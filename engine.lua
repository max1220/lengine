#!/usr/bin/env lua5.3
local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local utils = require("utils")
local time = require("time")


local function run(state)

	-- call a game callbacks
	local function try_callback(callback_name, ...)
		if state[callback_name] then
			return state[callback_name](state, ...)
		end
	end

	-- GL callback for keyboard events
	state.keyboard = {}
	local function keyboard_cb(window, key, code, action)
		if action == "press" then
			state.keyboard[key] = true
		elseif action == "release" then
			state.keyboard[key] = false
		end
		try_callback("on_keyboard", window, key, code, action)
	end

	-- GL callback for mouse button events
	state.mouse = {
		sensitivity = 0.01,
		dx = 0,
		dy = 0,
		x = 0,
		y = 0,
		capture = false
	}
	local function mouse_button_cb(window, button, action)
		if button and (action=="press") then
			state.mouse[button] = true
		elseif button and (action=="release") then
			state.mouse[button] = false
		end
		try_callback("on_mouse_button", window, button, action)
	end

	-- GL callback for mouse movement events
	local function mouse_pos_cb(window, x, y)
		local dx = x - state.mouse.x
		local dy = y - state.mouse.y
		state.mouse.dx = state.mouse.dx + dx
		state.mouse.dy = state.mouse.dy + dy
		state.mouse.x = x
		state.mouse.y = y
		try_callback("on_mouse_position", window, x, y)
	end

	local function reshape_callback(window, width, height)
		try_callback("on_reshape", window, width, height)
	end

	-- create a glfw window, setup callbacks for input events, setup opengl
	local function gl_init(config)
		local w = tonumber(state.width) or 800
		local h = tonumber(state.height) or 600
		local title = tostring(config.title or "")
		local major = config.opengl_major or 3
		local minor = config.opengl_minor or 3
		local profile = config.opengl_profile or "core"

		glfw.window_hint("context version major", major)
		glfw.window_hint("context version minor", minor)
		glfw.window_hint("opengl profile", profile)
		local window = glfw.create_window(w, h, title)
		glfw.make_context_current(window)
		gl.init()

		glfw.set_key_callback(window, keyboard_cb)
		glfw.set_mouse_button_callback(window, mouse_button_cb)
		glfw.set_cursor_pos_callback(window, mouse_pos_cb)
		glfw.set_framebuffer_size_callback(window, reshape_callback)

		state.window = window
		return window
	end

	-- check events, call draw(dt), then swap buffers(and terminate if window closed)
	local function gl_loop(window, draw)
		local last = gl.get_timestamp()
		while not glfw.window_should_close(window) do
			glfw.poll_events()
			local now = gl.get_timestamp()
			local dt = (now - last)/1000000000
			last = now
			draw(dt)
			glfw.swap_buffers(window)
		end
	end


	-- callback when we can draw an image
	local function draw_cb(dt)
		try_callback("on_update", dt)
		try_callback("on_draw")
	end

	local window = gl_init({
		width = 800,
		height = 600,
		keyboard_callback = keyboard_cb,
		mouse_position_callback = mouse_pos_cb,
		mouse_button_callback = mouse_button_cb,
	})

	try_callback("on_init", window)

	gl_loop(window, draw_cb)
end

run(require("game"))
