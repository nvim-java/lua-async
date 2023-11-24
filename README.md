# [Lua Async Await](https://github.com/nvim-java/lua-async-await)

This is basically [ms-jpq/lua-async-await](https://github.com/ms-jpq/lua-async-await) but with Promise like error handling

Refer the original repository for more comprehensive documentation on how all this works

## Why?

A Language Server command response contains two parameters. `error` & `response`. If the error is present
then the error should be handled.

Ex:-

```lua
self.client.request('workspace/executeCommand', cmd_info, function(err, res)
	if err then
		log.error(command .. ' failed! arguments: ', arguments, ' error: ', err)
	else
		log.debug(command .. ' success! response: ', res)
	end
end, buffer)
```

Promises are fine but chaining is annoying specially when you don't have arrow function like
syntactic sugar. Moreover, at the time of this is writing, Lua language server generics typing
is so primitive and cannot handle `Promise<Something>` like types.

So I wanted Promise like error handling but without Promises.

## How to use

Assume following is the asynchronous API

```lua
local function lsp_request(callback)
	local timer = vim.loop.new_timer()

	assert(timer)

	timer:start(2000, 0, function()
		-- First parameter is the error
		callback('something went wrong', nil)
	end)
end
```

### When no error handler defined

This is how you can call this asynchronous API without a callback

```lua
local M = require('sync')

M.sync(function()
	local response = M.wait_handle_error(M.wrap(lsp_request)())
end).run()
```

Result:

```
Error executing luv callback:
test6.lua:43: unhandled error test6.lua:105: something went wrong
stack traceback:
	[C]: in function 'error'
	test6.lua:43: in function 'callback'
	test6.lua:130: in function <test6.lua:129>
```

### When error handler is defined

```lua
local M = require('sync')

local main = M.sync(function()
	local response = M.wait_handle_error(M.wrap(lsp_request)())
end)
	.catch(function(err)
		print('error occurred ', err)
	end)
	.run()
```

Result:

```
error occured  test6.lua:105: something went wrong
```

### When nested

```lua
local M = require('sync')

local nested = M.sync(function()
	local response = M.wait_handle_error(M.wrap(lsp_request)())
end)

M.sync(function()
	M.wait_handle_error(nested.run)
end)
	.catch(function(err)
		print('parent error handler ' .. err)
	end)
	.run()
```

Result:

```
parent error handler test6.lua:105: test6.lua:105: something went wrong
```
