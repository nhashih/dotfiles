return {
  "3rd/image.nvim",
  opts = {
    backend = "kitty", -- or "ueberzug" if not using kitty
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
      },
    },
  },
}
