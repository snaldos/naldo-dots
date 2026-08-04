#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
MANAGER="$REPO_DIR/ghostty/.config/ghostty/ghostty-shaders.sh"
SOURCE_SHADERS="$REPO_DIR/ghostty/.config/ghostty/shaders"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/ghostty-shaders-test.XXXXXX")"
sleeper_pid=""
checks=0

cleanup() {
  if [[ -n "$sleeper_pid" ]]; then
    kill "$sleeper_pid" 2>/dev/null || true
    wait "$sleeper_pid" 2>/dev/null || true
  fi
  rm -rf -- "$workspace"
}
trap cleanup EXIT

fail() {
  printf 'not ok %d - %s\n' "$((checks + 1))" "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$1"
}

assert_contains() {
  local path="$1" expected="$2"
  grep -Fq -- "$expected" "$path" || fail "$path does not contain: $expected"
}

banned='stars?|gaussian|meteors?|geodesics?|fbm|octaves?|sparks?|ray[- ]?march|effect[- ]specific|complexity'
if rg -n -i "$banned" "$MANAGER" >"$workspace/banned.log"; then
  cat "$workspace/banned.log" >&2
  fail 'shader manager contains shader-family terminology'
fi
pass 'Bash manager contains no shader-family-specific terminology'

unexpected_macros="$(
  rg --no-filename -o 'GHOSTTY_GPU_[A-Z0-9_]+' \
    "$SOURCE_SHADERS/background" "$SOURCE_SHADERS/combined" "$SOURCE_SHADERS/cursor" |
    sort -u |
    grep -Ev '^GHOSTTY_GPU_PROFILE(_ECO|_BALANCED|_QUALITY|_ULTRA)?$' || true
)"
[[ -z "$unexpected_macros" ]] || fail "tracked shaders use non-generic injected API names: $unexpected_macros"
rg -q 'GHOSTTY_GPU_PROFILE' "$SOURCE_SHADERS" ||
  fail 'no tracked shader interprets the generic profile selector'
pass 'profile-aware GLSL sources depend only on the generic profile API'

home="$workspace/home"
config_dir="$home/.config/ghostty"
shader_dir="$config_dir/shaders"
mkdir -p "$shader_dir"/{cursor,background,combined}
printf '# test Ghostty config\n' >"$config_dir/config.ghostty"

cat >"$shader_dir/cursor/alpha.glsl" <<'GLSL'
#version 330 core
#if GHOSTTY_GPU_PROFILE == GHOSTTY_GPU_PROFILE_ECO
const int local_quality = 1;
#else
const int local_quality = 2;
#endif
void mainImage(out vec4 color, in vec2 coordinates) {
  color = vec4(float(local_quality) / 2.0);
}
GLSL
cat >"$shader_dir/background/beta.glsl" <<'GLSL'
#version 330 core
void mainImage(out vec4 color, in vec2 coordinates) {
  color = vec4(coordinates, 0.0, 1.0);
}
GLSL
cat >"$shader_dir/combined/gamma.glsl" <<'GLSL'
#version 330 core
void mainImage(out vec4 color, in vec2 coordinates) {
  color = vec4(coordinates.yx, 0.0, 1.0);
}
GLSL

HOME="$home" "$MANAGER" --no-reload set cursor alpha >"$workspace/set-cursor.log"
active_config="$shader_dir/active.ghostty"
quality_path="$(awk -F '"' '/^custom-shader = / { print $2 }' "$active_config")"
[[ -f "$quality_path" ]] || fail 'quality-profile generated shader is missing'

actual_defines="$(awk '/^#define GHOSTTY_GPU_/ { print $2 }' "$quality_path" | sort -u)"
expected_defines="$(printf '%s\n' \
  GHOSTTY_GPU_PROFILE \
  GHOSTTY_GPU_PROFILE_BALANCED \
  GHOSTTY_GPU_PROFILE_ECO \
  GHOSTTY_GPU_PROFILE_QUALITY \
  GHOSTTY_GPU_PROFILE_ULTRA | sort -u)"
[[ "$actual_defines" == "$expected_defines" ]] || {
  printf 'expected defines:\n%s\nactual defines:\n%s\n' "$expected_defines" "$actual_defines" >&2
  fail 'generated shader constants differ from the generic API'
}
assert_contains "$quality_path" '#define GHOSTTY_GPU_PROFILE 2'
assert_contains "$workspace/set-cursor.log" 'GPU profile: Quality (quality)'
pass 'generated shaders receive exactly the five generic profile constants'

