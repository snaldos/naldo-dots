# ~/.config/fish/config.fish

if status is-interactive
    set fish_greeting

    # Noctalia's built-in template updates the palette in this real active file.
    if not set -q STARSHIP_CONFIG
        set -l starship_config_home "$HOME/.config"
        if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
            set starship_config_home "$XDG_CONFIG_HOME"
        end
        set -gx STARSHIP_CONFIG "$starship_config_home/starship.toml"
    end

    # Starship prompt
    if command -q starship; and test "$TERM" != linux
        function starship_transient_prompt_func
            starship module character
        end

        starship init fish | source
        enable_transience
    end

    # Better clear
    alias clear "printf '\033[2J\033[3J\033[1;1H'"

    # Optional modern ls replacement
    if command -q eza
        alias ls "eza --icons=auto"
    end

end

# Paths are process-global; Fish's generated universal state stays machine-local.
fish_add_path --path \
    "$HOME/.local/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.ghcup/bin" \
    "$HOME/.npm-global/bin"

# Pixi
if command -q pixi
    pixi completion --shell fish | source
end

# Fedora packages Helix as `hx`; all durable editor consumers use that command.
set -gx EDITOR hx
set -gx VISUAL hx

# Keep provider prompt caches warm during long Pi study/research sessions.
set -gx PI_CACHE_RETENTION long

# Optional machine-local overrides, intentionally ignored by Git.
if test -r "$__fish_config_dir/local.fish"
    source "$__fish_config_dir/local.fish"
end
