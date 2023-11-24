local co = coroutine

local wrap = function(func)
	assert(type(func) == "function", "type error :: expected func")
	local factory = function(...)
		local params = { ... }
		local thunk = function(step)
			table.insert(params, step)
			return func(unpack(params))
		end
		return thunk
	end
	return factory
end

local function async(func)
	local m = {
		error_handler = nil,
	}

	local async_thunk_factory = wrap(function(handler, parent_handler_callback)
		assert(type(handler) == "function", "type error :: expected func")
		local thread = co.create(handler)
		local step = nil

		step = function(...)
			local ok, thunk = co.resume(thread, ...)

			-- when an error() is thrown after co-routine is resumed, obviously further
			-- processing stops, and resume returns ok(false) and thunk(error) returns
			-- the error message
			if not ok then
				if m.error_handler then
					m.error_handler(thunk)
					return
				end

				if parent_handler_callback then
					parent_handler_callback(thunk)
					return
				end

				error("unhandled error " .. thunk)
			end

			if co.status(thread) == "dead" and parent_handler_callback then
				parent_handler_callback(thunk)
			else
				assert(type(thunk) == "function", "type error :: expected func")
				thunk(step)
			end
		end

		step()

		return m
	end)

	m.run = async_thunk_factory(func)

	m.catch = function(error_handler)
		m.error_handler = error_handler
		return m
	end

	return m
end

-- many thunks -> single thunk
local join = function(thunks)
	local len = #thunks
	local done = 0
	local acc = {}

	local thunk = function(step)
		if len == 0 then
			return step()
		end
		for i, tk in ipairs(thunks) do
			assert(type(tk) == "function", "thunk must be function")
			local callback = function(...)
				acc[i] = { ... }
				done = done + 1
				if done == len then
					step(unpack(acc))
				end
			end
			tk(callback)
		end
	end
	return thunk
end

-- sugar over coroutine
local await = function(defer)
	assert(type(defer) == "function", "type error :: expected func")
	return co.yield(defer)
end

local await_handle_error = function(defer)
	assert(type(defer) == "function", "type error :: expected func")
	local err, value = co.yield(defer)

	if err then
		error(err)
	end

	return value
end

local await_all = function(defer)
	assert(type(defer) == "table", "type error :: expected table")
	return co.yield(join(defer))
end

return {
	sync = async,
	wait_handle_error = await_handle_error,
	wait = await,
	wait_all = await_all,
	wrap = wrap,
}
