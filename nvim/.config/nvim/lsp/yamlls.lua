return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
  root_markers = { "ansible.cfg", ".git" },
  settings = {
    yaml = {
      keyOrdering = false,
      validate = true,
      hover = true,
      completion = true,
      schemas = {
        ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
        ["https://json.schemastore.org/ansible-playbook.json"] = "ansible/playbooks/*.{yml,yaml}",
      },
    },
  },
}
