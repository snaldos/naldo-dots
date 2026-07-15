# ~/.config/fish/config.fish

if status is-interactive
    set fish_greeting

    # Prefer Noctalia's rendered config, with the tracked base as fallback.
    if not set -q STARSHIP_CONFIG
        if test -f "$HOME/.config/starship.toml"
            set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"
        else
            set -gx STARSHIP_CONFIG "$HOME/.config/starship.base.toml"
        end
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

    # Kitty SSH integration
    if test "$TERM" = xterm-kitty
        alias ssh "kitten ssh"
    end
end

# Conda
if test -f "$HOME/miniconda3/bin/conda"
    eval "$HOME/miniconda3/bin/conda" "shell.fish" hook $argv | source
else if test -f "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
    source "$HOME/miniconda3/etc/fish/conf.d/conda.fish"
else if test -d "$HOME/miniconda3/bin"
    fish_add_path "$HOME/miniconda3/bin"
end

# Paths are process-global; Fish's generated universal state stays machine-local.
fish_add_path --path \
    "$HOME/.local/bin" \
    "$HOME/.ghcup/bin" \
    "$HOME/.npm-global/bin"

# Pixi
if command -q pixi
    pixi completion --shell fish | source
end

# Neovim / editor
alias nvim "env SHELL=/bin/bash nvim"
set -gx EDITOR "env SHELL=/bin/bash nvim"
set -gx VISUAL "env SHELL=/bin/bash nvim"

# Keep provider prompt caches warm during long Pi study/research sessions.
set -gx PI_CACHE_RETENTION long
