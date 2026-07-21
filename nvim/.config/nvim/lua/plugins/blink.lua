return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}

      opts.keymap["<M-j>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_next()
          end
        end,
        "fallback",
      }

      opts.keymap["<M-k>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_prev()
          end
        end,
        "fallback",
      }

      -- Accept the selected completion and remain in Insert mode
      opts.keymap["<M-l>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.select_and_accept()
          end
        end,
        "fallback",
      }

      -- Cancel completion and remain in Insert mode
      opts.keymap["<M-h>"] = {
        function(cmp)
          if cmp.is_visible() then
            return cmp.cancel()
          end
        end,
        "fallback",
      }
    end,
  },
}
