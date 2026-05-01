return {
  cmd = { "uvx", "--from", "basedpyright", "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "pyrightconfig.json", ".git" },
  settings = {
    basedpyright = {
      analysis = {
        typeCheckingMode = "standard", -- "off", "basic", "standard", "strict"
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
}
