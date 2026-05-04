vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.guifont = "JetBrains Mono:h14"

local function apply_mise_env()
	if vim.fn.executable("mise") == 0 then
		return
	end

	local output = vim.fn.system({ "mise", "env", "--json", "--cd", vim.fn.getcwd() })
	if vim.v.shell_error ~= 0 or output == "" then
		return
	end

	local ok, env = pcall(vim.json.decode, output)
	if not ok or type(env) ~= "table" then
		return
	end

	for key, value in pairs(env) do
		if type(value) == "string" then
			vim.env[key] = value
		end
	end
end

apply_mise_env()

vim.api.nvim_create_autocmd({ "DirChanged" }, {
	callback = apply_mise_env,
})

vim.lsp.enable({ "basedpyright", "ruff", "yamlls" })

vim.keymap.set("n", "<Space>e", vim.diagnostic.open_float)

vim.keymap.set("n", "<leader>s", function()
  vim.cmd("10split")
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "hide"
  vim.bo.swapfile = false
end)

local wiki_root = vim.env.LLM_WIKI_ROOT or vim.fs.joinpath(vim.env.HOME, "LLMWiki")
local wiki_templates = {
	daily = "Daily Journal Template.md",
	query = "Query Page Template.md",
	raw = "Raw Note Template.md",
	review = "Review Template.md",
	source = "Source Template.md",
	wiki = "Wiki Page Template.md",
}

local function wiki_template_path(template)
	local template_file = wiki_templates[template] or template
	return vim.fs.joinpath(wiki_root, "90 Templates", template_file)
end

local function wiki_title_from_path(path)
	local name = vim.fn.fnamemodify(path, ":t:r")
	return name:gsub("-", " ")
end

local function wiki_substitute(line, path)
	local title = wiki_title_from_path(path)
	return line
		:gsub("{{date}}", os.date("%Y-%m-%d"))
		:gsub("{{date:YYYY%-MM%-DD}}", os.date("%Y-%m-%d"))
		:gsub("{{time}}", os.date("%H:%M"))
		:gsub("{{time:HH:mm}}", os.date("%H:%M"))
		:gsub("{{title}}", title)
end

local function wiki_render_template(template, path)
	local template_path = wiki_template_path(template)
	local ok, lines = pcall(vim.fn.readfile, template_path)
	if not ok then
		error("Template not found: " .. template_path)
	end
	return vim.tbl_map(function(line)
		return wiki_substitute(line, path)
	end, lines)
end

local function wiki_insert_template(template)
	local lines = wiki_render_template(template, vim.api.nvim_buf_get_name(0))
	local row = vim.api.nvim_win_get_cursor(0)[1]
	vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

local function wiki_open_with_template(relative_path, template)
	local path = vim.fs.normalize(vim.fs.joinpath(wiki_root, relative_path))
	local exists = vim.uv.fs_stat(path) ~= nil
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	if not exists and template ~= nil then
		vim.fn.writefile(wiki_render_template(template, path), path)
	end
	vim.cmd.edit(vim.fn.fnameescape(path))
end

vim.api.nvim_create_user_command("WikiTemplate", function(opts)
	wiki_insert_template(opts.args)
end, {
	nargs = 1,
	complete = function()
		return vim.tbl_keys(wiki_templates)
	end,
})

vim.api.nvim_create_user_command("WikiNew", function(opts)
	local args = vim.split(opts.args, "%s+")
	local maybe_template = args[#args]
	local template = wiki_templates[maybe_template] and maybe_template or nil
	local relative_path = opts.args
	if template ~= nil then
		table.remove(args)
		relative_path = table.concat(args, " ")
	end
	wiki_open_with_template(relative_path, template)
end, { nargs = "+" })

vim.api.nvim_create_user_command("WikiRaw", function(opts)
	local title = opts.args ~= "" and opts.args or os.date("Raw Note %Y-%m-%d %H%M")
	local filename = title:match("%.md$") and title or (title .. ".md")
	wiki_open_with_template("01 Raw/Inbox/" .. filename, "raw")
end, { nargs = "*" })

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

vim.g.rustaceanvim = {
	server = {
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					allFeatures = true,
				},
				check = {
					command = "clippy",
				},
			},
		},
	},
}

require("lazy").setup({
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {
			flavour = "mocha",
		},
		config = function(_, opts)
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")
		end,
	},
	{
		"saghen/blink.cmp",
		version = "*",
		opts = {
			keymap = { preset = "default" },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},
	{
		"mrcjkb/rustaceanvim",
		branch = "main",
		lazy = false,
	},
	{
		"saecki/crates.nvim",
		event = { "BufRead Cargo.toml" },
		opts = {},
	},
	{
		"ibhagwan/fzf-lua",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>ff", function() require("fzf-lua").files() end, desc = "Find files" },
			{ "<leader>fg", function() require("fzf-lua").live_grep() end, desc = "Live grep" },
			{ "<leader>fb", function() require("fzf-lua").buffers() end, desc = "Find buffers" },
			{ "<leader>fh", function() require("fzf-lua").help_tags() end, desc = "Help tags" },
			{ "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end, desc = "Find document symbols" },
			{ "<leader>fS", function() require("fzf-lua").lsp_workspace_symbols() end, desc = "Find workspace symbols" },
			{
				"<leader>fr",
				function()
					require("fzf-lua").files({
						cwd = vim.fn.getcwd(),
						cmd = "rg --files exercises",
						prompt = "Rustlings> ",
					})
				end,
				desc = "Find Rustlings exercise",
			},
		},
		opts = {},
	},
	{
		"mfussenegger/nvim-dap",
		keys = {
			{ "<F5>", function() require("dap").continue() end, desc = "Debug continue" },
			{ "<F10>", function() require("dap").step_over() end, desc = "Debug step over" },
			{ "<F11>", function() require("dap").step_into() end, desc = "Debug step into" },
			{ "<F12>", function() require("dap").step_out() end, desc = "Debug step out" },
			{ "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Toggle breakpoint" },
		},
		config = function()
			local dap = require("dap")
			if vim.fn.executable("codelldb") == 1 then
				dap.adapters.codelldb = {
					type = "server",
					port = "${port}",
					executable = {
						command = "codelldb",
						args = { "--port", "${port}" },
					},
				}
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = false,
		config = function()
			require("nvim-treesitter").install({ "rust", "toml" })
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "rust", "toml" },
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
	{
		"romus204/tree-sitter-manager.nvim",
		config = function()
			require("tree-sitter-manager").setup({
				auto_install = false,
				highlight = true,
			})
		end,
	},
})
