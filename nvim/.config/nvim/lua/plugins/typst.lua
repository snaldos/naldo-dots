return {
  {
    "chomosuke/typst-preview.nvim",
    opts = {
      dependencies_bin = {
        tinymist = "tinymist",
        websocat = "websocat",
      },
      extra_args = { "--verbose" },
    },
  },
}
