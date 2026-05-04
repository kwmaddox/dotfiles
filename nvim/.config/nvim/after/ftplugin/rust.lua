local bufnr = vim.api.nvim_get_current_buf()

vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.expandtab = true

local function rust_lsp(command)
	return function()
		if vim.fn.exists(":RustLsp") == 0 then
			vim.notify("RustLsp command is not available", vim.log.levels.WARN)
			return
		end

		vim.cmd.RustLsp(command)
	end
end

vim.keymap.set("n", "<leader>a", rust_lsp("codeAction"), { buffer = bufnr, desc = "Rust code action" })
vim.keymap.set("n", "<leader>r", rust_lsp("runnables"), { buffer = bufnr, desc = "Rust runnables" })
vim.keymap.set("n", "<leader>t", rust_lsp("testables"), { buffer = bufnr, desc = "Rust testables" })
vim.keymap.set("n", "<leader>e", rust_lsp("explainError"), { buffer = bufnr, desc = "Rust explain error" })
vim.keymap.set("n", "<leader>c", rust_lsp("flyCheck run"), { buffer = bufnr, desc = "Rust clippy check" })
vim.keymap.set("n", "<leader>d", rust_lsp("debuggables"), { buffer = bufnr, desc = "Rust debuggables" })
vim.keymap.set("n", "K", function()
	if vim.fn.exists(":RustLsp") == 0 then
		vim.notify("RustLsp command is not available", vim.log.levels.WARN)
		return
	end

	vim.cmd.RustLsp({ "hover", "actions" })
end, { buffer = bufnr, desc = "Rust hover actions" })

vim.api.nvim_create_autocmd("BufWritePre", {
	buffer = bufnr,
	callback = function()
		vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 3000 })
	end,
})
