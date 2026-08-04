#!/usr/bin/env bash

set -Eeuo pipefail

BOOTSTRAP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd -- "$BOOTSTRAP_DIR/../.." && pwd -P)"

usage() {
  printf 'Usage: %s --profile desktop|laptop\n' "${0##*/}"
}

fail_cli() {
  printf 'verify-fedora: %s\n' "$*" >&2
  usage >&2
  exit 2
}

profile=""
profile_count=0
while (($# > 0)); do
  case "$1" in
  --profile)
    (($# >= 2)) || fail_cli '--profile requires a value'
    ((profile_count += 1))
    ((profile_count == 1)) || fail_cli '--profile may be specified only once'
    profile="$2"
    shift 2
    ;;
  --profile=*)
    ((profile_count += 1))
    ((profile_count == 1)) || fail_cli '--profile may be specified only once'
    profile="${1#*=}"
    [[ -n "$profile" ]] || fail_cli '--profile requires a value'
    shift
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    fail_cli "unknown option: $1"
    ;;
  esac
done

case "$profile" in
  desktop|laptop) ;;
  "") fail_cli '--profile desktop|laptop is required' ;;
  *) fail_cli "invalid profile: $profile (expected desktop or laptop)" ;;
esac

missing_required=0
missing_optional=0
present=0

classification_is_required() {
  [[ "$1" == "session" || "$1" == "feature" ]]
}

validate_classification() {
  case "$1" in
  session|feature|optional|development) ;;
  *)
    printf 'verify-fedora: invalid classification %q in %s\n' "$1" "$2" >&2
    exit 2
    ;;
  esac
}

row_applies() {
  local applicability="$1" source="$2"
  case "$applicability" in
  all) return 0 ;;
  desktop|laptop) [[ "$applicability" == "$profile" ]] ;;
  *)
    printf 'verify-fedora: invalid profile %q in %s (expected all, desktop, or laptop)\n' \
      "$applicability" "$source" >&2
    exit 2
    ;;
  esac
}

record_present() {
  local kind="$1" classification="$2" identifier="$3" detail="$4"
  ((present += 1))
  printf 'PRESENT  %-12s [%-11s] %-48s %s\n' "$kind" "$classification" "$identifier" "$detail"
}

record_missing() {
  local kind="$1" classification="$2" identifier="$3" detail="$4"
  if classification_is_required "$classification"; then
    ((missing_required += 1))
    printf 'MISSING  %-12s [%-11s] %-48s %s\n' "$kind" "$classification" "$identifier" "$detail"
  else
    ((missing_optional += 1))
    printf 'OPTIONAL %-12s [%-11s] %-48s %s\n' "$kind" "$classification" "$identifier" "$detail"
  fi
}

verify_command_list() {
  local classification="$1" provider="$2" value="$3" purpose="$4" command_name
  [[ "$value" != "-" ]] || return 0
  IFS=',' read -r -a commands <<<"$value"
  for command_name in "${commands[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
      record_present command "$classification" "$command_name" "$provider"
    else
      record_missing command "$classification" "$command_name" "$provider — $purpose"
    fi
  done
}

application_roots=(
  "${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
  "/var/lib/flatpak/exports/share/applications"
  "/usr/local/share/applications"
  "/usr/share/applications"
)
wayland_roots=(
  "${XDG_DATA_HOME:-$HOME/.local/share}/wayland-sessions"
  "/usr/local/share/wayland-sessions"
  "/usr/share/wayland-sessions"
)

desktop_file_exists() {
  local identifier="$1" scope="$2" root
  local -a roots=("${application_roots[@]}")
  [[ "$scope" != "wayland" ]] || roots=("${wayland_roots[@]}")
  for root in "${roots[@]}"; do
    [[ -e "$root/$identifier" || -L "$root/$identifier" ]] && return 0
  done
  return 1
}

