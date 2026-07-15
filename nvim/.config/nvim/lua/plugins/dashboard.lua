return {
  {
    "snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = opts.dashboard or {}

      opts.dashboard.sections = {
        {
          section = "terminal",
          cmd = [[sh -lc 'wallpaper="$(noctalia msg wallpaper-get 2>/dev/null)"; [ -f "$wallpaper" ] || wallpaper="$HOME/.config/wall.png"; chafa "$wallpaper" --format symbols --symbols vhalf --size 60x17 --stretch; sleep .1']],
          height = 17,
          padding = 1,
        },
        {
          pane = 2,
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      }
    end,
  },
}
