local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local image = require("moonimage")

local vec2 = glmath.vec2
local vec3 = glmath.vec3
local vec4 = glmath.vec4
local mat4 = glmath.mat4

local float_s = gl.sizeof('float')
local vec2_s = float_s*2
local vec3_s = float_s*3
local vec4_s = float_s*4

local utils = {
	vec2 = vec2,
	vec3 = vec3,
	vec4 = vec4,
	mat4 = mat4,
	float_s = float_s,
	vec2_s = vec2_s,
	vec3_s = vec3_s,
	vec4_s = vec4_s,
}



-- print a table(recursive), but don't go into loops
-- max_i is the maximum recursion level,
-- max_l is the maximum list length  displayed
function utils.table_dump(t, max_i, max_l, i, seen)
	local i = i or 0
	local max_i = max_i or 7
	local max_l = max_l or math.huge
	local seen = seen or {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			if seen[v] then -- prevent loops
				print(("%s%s: \t %s (omitted, already seen)"):format(("\t"):rep(i), tostring(k), tostring(v)))
			elseif tostring(v):sub(1,1) == "{" then -- vector/matrix
				print(("%s%s: \t %s"):format(("\t"):rep(i), tostring(k), tostring(v)))
			else -- normal table
				seen[v] = true
				print(("%s%s: \t %s(#%d):"):format(("\t"):rep(i), tostring(k), tostring(v), #v))
				if i+1 <= max_i then
					utils.table_dump(v,max_i, max_l, i+1, seen)
				end
			end
		else -- normal value
			print(("%s%s: \t %s"):format(("\t"):rep(i), tostring(k), tostring(v)))
		end
		if type(k) == "number" and (#t>=max_l) and (k>=max_l) then
			print(("\t"):rep(i).."(more elements ommited) ...")
			break
		end
	end
end

-- Create a new opengl texture from a file, return tex_id
function utils.load_texture(filepath)
	local texture_id = gl.new_texture('2d')
	gl.texture_parameter('2d', 'wrap s', 'repeat')
	gl.texture_parameter('2d', 'wrap t', 'repeat')
	gl.texture_parameter('2d', 'min filter', 'linear')
	gl.texture_parameter('2d', 'mag filter', 'nearest')
	local data, width, height = image.load(filepath, 'rgb')
	gl.texture_image('2d', 0, 'rgb', 'rgb', 'ubyte', data, width, height)
	gl.generate_mipmap('2d')
	gl.unbind_texture('2d')
	print("Loaded texture", filepath, texture_id)
	return texture_id
end




return utils
