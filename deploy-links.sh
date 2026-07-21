#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIR="${HOME:?HOME is not set}"
DRY_RUN=0
packages=(
  ghostty fish starship herdr nvim zathura yazi hypr niri lazygit noctalia xdg-desktop-portal pi
  desktop automation machine
)

log() {
  printf '[stow] %s\n' "$*"
}

fail() {
  log "ERROR: $*" >&2
  exit 1
}

# Stow's complete simulation remains authoritative. These structures describe
# only target conflicts that the simulation reported and the reconciler proved safe.
declare -a conflict_targets=()
declare -a migration_created_files=()
declare -a migration_targets=()
declare -A migration_created_sources=()
declare -A migration_kinds=()
declare -A migration_reasons=()
declare -A migration_sources=()
migration_stage=""
migration_active=0

is_safe_target_relative() {
  local relative="$1"

  [[ -n "$relative" && "$relative" != /* && "$relative" != "." && "$relative" != ".." &&
    "$relative" != ../* && "$relative" != */../* && "$relative" != */.. &&
    "$relative" != *$'\n'* ]]
}

target_has_symlink_parent() {
  local relative="$1" parent part current="$TARGET_DIR"
  local -a parts=()

  parent="${relative%/*}"
  [[ "$parent" != "$relative" ]] || return 1
  IFS='/' read -r -a parts <<<"$parent"
  for part in "${parts[@]}"; do
    [[ -n "$part" && "$part" != "." ]] || continue
    current="$current/$part"
    [[ ! -L "$current" ]] || return 0
  done
  return 1
}

find_conflict_source() {
  local relative="$1" package candidate found="" count=0

  for package in "${packages[@]}"; do
    candidate="$REPO_DIR/$package/$relative"
    [[ -e "$candidate" || -L "$candidate" ]] || continue
    found="$candidate"
    ((count += 1))
  done
  ((count == 1)) || return 1
  [[ -f "$found" && ! -L "$found" ]] || return 1
  printf '%s\n' "$found"
}

# Differing files need explicit, content-recognized migration rules. Add a rule
# and an isolated regression test whenever tracked ownership expands to a path
# that older machines already own as a regular file.
is_known_legacy_portal() {
  local relative="$1" target="$2"
  local expected=$'[preferred]\ndefault=hyprland;gtk;\norg.freedesktop.impl.portal.FileChooser=termfilechooser;\n'

  case "$relative" in
  .config/xdg-desktop-portal/hyprland-portals.conf | .config/xdg-desktop-portal/portals.conf)
    cmp -s -- "$target" <(printf '%s' "$expected")
    ;;
  *)
    return 1
    ;;
  esac
}

is_known_legacy_zathurarc() {
  local target="$1"

  awk '
    BEGIN {
      expected_keys = "default-bg default-fg recolor-lightcolor recolor-darkcolor " \
        "statusbar-bg statusbar-fg inputbar-bg inputbar-fg " \
        "notification-bg notification-fg notification-error-bg notification-error-fg " \
        "notification-warning-bg notification-warning-fg index-bg index-fg " \
        "index-active-bg index-active-fg highlight-color highlight-active-color highlight-fg " \
        "completion-bg completion-fg completion-group-bg completion-group-fg " \
        "completion-highlight-fg completion-highlight-bg selection-clipboard"
      count = split(expected_keys, keys, " ")
      for (i = 1; i <= count; i++) {
        expected[keys[i]] = 1
      }
    }
    NR == 1 {
      if ($0 != "# Rendered by Noctalia from this tracked template.") {
        invalid = 1
      }
      next
    }
    /^[[:space:]]*$/ { next }
    /^#/ {
      invalid = 1
      next
    }
    {
      if ($1 != "set" || NF < 3 || !($2 in expected) || seen[$2]++) {
        invalid = 1
        next
      }
      if ($2 == "selection-clipboard") {
        value = $0
        sub(/^[[:space:]]*set[[:space:]]+selection-clipboard[[:space:]]+/, "", value)
        sub(/[[:space:]]+$/, "", value)
        if (value != "clipboard") {
          invalid = 1
        }
      }
    }
    END {
      for (key in expected) {
        if (seen[key] != 1) {
          invalid = 1
        }
      }
      exit invalid
    }
  ' "$target"
}

