if status is-interactive
    set -gx LV_BRANCH release-1.4/neovim-0.9
    fastfetch
end

set fish_greeting
# Web Development
alias bi="bun install"
alias bd="bun run dev"
alias bp="bun run preview"
alias bb="bun run build"
alias bl="bun run lint"

# System
alias sp="systemctl suspend"

fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

fish_add_path (go env GOPATH)/bin

set -Ux PATH $HOME/.bun/bin $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

set -gx EDITOR nvim
set -gx VISUAL nvim