verify_desktop_list() {
  local classification="$1" provider="$2" value="$3" purpose="$4"
  local entry scope identifier
  [[ "$value" != "-" ]] || return 0
  IFS=',' read -r -a desktops <<<"$value"
  for entry in "${desktops[@]}"; do
    scope="${entry%%:*}"
    identifier="${entry#*:}"
    [[ "$scope" == "application" || "$scope" == "wayland" ]] || {
      printf 'verify-fedora: invalid desktop scope in %q\n' "$entry" >&2
      exit 2
    }
    if desktop_file_exists "$identifier" "$scope"; then
      record_present desktop "$classification" "$identifier" "$provider"
    else
      record_missing desktop "$classification" "$identifier" "$provider — $purpose"
    fi
  done
}

font_family_exists() {
  local family="$1"
  command -v fc-list >/dev/null 2>&1 || return 1
  fc-list --format='%{family}\n' | awk -F ',' -v wanted="$family" '
    {
      for (field_index = 1; field_index <= NF; field_index++) {
        candidate = $field_index
        sub(/^[[:space:]]+/, "", candidate)
        sub(/[[:space:]]+$/, "", candidate)
        if (candidate == wanted) found = 1
      }
    }
    END { exit !found }
  '
}

verify_font_family() {
  local classification="$1" provider="$2" family="$3" purpose="$4"
  if font_family_exists "$family"; then
    record_present font "$classification" "$family" "$provider"
  else
    record_missing font "$classification" "$family" "$provider — $purpose"
  fi
}

unit_file_exists() {
  local unit="$1" scope="$2" root load_state
  local -a roots
  if [[ "$scope" == "user" ]]; then
    roots=(
      "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
      "$HOME/.local/share/systemd/user"
      "/usr/local/lib/systemd/user"
      "/usr/local/share/systemd/user"
      "/usr/lib/systemd/user"
      "/usr/share/systemd/user"
    )
  else
    roots=(
      "/etc/systemd/system"
      "/usr/local/lib/systemd/system"
      "/usr/lib/systemd/system"
      "/lib/systemd/system"
    )
  fi
  for root in "${roots[@]}"; do
    [[ -e "$root/$unit" || -L "$root/$unit" ]] && return 0
  done
  command -v systemctl >/dev/null 2>&1 || return 1
  if [[ "$scope" == "user" ]]; then
    load_state="$(systemctl --user show "$unit" --property=LoadState --value 2>/dev/null || true)"
  else
    load_state="$(systemctl show "$unit" --property=LoadState --value 2>/dev/null || true)"
  fi
  [[ -n "$load_state" && "$load_state" != "not-found" ]]
}

unit_state() {
  local unit="$1" scope="$2"
  command -v systemctl >/dev/null 2>&1 || {
    printf 'state unavailable'
    return
  }
  if [[ "$scope" == "user" ]]; then
    systemctl --user is-active "$unit" 2>/dev/null || true
  else
    systemctl is-active "$unit" 2>/dev/null || true
  fi
}

verify_unit_list() {
  local classification="$1" provider="$2" value="$3" purpose="$4"
  local entry scope identifier state
  [[ "$value" != "-" ]] || return 0
  IFS=',' read -r -a units <<<"$value"
  for entry in "${units[@]}"; do
    scope="${entry%%:*}"
    identifier="${entry#*:}"
    [[ "$scope" == "user" || "$scope" == "system" ]] || {
      printf 'verify-fedora: invalid unit scope in %q\n' "$entry" >&2
      exit 2
    }
    if unit_file_exists "$identifier" "$scope"; then
      state="$(unit_state "$identifier" "$scope")"
      record_present service "$classification" "$identifier" "$provider; ${state:-inactive or unavailable}"
    else
      record_missing service "$classification" "$identifier" "$provider — $purpose"
    fi
  done
}

