local M = require("sync")

local function lsp_request(callback)
	local timer = vim.loop.new_timer()

	assert(timer)

	timer:start(2000, 0, function()
		callback("something went wrong")
	end)
end

vim.cmd.messages("clear")

local nested = M.sync(function()
	local response = M.wait_handle_error(M.wrap(lsp_request)())
	vim.print(response)
end)

M.sync(function()
	M.wait_handle_error(nested.run)
end)
	.catch(function(err)
		print("parent error handler " .. err)
	end)
	.run()
