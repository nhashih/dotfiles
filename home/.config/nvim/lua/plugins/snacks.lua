return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  opts = {
    explorer = {
      enabled = true,
    },

    picker = {
      enabled = true,

      sources = {
        explorer = {
          git_status = true,
          git_untracked = true,
          tree = true,
          ignored = true,
          hidden = true,

          win = {
            list = {
              keys = {
                ["gy"] = {
                  "yank_relative_cwd",
                  mode = { "n", "x" },
                  desc = "Yank path relative to cwd",
                },
                ["gY"] = {
                  "yank_relative_home",
                  mode = { "n", "x" },
                  desc = "Yank path relative to home",
                },
              },
            },
          },

          actions = {
            yank_relative_cwd = function(picker)
              local item = picker:current({ resolve = true })

              if not item then
                vim.notify("No item selected", vim.log.levels.WARN)
                return
              end

              local file = item.file or item.text
              if not file then
                vim.notify("No file path found", vim.log.levels.WARN)
                return
              end

              local path = vim.fn.fnamemodify(file, ":.")
              vim.fn.setreg("+", path)
              vim.fn.setreg('"', path)
              vim.notify("Yanked: " .. path)
            end,

            yank_relative_home = function(picker)
              local item = picker:current({ resolve = true })

              if not item then
                vim.notify("No item selected", vim.log.levels.WARN)
                return
              end

              local file = item.file or item.text
              if not file then
                vim.notify("No file path found", vim.log.levels.WARN)
                return
              end

              local path = vim.fn.fnamemodify(file, ":~")
              vim.fn.setreg("+", path)
              vim.fn.setreg('"', path)
              vim.notify("Yanked: " .. path)
            end,
          },
        },
      },
    },
  },

  keys = {
    {
      "<leader>e",
      function()
        Snacks.explorer()
      end,
      desc = "File Explorer",
    },
  },
}
