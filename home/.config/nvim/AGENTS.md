# AGENTS.md

- LazyVim starter template (see README.md)
- Entry point: `init.lua`
- Plugin specs: `lua/plugins/` (lazy.nvim managed)
- Update plugins: `:Lazy sync` in nvim, commit `lazy-lock.json` changes
- Validate config: `nvim --headless -c 'qa!'` (checks startup errors)
- Do not manually edit `lazy-lock.json`
