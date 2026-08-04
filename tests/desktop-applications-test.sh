#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DNF_MANIFEST="$REPO_DIR/bootstrap/fedora/dnf-packages.tsv"
FLATPAK_MANIFEST="$REPO_DIR/bootstrap/fedora/flatpaks.tsv"
EXTERNAL_MANIFEST="$REPO_DIR/bootstrap/fedora/external-tools.tsv"
MIMEAPPS="$REPO_DIR/desktop/.config/mimeapps.list"
ANNOTATOR="$REPO_DIR/desktop/.local/bin/naldo-annotated-snip"
APP_LAUNCHER="$REPO_DIR/niri/.config/niri/scripts/app_launcher.sh"
workspace="$(mktemp -d "${TMPDIR:-/tmp}/desktop-applications-test.XXXXXX")"
checks=0
trap 'rm -rf -- "$workspace"' EXIT

fail() {
  printf 'not ok %d - %s\n' "$((checks + 1))" "$*" >&2
  exit 1
}

pass() {
  ((checks += 1))
  printf 'ok %d - %s\n' "$checks" "$1"
}

manifest_has_package() {
  local package="$1"
  [[ "$(awk -F '\t' -v package="$package" '$1 == package { count++ } END { print count+0 }' "$DNF_MANIFEST")" == 1 ]] ||
    fail "official DNF manifest does not contain exactly one $package"
}

