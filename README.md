# lua-async

Synchronous like asynchronous for Lua.

## What

Take a look at before and after

**Before:**

```lua
request('workspace/executeCommand', cmd_info, function(err, res)
  if err then
    log.error(err)
  else
    log.debug(res)
  end
end, buffer)
```

**After:**

```lua
-- on error, statement will fail throwing an error just like any synchronous API
local result  = request('workspace/executeCommand', cmd_info, buffer)
log.debug(result)
```

## Why

Well, callback creates callback hell.

## How to use

```lua
local runner = require("async.runner")
local wrap = require("async.wrap")
local wait = require("async.waits.wait_with_error_handler")

local function success_async(callback)
  local timer = vim.loop.new_timer()

  assert(timer)

  timer:start(2000, 0, function()
    -- First parameter is the error
    callback(nil, "hello world")
  end)
end

local function fail_async(callback)
  local timer = vim.loop.new_timer()

  assert(timer)

  timer:start(2000, 0, function()
    -- First parameter is the error
    callback("something went wrong", nil)
  end)
end

local function log(message)
  vim.print(os.date("%H:%M:%S") .. " " .. message)
end

vim.cmd.messages("clear")

local nested = runner(function()
  local success_sync = wrap(success_async)
  local fail_sync = wrap(fail_async)

  local success_result = wait(success_sync())
  -- here we get the result because there is no error
  log("success_result is: " .. success_result)

  -- following is going to fail and error will get caught by
  -- the parent runner function's 'catch'
  wait(fail_sync())
end)

runner(function()
    log("starting the execution")
    -- just wait for nested runner to complete the execution
    wait(nested.run)
  end)
  .catch(function(err)
    log("parent error handler " .. err)
  end)
  .run()
```

### Output

```txt
18:44:46 starting the execution
18:44:48 success_result is: hello world
18:44:50 parent error handler ...-async-await/lua/async/waits/wait_with_error_handler.lua:14: ...-async-await/lua/async/waits/wait_with_error_handler.lua:14: something went wrong
```