verify_dnf_packages() {
  local package classification executables desktops units purpose applicability provider
  printf '\n== Official Fedora packages and their expected outputs ==\n'
  while IFS=$'\t' read -r package classification executables desktops units purpose applicability || [[ -n "$package" ]]; do
    [[ -n "$package" && "$package" != \#* ]] || continue
    validate_classification "$classification" dnf-packages.tsv
    row_applies "$applicability" dnf-packages.tsv || continue
    provider="dnf:$package"
    if command -v rpm >/dev/null 2>&1 && rpm --quiet -q "$package"; then
      record_present package "$classification" "$package" official-fedora
    else
      record_missing package "$classification" "$package" "official-fedora — $purpose"
    fi
    verify_command_list "$classification" "$provider" "$executables" "$purpose"
    verify_desktop_list "$classification" "$provider" "$desktops" "$purpose"
    verify_unit_list "$classification" "$provider" "$units" "$purpose"
  done <"$BOOTSTRAP_DIR/dnf-packages.tsv"
}

flatpak_command_exists() {
  local identifier="$1" command_name="$2" location
  command -v flatpak >/dev/null 2>&1 || return 1
  location="$(flatpak info --show-location "$identifier" 2>/dev/null)" || return 1
  [[ "$location" == /* && -x "$location/files/bin/$command_name" ]]
}

verify_flatpak_command_list() {
  local classification="$1" identifier="$2" value="$3" purpose="$4" command_name invocation
  [[ "$value" != "-" ]] || return 0
  IFS=',' read -r -a commands <<<"$value"
  for command_name in "${commands[@]}"; do
    invocation="flatpak run --command=$command_name $identifier"
    if flatpak_command_exists "$identifier" "$command_name"; then
      record_present integration "$classification" "$invocation" "flatpak:$identifier"
    else
      record_missing integration "$classification" "$invocation" "flatpak:$identifier — $purpose"
    fi
  done
}

verify_flatpaks() {
  local identifier classification remote desktop integration_commands purpose applicability provider
  printf '\n== Flatpak applications, integration commands, and exported desktop files ==\n'
  while IFS=$'\t' read -r identifier classification remote desktop integration_commands purpose applicability || [[ -n "$identifier" ]]; do
    [[ -n "$identifier" && "$identifier" != \#* ]] || continue
    validate_classification "$classification" flatpaks.tsv
    row_applies "$applicability" flatpaks.tsv || continue
    provider="flatpak:$identifier"
    if command -v flatpak >/dev/null 2>&1 && flatpak info "$identifier" >/dev/null 2>&1; then
      record_present flatpak "$classification" "$identifier" "$remote"
    else
      record_missing flatpak "$classification" "$identifier" "$remote — $purpose"
    fi
    verify_desktop_list "$classification" "$provider" "application:$desktop" "$purpose"
    verify_flatpak_command_list "$classification" "$identifier" "$integration_commands" "$purpose"
  done <"$BOOTSTRAP_DIR/flatpaks.tsv"
}

verify_npm_tools() {
  local package commands classification role applicability
  printf '\n== User-prefix npm tools ==\n'
  while IFS=$'\t' read -r package commands classification role applicability || [[ -n "$package" ]]; do
    [[ -n "$package" && "$package" != \#* ]] || continue
    validate_classification "$classification" npm-packages.tsv
    row_applies "$applicability" npm-packages.tsv || continue
    verify_command_list "$classification" "npm:$package" "$commands" "$role"
  done <"$BOOTSTRAP_DIR/npm-packages.tsv"
}

verify_uv_tools() {
  local package commands classification activation role applicability
  printf '\n== uv tools ==\n'
  while IFS=$'\t' read -r package commands classification activation role applicability || [[ -n "$package" ]]; do
    [[ -n "$package" && "$package" != \#* ]] || continue
    validate_classification "$classification" uv-tools.tsv
    [[ "$activation" == "active" || "$activation" == "inactive" ]] || {
      printf 'verify-fedora: invalid uv activation %q\n' "$activation" >&2
      exit 2
    }
    row_applies "$applicability" uv-tools.tsv || continue
    verify_command_list "$classification" "uv:$package" "$commands" "$role"
  done <"$BOOTSTRAP_DIR/uv-tools.tsv"
}

verify_cargo_tools() {
  local package commands classification _source _locked_install _update _uninstall role applicability
  printf '\n== Locked Cargo tools ==\n'
  while IFS=$'\t' read -r package commands classification _source _locked_install _update _uninstall role applicability || [[ -n "$package" ]]; do
    [[ -n "$package" && "$package" != \#* ]] || continue
    validate_classification "$classification" cargo-tools.tsv
    row_applies "$applicability" cargo-tools.tsv || continue
    verify_command_list "$classification" "cargo:$package" "$commands" "$role"
  done <"$BOOTSTRAP_DIR/cargo-tools.tsv"
}

validate_external_source_class() {
  case "$1" in
  official-vendor-repository | reviewed-third-party-repository | reviewed-community-copr | \
    upstream-documented-third-party-copr | official-upstream-installer | \
    official-upstream-release | official-upstream-tagged-source | \
    official-vscode-extension | reviewed-gh-extension) ;;
  *)
    printf 'verify-fedora: invalid external source class %q in external-tools.tsv\n' "$1" >&2
    exit 2
    ;;
  esac
}

verify_external_rpm_package() {
  local tool="$1" classification="$2" source_class="$3" source="$4" purpose="$5"
  local vendor owner
  if ! command -v rpm >/dev/null 2>&1 || ! rpm --quiet -q "$tool"; then
    record_missing package "$classification" "$tool" "$source_class — $purpose"
    return
  fi
  case "$source_class" in
  reviewed-community-copr | upstream-documented-third-party-copr)
    owner="${source#*'/coprs/'}"
    owner="${owner%%/*}"
    vendor="$(rpm -q --qf '%{VENDOR}' "$tool")"
    if [[ -n "$owner" && "$owner" != "$source" && "$vendor" == "Fedora Copr - user $owner" ]]; then
      record_present package "$classification" "$tool" "$source_class:$owner"
    else
      record_missing package "$classification" "$tool" \
        "$source_class — unexpected RPM vendor ${vendor:-unknown}; expected COPR owner $owner"
    fi
    ;;
  official-vendor-repository)
    vendor="$(rpm -q --qf '%{VENDOR}\t%{PACKAGER}' "$tool")"
    case "$tool:$vendor" in
    google-chrome-stable:Google\ LLC*) owner=google ;;
    code:Microsoft\ Corporation*) owner=microsoft ;;
    tailscale:*Tailscale\ Inc*) owner=tailscale ;;
    *) owner= ;;
    esac
    if [[ -n "$owner" ]]; then
      record_present package "$classification" "$tool" "$source_class:$owner"
    else
      record_missing package "$classification" "$tool" \
        "$source_class — unexpected RPM vendor/packager ${vendor:-unknown}"
    fi
    ;;
  *) record_present package "$classification" "$tool" "$source_class" ;;
  esac
}

herdr_installer_receipt_is_valid() {
  local receipt path expected channel
  local -a lines=()
  receipt="${XDG_DATA_HOME:-$HOME/.local/share}/naldo/provider-receipts/herdr-official-installer"
  [[ -f "$receipt" && ! -L "$receipt" && -O "$receipt" ]] || return 1
  command -v herdr >/dev/null 2>&1 || return 1
  path="$(readlink -f -- "$(command -v herdr)")" || return 1
  expected="$(readlink -m -- "$HOME/.local/bin/herdr")"
  [[ "$path" == "$expected" ]] || return 1
  mapfile -t lines <"$receipt"
  [[ "${#lines[@]}" == 2 ]] || return 1
  [[ "${lines[0]}" == 'source=https://herdr.dev/install.sh' ]] || return 1
  [[ "${lines[1]}" == "binary=$path" ]] || return 1
  channel="$(herdr channel show 2>/dev/null)" || return 1
  [[ "$channel" == stable ]]
}

tuicr_installer_receipt_is_valid() {
  local receipt path expected
  local -a lines=()
  receipt="${XDG_DATA_HOME:-$HOME/.local/share}/naldo/provider-receipts/tuicr-official-installer"
  [[ -f "$receipt" && ! -L "$receipt" && -O "$receipt" ]] || return 1
  command -v tuicr >/dev/null 2>&1 || return 1
  path="$(readlink -f -- "$(command -v tuicr)")" || return 1
  expected="$(readlink -m -- "$HOME/.local/bin/tuicr")"
  [[ "$path" == "$expected" ]] || return 1
  mapfile -t lines <"$receipt"
  [[ "${#lines[@]}" == 2 ]] || return 1
  [[ "${lines[0]}" == 'source=https://tuicr.dev/install.sh' ]] || return 1
  [[ "${lines[1]}" == "binary=$path" ]]
}

verify_official_installer_provider() {
  local tool="$1" classification="$2" purpose="$3" resolved expected
  case "$tool" in
  herdr)
    if herdr_installer_receipt_is_valid; then
      record_present provider "$classification" "$tool" official-upstream-installer
    else
      record_missing provider "$classification" "$tool" \
        "official-upstream-installer — missing valid stable-channel installer receipt — $purpose"
    fi
    ;;
  pixi)
    if command -v pixi >/dev/null 2>&1; then
      resolved="$(readlink -f -- "$(command -v pixi)")"
      expected="$(readlink -m -- "$HOME/.pixi/bin/pixi")"
    else
      resolved=""
      expected="$(readlink -m -- "$HOME/.pixi/bin/pixi")"
    fi
    if [[ -n "$resolved" && "$resolved" == "$expected" ]]; then
      record_present provider "$classification" "$tool" official-upstream-installer
    else
      record_missing provider "$classification" "$tool" \
        "official-upstream-installer — expected $expected — $purpose"
    fi
    ;;
  tuicr)
    if tuicr_installer_receipt_is_valid; then
      record_present provider "$classification" "$tool" official-upstream-installer
    else
      record_missing provider "$classification" "$tool" \
        "official-upstream-installer — missing valid installer receipt — $purpose"
    fi
    ;;
  *)
    printf 'verify-fedora: no official-installer ownership check for %q\n' "$tool" >&2
    exit 2
    ;;
  esac
}

verify_gh_extension_provider() {
  local tool="$1" classification="$2" purpose="$3"
  local extension_dir manifest binary configured_path
  extension_dir="${XDG_DATA_HOME:-$HOME/.local/share}/gh/extensions/$tool"
  manifest="$extension_dir/manifest.yml"
  binary="$extension_dir/$tool"
  configured_path=""
  if [[ -f "$manifest" && ! -L "$manifest" && -x "$binary" && ! -L "$binary" ]] &&
    grep -Fxq 'owner: dlvhdr' "$manifest" &&
    grep -Fxq 'name: gh-dash' "$manifest" &&
    grep -Fxq 'host: github.com' "$manifest"; then
    configured_path="$(awk -F ': ' '$1 == "path" { print $2; exit }' "$manifest")"
  fi
  if [[ "$tool" == gh-dash && "$configured_path" == "$binary" ]]; then
    record_present provider "$classification" "$tool" reviewed-gh-extension
  else
    record_missing provider "$classification" "$tool" \
      "reviewed-gh-extension — missing valid dlvhdr/gh-dash installation — $purpose"
  fi
}

verify_vscode_extension_provider() {
  local extension_id="$1" classification="$2" purpose="$3"
  if command -v code >/dev/null 2>&1 &&
    code --list-extensions 2>/dev/null | grep -Fxiq -- "$extension_id"; then
    record_present provider "$classification" "$extension_id" official-vscode-extension
  else
    record_missing provider "$classification" "$extension_id" \
      "official-vscode-extension — selected extension is not installed — $purpose"
  fi
}

verify_external_tools() {
  local tool classification source_class source executables desktops units _update _uninstall purpose applicability provider
  printf '\n== Reviewed external tools and provider ownership ==\n'
  while IFS=$'\t' read -r tool classification source_class source executables desktops units _update _uninstall purpose applicability || [[ -n "$tool" ]]; do
    [[ -n "$tool" && "$tool" != \#* ]] || continue
    validate_classification "$classification" external-tools.tsv
    validate_external_source_class "$source_class"
    row_applies "$applicability" external-tools.tsv || continue
    provider="$source_class:$tool"
    case "$source_class" in
    official-vendor-repository | reviewed-community-copr | upstream-documented-third-party-copr)
      verify_external_rpm_package "$tool" "$classification" "$source_class" "$source" "$purpose"
      ;;
    official-upstream-installer)
      verify_official_installer_provider "$tool" "$classification" "$purpose"
      ;;
    reviewed-gh-extension)
      verify_gh_extension_provider "$tool" "$classification" "$purpose"
      ;;
    official-vscode-extension)
      verify_vscode_extension_provider "$tool" "$classification" "$purpose"
      ;;
    esac
    verify_command_list "$classification" "$provider" "$executables" "$purpose"
    verify_desktop_list "$classification" "$provider" "$desktops" "$purpose"
    verify_unit_list "$classification" "$provider" "$units" "$purpose"
    if [[ "$tool" == "JetBrainsMono Nerd Font" ]]; then
      verify_font_family "$classification" "$provider" "$tool" "$purpose"
    fi
  done <"$BOOTSTRAP_DIR/external-tools.tsv"
}

verify_tracked_user_outputs() {
  local source repository_relative target_relative target identifier
  local -a stow_packages=(
    ghostty fish starship herdr helix zathura yazi niri lazygit noctalia
    xdg-desktop-portal pi desktop automation git
  )

  printf '\n== Tracked user executables ==\n'
  while IFS= read -r -d '' source; do
    [[ -x "$REPO_DIR/$source" ]] || continue
    repository_relative="$source"
    target_relative="${repository_relative#*/}"
    target="$HOME/$target_relative"
    identifier="$HOME/$target_relative"
    if [[ -x "$target" ]]; then
      record_present command feature "$identifier" "dotfiles:${repository_relative%%/*}"
    else
      record_missing command feature "$identifier" "dotfiles:${repository_relative%%/*} — run install.sh"
    fi
  done < <(git -C "$REPO_DIR" ls-files -z -- "${stow_packages[@]}")

  printf '\n== Tracked user desktop files and units ==\n'
  while IFS= read -r -d '' source; do
    identifier="${source##*/}"
    if desktop_file_exists "$identifier" application; then
      record_present desktop feature "$identifier" dotfiles:desktop
    else
      record_missing desktop feature "$identifier" 'dotfiles:desktop — run install.sh'
    fi
  done < <(git -C "$REPO_DIR" ls-files -z -- 'desktop/.local/share/applications/*.desktop')

  while IFS= read -r -d '' source; do
    identifier="${source##*/}"
    if unit_file_exists "$identifier" user; then
      record_present service feature "$identifier" "dotfiles:automation; $(unit_state "$identifier" user)"
    else
      record_missing service feature "$identifier" 'dotfiles:automation — run install.sh'
    fi
  done < <(git -C "$REPO_DIR" ls-files -z -- 'automation/.config/systemd/user/*.service' 'automation/.config/systemd/user/*.timer')
}

printf 'Fedora verification profile: %s\n' "$profile"

verify_dnf_packages
verify_flatpaks
verify_npm_tools
verify_uv_tools
verify_cargo_tools
verify_external_tools
verify_tracked_user_outputs

printf '\nSummary: %d present, %d missing required, %d missing optional/development.\n' \
  "$present" "$missing_required" "$missing_optional"
if ((missing_required > 0)); then
  printf 'Required session or configured-feature dependencies are missing.\n' >&2
  exit 1
fi
printf 'All required session and configured-feature dependencies were found.\n'