mime_default_is() {
  local mime="$1" expected="$2" actual
  actual="$(awk -F= -v mime="$mime" '
    $0 == "[Default Applications]" { active=1; next }
    /^\[/ { active=0 }
    active && $1 == mime { print $2; exit }
  ' "$MIMEAPPS")"
  [[ "$actual" == "$expected" ]] ||
    fail "default for $mime is ${actual:-missing}, expected $expected"
}

fake_bin="$workspace/bin"
clipboard="$workspace/clipboard.png"
mkdir -p "$fake_bin"
printf 'old-png-data' >"$clipboard"
cat >"$fake_bin/noctalia" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$SCREENSHOT_NOCTALIA_LOG"
printf 'new-png-data' >"$SCREENSHOT_CLIPBOARD"
EOF
cat >"$fake_bin/wl-paste" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
--list-types) printf 'image/png\n' ;;
--type) [[ "${2:-}" == image/png ]] || exit 2; cat -- "$SCREENSHOT_CLIPBOARD" ;;
*) exit 2 ;;
esac
EOF
cat >"$fake_bin/swappy" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$SCREENSHOT_SWAPPY_LOG"
cat >"$SCREENSHOT_SWAPPY_INPUT"
EOF
cat >"$fake_bin/notify-send" <<'EOF'
#!/usr/bin/env bash
exit 99
EOF
chmod 0755 "$fake_bin"/*

SCREENSHOT_CLIPBOARD="$clipboard" \
SCREENSHOT_NOCTALIA_LOG="$workspace/noctalia.args" \
SCREENSHOT_SWAPPY_LOG="$workspace/swappy.args" \
SCREENSHOT_SWAPPY_INPUT="$workspace/swappy.input" \
PATH="$fake_bin:$PATH" "$ANNOTATOR"
[[ "$(<"$workspace/noctalia.args")" == $'msg\nscreenshot-region' ]] ||
  fail 'annotation helper did not use Noctalia screenshot-region'
[[ "$(<"$workspace/swappy.args")" == $'-f\n-' ]] ||
  fail 'annotation helper did not invoke swappy -f -'
[[ "$(<"$workspace/swappy.input")" == new-png-data ]] ||
  fail 'annotation helper did not pipe captured PNG data to Swappy'
pass 'Noctalia region capture pipes PNG data to swappy -f -'

excluded_annotator='sa'"tty"
if rg -n -i "\\b(grim|slurp|$excluded_annotator)\\b" \
  "$REPO_DIR/desktop" "$REPO_DIR/niri" "$REPO_DIR/noctalia" "$REPO_DIR/yazi" \
  "$REPO_DIR/bootstrap/fedora" >"$workspace/forbidden-tools.log"; then
  cat "$workspace/forbidden-tools.log" >&2
  fail 'desktop still declares an excluded capture or annotation tool'
fi
pass 'screenshot policy contains only Noctalia capture and Swappy annotation'

for package in blender firefox inkscape obs-studio obs-studio-plugin-browser imv mpv mpv-mpris \
  zathura zathura-pdf-poppler swappy thunderbird okular; do
  manifest_has_package "$package"
done
! awk -F '\t' '$1 == "celluloid" || $1 == "zathura-pdf-mupdf" { found=1 } END { exit !found }' \
  "$DNF_MANIFEST" || fail 'an unselected desktop alternative remains in the DNF manifest'
awk -F '\t' '$1 == "okular" && $2 == "feature" { found=1 } END { exit !found }' "$DNF_MANIFEST" ||
  fail 'installed secondary PDF application is not required'
pass 'official Fedora applications contain exactly the selected installed policy'

actual_flatpaks="$(awk -F '\t' '$1 !~ /^#/ && NF { print $1 }' "$FLATPAK_MANIFEST" | sort)"
expected_flatpaks="$(printf '%s\n' app.zen_browser.zen com.discordapp.Discord md.obsidian.Obsidian \
  com.dec05eba.gpu_screen_recorder com.github.ahrm.sioyek dev.vencord.Vesktop | sort)"
[[ "$actual_flatpaks" == "$expected_flatpaks" ]] || fail 'Flatpak IDs differ from selected policy'
awk -F '\t' '
  $1 == "com.github.ahrm.sioyek" && $2 == "feature" && $3 == "flathub" &&
  $4 == "com.github.ahrm.sioyek.desktop" && $NF == "all" { found=1 }
  END { exit !found }
' "$FLATPAK_MANIFEST" || fail 'Sioyek is not a selected Flathub PDF feature'
awk -F '\t' '$1 == "dev.vencord.Vesktop" && $2 == "optional" { found=1 } END { exit !found }' \
  "$FLATPAK_MANIFEST" || fail 'Vesktop is not optional'
awk -F '\t' '
  $1 == "com.dec05eba.gpu_screen_recorder" && $2 == "feature" && $3 == "flathub" &&
  $4 == "com.dec05eba.gpu_screen_recorder.desktop" && $5 == "gpu-screen-recorder" && $NF == "all" { found=1 }
  END { exit !found }
' "$FLATPAK_MANIFEST" || fail 'GPU Screen Recorder lacks one Flathub application and packaged CLI provider'
pass 'Flatpak policy contains five required applications, one named optional application, and one recorder provider'

grep -Fq '"noctalia/screen_recorder"' "$REPO_DIR/noctalia/.config/noctalia/config.toml" ||
  fail 'Noctalia Screen Recorder plugin is not selected'
awk '
  $0 == "[plugin_settings.\"noctalia/screen_recorder\"]" { active=1; next }
  /^\[/ { active=0 }
  active && $0 == "video_source = \"portal\"" { found=1 }
  END { exit !found }
' "$REPO_DIR/noctalia/.config/noctalia/config.toml" ||
  fail 'Noctalia Screen Recorder does not explicitly use portal capture'
pass 'the Flathub-compatible Noctalia recorder remains selected in portal mode'

mime_default_is inode/directory yazi.desktop
for mime in text/html application/xhtml+xml x-scheme-handler/http x-scheme-handler/https; do
  mime_default_is "$mime" app.zen_browser.zen.desktop
done
mime_default_is application/pdf org.pwmt.zathura.desktop
for mime in image/png image/jpeg image/gif image/webp image/bmp image/tiff image/svg+xml; do
  mime_default_is "$mime" imv.desktop
done
for mime in text/plain text/markdown text/vnd.typst text/x-python text/x-csrc application/json application/x-yaml; do
  mime_default_is "$mime" Helix.desktop
done
for mime in audio/flac audio/mpeg audio/ogg video/mp4 video/webm video/x-matroska; do
  mime_default_is "$mime" mpv.desktop
done
mime_default_is x-scheme-handler/discord com.discordapp.Discord.desktop
mime_default_is x-scheme-handler/obsidian md.obsidian.Obsidian.desktop
for mime in x-scheme-handler/mailto x-scheme-handler/mid x-scheme-handler/webcal \
  x-scheme-handler/webcals message/rfc822 text/calendar; do
  mime_default_is "$mime" net.thunderbird.Thunderbird.desktop
done
grep -Fxq 'application/pdf=org.pwmt.zathura.desktop;org.kde.okular.desktop;okularApplication_pdf.desktop;com.github.ahrm.sioyek.desktop;' "$MIMEAPPS" ||
  fail 'PDF association order differs from policy'
grep -Fxq 'text/markdown=Helix.desktop;md.obsidian.Obsidian.desktop;' "$MIMEAPPS" ||
  fail 'Markdown association order differs from policy'
grep -Fxq 'image/svg+xml=imv.desktop;org.inkscape.Inkscape.desktop;' "$MIMEAPPS" ||
  fail 'SVG association order differs from policy'
! rg -n 'Celluloid|celluloid' "$MIMEAPPS" "$REPO_DIR/yazi/.config/yazi/yazi.toml" >/dev/null ||
  fail 'removed Celluloid alternative remains configured'
pass 'MIME and Yazi policies contain selected defaults and named additions only'

python3 - "$REPO_DIR" <<'PY'
from pathlib import Path
import csv
import sys
root = Path(sys.argv[1])
bootstrap = root / "bootstrap/fedora"

def rows(path):
    with path.open(newline="") as handle:
        return [r for r in csv.reader(handle, delimiter="\t") if r and r[0] and not r[0].startswith("#")]

def specs(value):
    if value == "-":
        return []
    return [entry.split(":", 1)[1] for entry in value.split(",")]

known = set()
for row in rows(bootstrap / "dnf-packages.tsv"):
    known.update(specs(row[3]))
for row in rows(bootstrap / "external-tools.tsv"):
    known.update(specs(row[5]))
for row in rows(bootstrap / "flatpaks.tsv"):
    known.add(row[3])
known.update(path.name for path in (root / "desktop/.local/share/applications").glob("*.desktop"))

mime_ids = set()
for line in (root / "desktop/.config/mimeapps.list").read_text().splitlines():
    if not line or line.startswith("[") or line.startswith("#") or "=" not in line:
        continue
    for desktop in line.split("=", 1)[1].split(";"):
        if desktop:
            mime_ids.add(desktop)
missing = sorted(mime_ids - known)
assert not missing, f"MIME desktop IDs lack one source-manifest entry: {missing}"
PY
pass 'every MIME and Flatpak desktop ID derives from one installation-source entry'

awk -F '\t' '
  $1 == "google-chrome-stable" && $2 == "feature" &&
  $3 == "official-vendor-repository" &&
  $4 == "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" &&
  $5 == "google-chrome-stable" && $6 == "application:google-chrome.desktop" { found=1 }
  END { exit !found }
' "$EXTERNAL_MANIFEST" || fail 'Chrome source or desktop identity differs from selected vendor policy'
grep -Fq 'https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm' \
  "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" || fail 'Chrome vendor RPM is absent from the clean-install guide'
grep -Fq 'sudo dnf install /tmp/google-chrome-stable_current_x86_64.rpm' \
  "$REPO_DIR/bootstrap/fedora/CLEAN-INSTALL.md" || fail 'Chrome reviewed local-RPM installation is absent from the clean-install guide'
awk -F '\t' '$1 == "firefox" && $2 == "feature" && $4 == "application:org.mozilla.firefox.desktop" { found=1 } END { exit !found }' \
  "$DNF_MANIFEST" || fail 'Firefox is not a selected secondary browser'
! rg -n 'launch-zen' "$REPO_DIR/desktop" "$REPO_DIR/niri" "$REPO_DIR/bootstrap/fedora" >/dev/null ||
  fail 'fixed-command Zen forwarding wrapper remains'
# Literal source assertion; expansion belongs to the launcher at runtime.
# shellcheck disable=SC2016
grep -Fq 'spawn_app flatpak run "$ZEN_FLATPAK_ID" --new-window about:newtab' "$APP_LAUNCHER" ||
  fail 'Zen Flatpak launcher does not request a direct new window'

zen_bin="$workspace/zen-bin"
zen_state="$workspace/zen.state"
zen_actions="$workspace/zen.actions"
mkdir -p "$zen_bin"
cat >"$zen_bin/noctalia" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '󰙨 Zen Browser'
EOF
cat >"$zen_bin/flatpak" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == info && "$2" == app.zen_browser.zen ]]
EOF
cat >"$zen_bin/niri" <<'EOF'
#!/usr/bin/env bash
set -e
if [[ "$1" == msg && "$2" == -j && "$3" == focused-window ]]; then
  if [[ -e "$ZEN_TEST_STATE" ]]; then
    printf '%s\n' '{"id":57,"app_id":"app.zen_browser.zen","is_floating":false}'
  else
    printf '%s\n' '{"id":41,"app_id":"app.zen_browser.zen","is_floating":false}'
  fi
  exit 0
fi
if [[ "$1" == msg && "$2" == action ]]; then
  printf '%s\n' "$*" >>"$ZEN_TEST_ACTIONS"
  if [[ "$3" == spawn ]]; then
    : >"$ZEN_TEST_STATE"
  fi
  exit 0
fi
exit 2
EOF
cat >"$zen_bin/launch-terminal" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod 0755 "$zen_bin"/*
PATH="$zen_bin:/usr/bin" \
NOCTALIA="$zen_bin/noctalia" \
NIRI="$zen_bin/niri" \
LAUNCH_TERMINAL="$zen_bin/launch-terminal" \
ZEN_TEST_STATE="$zen_state" \
ZEN_TEST_ACTIONS="$zen_actions" \
  "$APP_LAUNCHER"
for expected_action in \
  'msg action spawn -- flatpak run app.zen_browser.zen --new-window about:newtab' \
  'msg action move-window-to-floating --id 57' \
  'msg action set-window-width --id 57 1080' \
  'msg action set-window-height --id 57 920' \
  'msg action center-window --id 57'; do
  grep -Fxq "$expected_action" "$zen_actions" ||
    fail "launcher omitted targeted Zen action: $expected_action"
done
! grep -Eq -- '--id 41($| )' "$zen_actions" ||
  fail 'launcher changed a pre-existing ordinary Zen window'
pass 'Zen remains default while only the Mod+Z-created window is floated sized and centered'

printf '1..%d\n' "$checks"
