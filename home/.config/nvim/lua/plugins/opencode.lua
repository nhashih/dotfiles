return {
  "nickjvandyke/opencode.nvim",
  dependencies = {
    -- Dibutuhkan untuk input dan picker UI
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  keys = {
    {
      "<leader>aa",
      function()
        require("opencode").toggle()
      end,
      mode = { "n" },
      desc = "Toggle OpenCode",
    },
    {
      "<leader>ai",
      function()
        require("opencode").ask("", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "OpenCode Ask",
    },
    {
      "<leader>ab",
      function()
        require("opencode").ask("@file ", { submit = true })
      end,
      mode = { "n", "x" },
      desc = "Ask about Buffer",
    },
    {
      "<leader>ae",
      function()
        require("opencode").prompt("explain")
      end,
      mode = { "n", "x" },
      desc = "Explain Code",
    },
    {
      "<leader>af",
      function()
        require("opencode").prompt("fix")
      end,
      mode = { "n", "x" },
      desc = "Fix Diagnostics",
    },
  },
  opts = {
    -- Kamu bisa menambahkan konfigurasi model di sini jika perlu
  },
}