cp -- "$quality_path" "$workspace/quality.glsl"
HOME="$home" "$MANAGER" --no-reload set-profile eco >"$workspace/set-profile.log"
eco_path="$(awk -F '"' '/^custom-shader = / { print $2 }' "$active_config")"
[[ -f "$eco_path" && "$eco_path" != "$quality_path" ]] ||
  fail 'profile change did not select a different generated path'
assert_contains "$eco_path" '#define GHOSTTY_GPU_PROFILE 0'
assert_contains "$workspace/set-profile.log" 'GPU profile: Power saver (eco)'
if cmp -s "$workspace/quality.glsl" "$eco_path"; then
  fail 'profile change did not alter generated shader content'
fi
[[ "$(find "$shader_dir/generated" -maxdepth 1 -type f -name '*.glsl' | wc -l)" == 1 ]] ||
  fail 'inactive content-addressed shader was not cleaned up'
pass 'profile changes alter generated content-addressed shader files'

HOME="$home" "$MANAGER" --no-reload set background beta >"$workspace/set-background.log"
HOME="$home" "$MANAGER" --no-reload set combined gamma >"$workspace/set-combined.log"
[[ "$(HOME="$home" "$MANAGER" mode)" == combined ]] || fail 'combined mode was not selected'
[[ "$(HOME="$home" "$MANAGER" current cursor)" == none ]] || fail 'combined selection did not disable cursor stage'
[[ "$(HOME="$home" "$MANAGER" current background)" == none ]] || fail 'combined selection did not disable background stage'
[[ "$(HOME="$home" "$MANAGER" current combined)" == gamma.glsl ]] || fail 'combined selection was not retained'
HOME="$home" "$MANAGER" --no-reload set combined none >"$workspace/disable-combined.log"
[[ "$(HOME="$home" "$MANAGER" mode)" == none ]] || fail 'disabling combined unexpectedly restored separate stages'
[[ -z "$(awk '/^custom-shader = / { print }' "$active_config")" ]] || fail 'disabled state retained an active shader'
pass 'selection, exclusivity, disable, state, and active-config behavior remain intact'

status_output="$(HOME="$home" "$MANAGER" status)"
grep -Fxq 'GPU profile: Power saver (eco)' <<<"$status_output" || fail 'status profile output is not generic'
if grep -Eiq "$banned" <<<"$status_output"; then
  fail 'status output contains shader-family terminology'
fi
pass 'profile summary and status output remain generic'

fake_bin="$workspace/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/ghostty" <<'FAKE_GHOSTTY'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$GHOSTTY_TEST_LOG"
exit "${GHOSTTY_TEST_EXIT:-0}"
FAKE_GHOSTTY
chmod 0755 "$fake_bin/ghostty"
GHOSTTY_TEST_LOG="$workspace/validate.args" PATH="$fake_bin:$PATH" HOME="$home" \
  "$MANAGER" validate
assert_contains "$workspace/validate.args" '+validate-config'
assert_contains "$workspace/validate.args" "--config-file=$config_dir/config.ghostty"
if GHOSTTY_TEST_LOG="$workspace/validate-fail.args" GHOSTTY_TEST_EXIT=9 \
  PATH="$fake_bin:$PATH" HOME="$home" "$MANAGER" validate >/dev/null 2>&1; then
  fail 'validator failure was not propagated'
else
  status=$?
  [[ "$status" == 9 ]] || fail "validator failure changed exit status to $status"
fi
pass 'Ghostty validation invocation and failure propagation remain intact'

reload_ready="$workspace/reload.ready"
bash -c 'trap "exit 42" USR2; : >"$1"; while :; do sleep 1; done' _ "$reload_ready" &
sleeper_pid=$!
for _ in {1..100}; do
  [[ -e "$reload_ready" ]] && break
  sleep 0.01
done
[[ -e "$reload_ready" ]] || fail 'reload test process did not become ready'
fake_proc="$workspace/proc"
mkdir -p "$fake_proc/$sleeper_pid"
printf 'ghostty\n' >"$fake_proc/$sleeper_pid/comm"
HOME="$home" GHOSTTY_PROC_ROOT="$fake_proc" "$MANAGER" reload >"$workspace/reload.log"
assert_contains "$workspace/reload.log" 'Ghostty reloaded.'
if wait "$sleeper_pid" 2>/dev/null; then
  fail 'reload did not invoke the selected process signal handler'
else
  signal_status=$?
  [[ "$signal_status" == 42 ]] || fail "reload target did not receive SIGUSR2: $signal_status"
fi
sleeper_pid=""
pass 'reload behavior still signals Ghostty processes with SIGUSR2'

printf '1..%d\n' "$checks"