extract_stow_conflicts() {
  local output="$1" line prefix remainder relative parse_failed=0
  declare -A seen=()

  conflict_targets=()
  prefix="  * cannot stow "
  while IFS= read -r line; do
    [[ "${line:0:4}" == "  * " ]] || continue
    if [[ "$line" != "$prefix"* ]]; then
      parse_failed=1
      continue
    fi
    remainder="${line#* over existing target }"
    if [[ "$remainder" == "$line" || "$remainder" != *" since "* ]]; then
      parse_failed=1
      continue
    fi
    relative="${remainder%% since *}"
    if [[ -z "${seen[$relative]+x}" ]]; then
      seen["$relative"]=1
      conflict_targets+=("$relative")
    fi
  done <<<"$output"

  ((parse_failed == 0 && ${#conflict_targets[@]} > 0)) || return 1
  [[ "$output" == *"All operations aborted."* ]]
}

classify_target_conflict() {
  local relative="$1" target source noctalia_fragment

  classified_kind=""
  classified_reason=""
  classified_source=""
  classification_error=""

  if ! is_safe_target_relative "$relative"; then
    classification_error="unsafe target path reported by Stow"
    return 1
  fi
  target="$TARGET_DIR/$relative"
  if target_has_symlink_parent "$relative"; then
    classification_error="a target parent is a symlink"
    return 1
  fi
  if [[ ! -f "$target" || -L "$target" ]]; then
    classification_error="target is not a real regular file"
    return 1
  fi
  if ! source="$(find_conflict_source "$relative")"; then
    classification_error="could not identify one regular package source"
    return 1
  fi

  if cmp -s -- "$source" "$target"; then
    classified_kind="identical"
    classified_reason="replace byte-identical file with its managed symlink"
  elif is_known_legacy_portal "$relative" "$target"; then
    classified_kind="known-portal"
    classified_reason="remove the recognized pre-Stow portal configuration"
  elif [[ "$relative" == ".config/zathura/zathurarc" ]] &&
    is_known_legacy_zathurarc "$target"; then
    noctalia_fragment="$TARGET_DIR/.config/zathura/noctaliarc"
    if [[ -e "$noctalia_fragment" || -L "$noctalia_fragment" ]] &&
      [[ ! -f "$noctalia_fragment" || -L "$noctalia_fragment" ]]; then
      classification_error="Zathura's local Noctalia include is not a real regular file"
      return 1
    fi
    classified_kind="known-zathura"
    classified_reason="split the recognized generated Zathura output into tracked behavior and local colors"
  else
    classification_error="contents differ from the tracked source and no known migration matches"
    return 1
  fi

  classified_source="$source"
}

plan_target_migrations() {
  local relative unsafe=0

  migration_targets=()
  for relative in "${conflict_targets[@]}"; do
    if classify_target_conflict "$relative"; then
      migration_targets+=("$relative")
      migration_kinds["$relative"]="$classified_kind"
      migration_reasons["$relative"]="$classified_reason"
      migration_sources["$relative"]="$classified_source"
    else
      log "ERROR: cannot safely migrate $TARGET_DIR/$relative: $classification_error" >&2
      unsafe=1
    fi
  done

  if ((unsafe != 0)); then
    log "ERROR: target conflicts require explicit review; no target files were changed" >&2
    log "ERROR: refusing --adopt because it could overwrite tracked sources" >&2
    return 1
  fi
}

render_legacy_zathura_colors() {
  local legacy="$1"

  awk '
    /^[[:space:]]*set[[:space:]]+selection-clipboard[[:space:]]+clipboard[[:space:]]*$/ {
      next
    }
    { lines[++count] = $0 }
    END {
      while (count > 0 && lines[count] ~ /^[[:space:]]*$/) {
        count--
      }
      for (i = 1; i <= count; i++) {
        print lines[i]
      }
    }
  ' "$legacy"
}

prepare_zathura_color_fragment() {
  local legacy="$1"
  local fragment="$TARGET_DIR/.config/zathura/noctaliarc" temporary

  if [[ -e "$fragment" || -L "$fragment" ]]; then
    [[ -f "$fragment" && ! -L "$fragment" ]] || return 1
    return 0
  fi

  temporary="$(mktemp --tmpdir="${fragment%/*}" '.noctaliarc.migration.XXXXXX')"
  if ! render_legacy_zathura_colors "$legacy" >"$temporary" ||
    ! chmod 644 "$temporary" || ! mv -- "$temporary" "$fragment"; then
    rm -f -- "$temporary"
    return 1
  fi
  migration_created_files+=("$fragment")
  migration_created_sources["$fragment"]="$legacy"
  log "initialized local Zathura colors from the recognized generated configuration"
}

rollback_target_migrations() {
  local status=$? relative staged target resolved expected created legacy restore_failed=0

  trap - EXIT
  set +e
  ((migration_active == 1)) || exit "$status"
  log "restoring target files after unsuccessful reconciliation" >&2

  for created in "${migration_created_files[@]}"; do
    legacy="${migration_created_sources[$created]}"
    if [[ -f "$created" && ! -L "$created" ]] &&
      cmp -s -- "$created" <(render_legacy_zathura_colors "$legacy"); then
      rm -f -- "$created"
    else
      log "WARNING: retained changed migration output at $created" >&2
    fi
  done

  for relative in "${migration_targets[@]}"; do
    staged="$migration_stage/targets/$relative"
    [[ -e "$staged" || -L "$staged" ]] || continue
    target="$TARGET_DIR/$relative"
    if [[ -L "$target" ]]; then
      resolved="$(readlink -f -- "$target" 2>/dev/null || true)"
      expected="$(readlink -f -- "${migration_sources[$relative]}" 2>/dev/null || true)"
      if [[ -n "$resolved" && "$resolved" == "$expected" ]]; then
        rm -f -- "$target"
      else
        log "ERROR: refusing to replace unexpected link while restoring $target" >&2
        restore_failed=1
        continue
      fi
    elif [[ -e "$target" ]]; then
      log "ERROR: refusing to replace unexpected path while restoring $target" >&2
      restore_failed=1
      continue
    fi
    mkdir -p -- "${target%/*}"
    if ! mv -- "$staged" "$target"; then
      log "ERROR: could not restore $target" >&2
      restore_failed=1
    fi
  done

  if ((restore_failed == 0)); then
    rm -r -- "$migration_stage"
  else
    log "ERROR: retained recovery files under $migration_stage" >&2
  fi
  exit "$status"
}

apply_target_migrations() {
  local relative target staged

  # Keep originals on the target filesystem so each move is atomic. The EXIT
  # trap restores them if the real Stow transaction fails after its preflight.
  migration_stage="$(mktemp -d --tmpdir="$TARGET_DIR" '.dotfiles-stow-migration.XXXXXX')"
  chmod 700 "$migration_stage"
  migration_active=1
  trap rollback_target_migrations EXIT

  for relative in "${migration_targets[@]}"; do
    target="$TARGET_DIR/$relative"
    staged="$migration_stage/targets/$relative"
    mkdir -p -- "${staged%/*}"
    mv -- "$target" "$staged"
    log "migrated $relative: ${migration_reasons[$relative]}"
  done

  for relative in "${migration_targets[@]}"; do
    [[ "${migration_kinds[$relative]}" == "known-zathura" ]] || continue
    prepare_zathura_color_fragment "$migration_stage/targets/$relative" ||
      fail "could not preserve the legacy Zathura color fragment"
  done
}

finish_target_migrations() {
  migration_active=0
  trap - EXIT
  rm -r -- "$migration_stage" || fail "could not remove migration staging directory: $migration_stage"
  migration_stage=""
}

usage() {
  cat <<EOF
Usage: ${0##*/} [OPTIONS]

Reconcile the declared GNU Stow packages with a target directory.

Options:
  --dry-run        Show the planned Stow operations without changing links
  --target DIR     Override the target directory (default: \$HOME)
  -h, --help       Show this help
EOF
}

while (($# > 0)); do
  case "$1" in
  --dry-run)
    DRY_RUN=1
    shift
    ;;
  --target)
    (($# >= 2)) || fail "--target requires a directory"
    TARGET_DIR="$2"
    shift 2
    ;;
  --target=*)
    TARGET_DIR="${1#*=}"
    [[ -n "$TARGET_DIR" ]] || fail "--target requires a directory"
    shift
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    fail "unknown option: $1"
    ;;
  esac
done

for required_command in git stow flock; do
  command -v "$required_command" >/dev/null 2>&1 || fail "missing command: $required_command"
done

git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  fail "not a Git working tree: $REPO_DIR"
# install.sh and sync.sh hold this lock across their complete transactions.
if [[ "${NALDO_DOTFILES_LOCK_HELD:-0}" != 1 ]]; then
  exec 9>"$(git -C "$REPO_DIR" rev-parse --git-path naldo-sync.lock)"
  flock -n 9 || fail "another dotfiles operation is active"
fi
[[ -d "$TARGET_DIR" ]] || fail "target is not a directory: $TARGET_DIR"
TARGET_DIR="$(cd -- "$TARGET_DIR" && pwd -P)"

for package in "${packages[@]}"; do
  [[ -d "$REPO_DIR/$package" ]] || fail "missing Stow package: $package"
done

mapfile -d '' ignored_source_entries < <(
  git -C "$REPO_DIR" ls-files --others --ignored --exclude-standard -z -- "${packages[@]}"
)
((${#ignored_source_entries[@]} == 0)) ||
  fail "ignored generated/private state exists inside a package source"

stow_args=(
  --dir="$REPO_DIR"
  --target="$TARGET_DIR"
  --no-folding
  --restow
)
simulation_args=("${stow_args[@]}" --simulate --verbose=2)

log "checking links under $TARGET_DIR"
if simulation_output="$(LC_ALL=C stow "${simulation_args[@]}" "${packages[@]}" 2>&1)"; then
  simulation_status=0
else
  simulation_status=$?
fi

if ((simulation_status != 0)); then
  if ((simulation_status != 1)) || ! extract_stow_conflicts "$simulation_output"; then
    printf '%s\n' "$simulation_output" >&2
    fail "Stow preflight failed and its conflicts could not be classified"
  fi
  plan_target_migrations || exit 1

  if ((DRY_RUN == 1)); then
    for relative in "${migration_targets[@]}"; do
      log "would migrate $relative: ${migration_reasons[$relative]}"
    done
    log "dry run complete; ${#migration_targets[@]} safe target migration(s) planned"
    exit 0
  fi

  apply_target_migrations
elif ((DRY_RUN == 1)); then
  printf '%s\n' "$simulation_output"
  log "dry run complete"
  exit 0
fi

log "reconciling links under $TARGET_DIR"
stow "${stow_args[@]}" "${packages[@]}" || fail "Stow reconciliation failed after preflight"
((${#migration_targets[@]} == 0)) || finish_target_migrations
log "links reconciled"
