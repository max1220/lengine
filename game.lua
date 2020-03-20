--luacheck: no max line length, ignore self

local gl = require("moongl")
local glfw = require("moonglfw")
local glmath = require("moonglmath")
local assimp = require("moonassimp")

local utils = require("utils")
local random = require("random")
local chunk_manager = require("chunk_manager")
local chunk_generator = require("chunk_generator")

local vec2 = utils.vec2
local vec3 = utils.vec3
local vec4 = utils.vec4
local mat4 = utils.mat4
local float_s = utils.float_s
local vec2_s = utils.vec2_s
local vec3_s = utils.vec3_s
local vec4_s = utils.vec4_s


--[[
TODO:
 * Multiple lights(Store light position/color in VBO)
 * chunk meshing
 * materials(duffuse, specular) per block
]]




local game = {
	width = 800,
	height = 600,
	title = "Test!",
	opengl_major = 3,
	opengl_minor = 3,
	opengl_profile = 'core'
}

function game:new_static_object(vertices, colors, normals, tex_cords, model_matrix)
	assert((#vertices == #colors) and (#vertices == #normals) and (#vertices == #tex_cords))
	local object = {}
	object.vertices_len = #vertices
	object.vertices = assert(vertices)
	object.colors = assert(colors)
	object.normals = assert(normals)
	object.tex_cords = assert(tex_cords)
	object.model_matrix = assert(model_matrix)

	function object.update_buffer(_self)
		assert((#_self.vertices == #_self.colors) and (#_self.vertices == #_self.normals) and (#_self.vertices == #_self.tex_cords))

		gl.bind_buffer("array", _self.vbo)
		local buffer_size = #_self.vertices*vec4_s + #_self.colors*vec4_s + #_self.normals*vec3_s + #_self.tex_cords*vec2_s
		gl.buffer_data("array", buffer_size, "static draw")

		-- push all vertices and colors to the array buffer
		local color_offset = gl.buffer_sub_data("array", 0, gl.pack("float", _self.vertices))
		local normal_offset = color_offset + gl.buffer_sub_data("array", color_offset, gl.pack("float", _self.colors))
		local tex_cords_offset = normal_offset + gl.buffer_sub_data("array", normal_offset, gl.pack("float", _self.normals))
		gl.buffer_sub_data("array", tex_cords_offset, gl.pack("float", _self.tex_cords))

		-- set the vertex array configuration for the VAO
		gl.bind_vertex_array(_self.vao)
		gl.vertex_attrib_pointer(self.vertex_attributes.vPosition, 4, "float", false, 0, 0)
		gl.vertex_attrib_pointer(self.vertex_attributes.vColor, 4, "float", false, 0, color_offset)
		gl.vertex_attrib_pointer(self.vertex_attributes.vNormal, 3, "float", false, 0, normal_offset)
		gl.vertex_attrib_pointer(self.vertex_attributes.vTexCord, 2, "float", false, 0, tex_cords_offset)
	end

	-- create vertex array object to store info about vertex atribute buffer
	local vao = gl.new_vertex_array()
	object.vao = vao

	-- store new buffer(vertex buffer object) in array buffer
	local buffer = gl.new_buffer("array");
	object.vbo = buffer

	-- enable the vertex array configuration for the VAO
	gl.enable_vertex_attrib_array(self.vertex_attributes.vPosition)
	gl.enable_vertex_attrib_array(self.vertex_attributes.vColor)
	gl.enable_vertex_attrib_array(self.vertex_attributes.vNormal)
	gl.enable_vertex_attrib_array(self.vertex_attributes.vTexCord)

	object:update_buffer()

	return object
end

function game:new_cube(colors, texCoords, model_matrix)
	--[[
	unit cube
	A cube has 6 sides and each side has 4 vertices, therefore, the total number
	of vertices is 24 (6 sides * 4 verts), and 72 floats in the vertex array
	since each vertex has 3 components (x,y,z) (= 24 * 3)
	    v6----- v5
	   /|      /|
	  v1------v0|
	  | |     | |
	  | v7----|-v4
	  |/      |/
	  v2------v3
	]]
	-- vertex position array
	local vertices  = {
		vec4( 0.5, 0.5, 0.5, 1), vec4(-0.5, 0.5, 0.5, 1), vec4(-0.5,-0.5, 0.5, 1), vec4( 0.5,-0.5, 0.5, 1), -- v0,v1,v2,v3 (front)
		vec4( 0.5, 0.5, 0.5, 1), vec4( 0.5,-0.5, 0.5, 1), vec4( 0.5,-0.5,-0.5, 1), vec4( 0.5, 0.5,-0.5, 1), -- v0,v3,v4,v5 (right)
		vec4( 0.5, 0.5, 0.5, 1), vec4( 0.5, 0.5,-0.5, 1), vec4(-0.5, 0.5,-0.5, 1), vec4(-0.5, 0.5, 0.5, 1), -- v0,v5,v6,v1 (top)
		vec4(-0.5, 0.5, 0.5, 1), vec4(-0.5, 0.5,-0.5, 1), vec4(-0.5,-0.5,-0.5, 1), vec4(-0.5,-0.5, 0.5, 1), -- v1,v6,v7,v2 (left)
		vec4(-0.5,-0.5,-0.5, 1), vec4( 0.5,-0.5,-0.5, 1), vec4( 0.5,-0.5, 0.5, 1), vec4(-0.5,-0.5, 0.5, 1), -- v7,v4,v3,v2 (bottom)
		vec4( 0.5,-0.5,-0.5, 1), vec4(-0.5,-0.5,-0.5, 1), vec4(-0.5, 0.5,-0.5, 1), vec4( 0.5, 0.5,-0.5, 1)  -- v4,v7,v6,v5 (back)
	};

	-- normal array
	local normals = {
		vec3( 0, 0, 1), vec3( 0, 0, 1), vec3( 0, 0, 1), vec3( 0, 0, 1),  -- v0,v1,v2,v3 (front)
		vec3( 1, 0, 0), vec3( 1, 0, 0), vec3( 1, 0, 0), vec3( 1, 0, 0),  -- v0,v3,v4,v5 (right)
		vec3( 0, 1, 0), vec3( 0, 1, 0), vec3( 0, 1, 0), vec3( 0, 1, 0),  -- v0,v5,v6,v1 (top)
		vec3(-1, 0, 0), vec3(-1, 0, 0), vec3(-1, 0, 0), vec3(-1, 0, 0),  -- v1,v6,v7,v2 (left)
		vec3( 0,-1, 0), vec3( 0,-1, 0), vec3( 0,-1, 0), vec3( 0,-1, 0),  -- v7,v4,v3,v2 (bottom)
		vec3( 0, 0,-1), vec3( 0, 0,-1), vec3( 0, 0,-1), vec3( 0, 0,-1)   -- v4,v7,v6,v5 (back)
	}

	-- colour array
	local _colors = colors or {
		vec4(1, 1, 1, 1), vec4(1, 1, 0, 1), vec4(1, 0, 0, 1), vec4(1, 0, 1, 1), -- v0,v1,v2,v3 (front)
		vec4(1, 1, 1, 1), vec4(1, 0, 1, 1), vec4(0, 0, 1, 1), vec4(0, 1, 1, 1), -- v0,v3,v4,v5 (right)
		vec4(1, 1, 1, 1), vec4(0, 1, 1, 1), vec4(0, 1, 0, 1), vec4(1, 1, 0, 1), -- v0,v5,v6,v1 (top)
		vec4(1, 1, 0, 1), vec4(0, 1, 0, 1), vec4(0, 0, 0, 1), vec4(1, 0, 0, 1), -- v1,v6,v7,v2 (left)
		vec4(0, 0, 0, 1), vec4(0, 0, 1, 1), vec4(1, 0, 1, 1), vec4(1, 0, 0, 1), -- v7,v4,v3,v2 (bottom)
		vec4(0, 0, 1, 1), vec4(0, 0, 0, 1), vec4(0, 1, 0, 1), vec4(0, 1, 1, 1)  -- v4,v7,v6,v5 (back)
	}

	-- texture coord array
	local _texCoords = texCoords or {
		vec2(1, 0), vec2(0, 0), vec2(0, 1), vec2(1, 1), -- v0,v1,v2,v3 (front)
		vec2(0, 0), vec2(0, 1), vec2(1, 1), vec2(1, 0), -- v0,v3,v4,v5 (right)
		vec2(1, 1), vec2(1, 0), vec2(0, 0), vec2(0, 1), -- v0,v5,v6,v1 (top)
		vec2(1, 0), vec2(0, 0), vec2(0, 1), vec2(1, 1), -- v1,v6,v7,v2 (left)
		vec2(0, 1), vec2(1, 1), vec2(1, 0), vec2(0, 0), -- v7,v4,v3,v2 (bottom)
		vec2(0, 1), vec2(1, 1), vec2(1, 0), vec2(0, 0)  -- v4,v7,v6,v5 (back)
	}

	-- index array for glDrawElements()
	-- A cube requires 36 indices = 6 sides * 2 tris * 3 verts
	local indices = {
		 0, 1, 2,   2, 3, 0, -- v0-v1-v2, v2-v3-v0 (front)
		 4, 5, 6,   6, 7, 4, -- v0-v3-v4, v4-v5-v0 (right)
		 8, 9,10,  10,11, 8, -- v0-v5-v6, v6-v1-v0 (top)
		12,13,14,  14,15,12, -- v1-v6-v7, v7-v2-v1 (left)
		16,17,18,  18,19,16, -- v7-v4-v3, v3-v2-v7 (bottom)
		20,21,22,  22,23,20  -- v4-v7-v6, v6-v5-v4 (back)
	}

	local vertexBuffer, colorBuffer, normalBuffer, textureBuffer = {},{},{},{}
	for i=1, 36 do
		vertexBuffer[i] = vertices[indices[i]+1]
		colorBuffer[i] = _colors[indices[i]+1]
		normalBuffer[i] = normals[indices[i]+1]
		textureBuffer[i] = _texCoords[indices[i]+1]
	end

	local cube_obj = game:new_static_object(vertexBuffer, colorBuffer, normalBuffer, textureBuffer, model_matrix or mat4())
	return cube_obj
end



function game:new_test()
	local scene = assimp.import_file("assets/teapot.obj", 'triangulate', 'gen smooth normals')
	local mesh = scene:meshes()[1]
	local vertices = {}
	local normals = {}
	local colors = {}
	local tex_cords = {}
	local has_colors = mesh:has_colors(1)

	for i=1, mesh:num_vertices() do
		local x,y,z = mesh:position(i)
		vertices[i] = vec4(x,y,z, 1)
		if has_colors then
			local r,g,b,a = mesh:color(1, i)
			colors[i] = vec4(r,g,b,a)
		else
			colors[i] = vec4(1,1,1, 1)
		end
		local nx,ny,nz = mesh:normal(i)
		normals[i] = vec3(nx,ny,nz,1)
		tex_cords[i] = vec2(0,0)
	end

	local obj = self:new_static_object(vertices, colors, normals, tex_cords, mat4())
	return obj
end

function game:add_uniform(uniform_name)
	local uniform_loc = gl.get_uniform_location(self.program, uniform_name)
	self.uniforms = self.uniforms or {}
	self.uniforms[uniform_name] = uniform_loc
	return uniform_loc
end

function game:add_vertex_attribute(attribute_name)
	local attribute_loc = gl.get_attrib_location(self.program, attribute_name)
	self.vertex_attributes[attribute_name] = attribute_loc
	return attribute_loc
end

function game:update_camera()
	self.projection_matrix = glmath.perspective(math.rad(self.camera.fov), self.camera.ar, self.camera.near, self.camera.far)
	--self.view_matrix = glmath.rotate(self.camera.rotation.x, vec3(-1,0,0))*glmath.rotate(self.camera.rotation.y, vec3(-1,0,0))*glmath.translate(vec3(self.camera.x, self.camera.y, self.camera.z))
	self.view_matrix = glmath.rotate(self.camera.rotation.x, vec3(-1,0,0))*glmath.rotate(self.camera.rotation.y, vec3(0,-1,0))*glmath.translate(vec3(self.camera.position.x, self.camera.position.y, self.camera.position.z))
	--self.view_matrix = glmath.look_at(vec3(0,0,-4), vec3(0,0,0), vec3(0,1,0))
end

function game:generate_cube_tileset(tiles_x, tiles_y, tile_mapping)
	-- return a table that maps a tile_id to a set of texture coordinates for a cube.
	local tileset = {}
	local _tile_mapping = tile_mapping or {}
	local tile_w, tile_h = 1/tiles_x, 1/tiles_y
	for tile_id=1, tiles_x*tiles_y do
		local mapping = _tile_mapping[tile_id] or {}
		local tile_map = {
			front  = mapping.front  or {vec2(1, 0), vec2(0, 0), vec2(0, 1), vec2(1, 1)}, -- v0,v1,v2,v3 (front)
			right  = mapping.right  or {vec2(0, 0), vec2(0, 1), vec2(1, 1), vec2(1, 0)}, -- v0,v3,v4,v5 (right)
			top    = mapping.top    or {vec2(1, 1), vec2(1, 0), vec2(0, 0), vec2(0, 1)}, -- v0,v5,v6,v1 (top)
			left   = mapping.left   or {vec2(1, 0), vec2(0, 0), vec2(0, 1), vec2(1, 1)}, -- v1,v6,v7,v2 (left)
			bottom = mapping.bottom or {vec2(0, 1), vec2(1, 1), vec2(1, 0), vec2(0, 0)}, -- v7,v4,v3,v2 (bottom)
			back   = mapping.back   or {vec2(0, 1), vec2(1, 1), vec2(1, 0), vec2(0, 0)}  -- v4,v7,v6,v5 (back)
		}

		for k,cords in pairs(tile_map) do
			local id = cords.tile_id or tile_id
			local _x = (id-1) % tiles_x
			local _y = math.floor((id-1) / tiles_y)
			local tile_x, tile_y = _x*tile_w, _y*tile_h
			local new_cords = {
				vec2(tile_x + (cords[1].x * tile_w), tile_y + (cords[1].y * tile_h)),
				vec2(tile_x + (cords[2].x * tile_w), tile_y + (cords[2].y * tile_h)),
				vec2(tile_x + (cords[3].x * tile_w), tile_y + (cords[3].y * tile_h)),
				vec2(tile_x + (cords[4].x * tile_w), tile_y + (cords[4].y * tile_h))
			}
			tile_map[k] = new_cords
		end

		local tex_cords = {
			tile_map.front  [1], tile_map.front  [2],tile_map.front  [3],tile_map.front  [4],
			tile_map.right  [1], tile_map.right  [2],tile_map.right  [3],tile_map.right  [4],
			tile_map.top    [1], tile_map.top    [2],tile_map.top    [3],tile_map.top    [4],
			tile_map.left   [1], tile_map.left   [2],tile_map.left   [3],tile_map.left   [4],
			tile_map.bottom [1], tile_map.bottom [2],tile_map.bottom [3],tile_map.bottom [4],
			tile_map.back   [1], tile_map.back   [2],tile_map.back   [3],tile_map.back   [4],
		}

		tileset[tile_id] = tex_cords
	end
	return tileset
end

function game:load_texture(filepath)
	local texture_id = utils.load_texture(filepath)
	self.textures[filepath] =texture_id
	return texture_id
end

function game:update_chunks()
	local chunk_ox = math.floor((-self.camera.position.x/self.chunk_w)+0.5)
	local chunk_oz = math.floor((-self.camera.position.z/self.chunk_d)+0.5)

	self.objects = {}

	local view_dist = self.view_dist
	for x=-view_dist, view_dist do
		for z=-view_dist, view_dist do
			local chunk = self.chunk_manager:get_chunk(chunk_ox+x,0,chunk_oz+z)
			if not chunk.object then
				chunk.object = self:new_chunk_object(chunk.data, self.cube_tileset)
				chunk.object.model_matrix = glmath.translate(chunk.x*self.chunk_w, chunk.y*self.chunk_h, chunk.z*self.chunk_d)
			end
			table.insert(self.objects, chunk.object)
		end
	end
end

function game:on_mouse_position(_, x, y)
end

function game:on_mouse_button(_, btn, action)
	--print("mouse button:",btn, action)
	if (btn == "left") and (action == "press") and (not self.mouse.capture) then
		glfw.set_input_mode(self.window, "cursor", "disabled")
	elseif (btn == "left") and (action == "release") and (not self.mouse.capture) then
		glfw.set_input_mode(self.window, "cursor", "normal")
	end
end

function game:on_keyboard(_, key, code, action)
	if (key == "escape") and (action == "press") then
		glfw.set_window_should_close(self.window, true)
	elseif (key == "c") and (action == "press") then
		self.mouse.capture = not self.mouse.capture
		if self.mouse.capture then
			glfw.set_input_mode(self.window, "cursor", "disabled")
		else
			glfw.set_input_mode(self.window, "cursor", "normal")
		end
	end
end

function game:on_draw()
	gl.clear("color", "depth")
	for i=1, #self.objects do
		local object = self.objects[i]

		-- prepare for rendering by binding the VAO, and setting the MVP uniforms
		gl.bind_vertex_array(object.vao)
		gl.uniform_matrix(self.uniforms.MAT_M, "float", "4x4", true, gl.flatten(object.model_matrix))
		gl.uniform_matrix(self.uniforms.MAT_V, "float", "4x4", true, gl.flatten(self.view_matrix))
		--gl.uniform_matrix(self.uniforms.MAT_P, "float", "4x4", true, gl.flatten(self.projection_matrix))
		local mvp = self.projection_matrix * self.view_matrix * object.model_matrix
		gl.uniform_matrix(self.uniforms.MAT_MVP, "float", "4x4", true, gl.flatten(mvp))

		gl.active_texture(0)
		gl.bind_texture("2d", self.textures["assets/terrain.png"])
		gl.uniform(self.uniforms.tex_map, "int", 0)

		gl.draw_arrays("triangles", 0, object.vertices_len)
	end
end

function game:on_update(dt)
	self.time = self.time + dt

	local light_pos = vec3(0,(math.sin(self.time*3)+2),0)
	--local cube = self.objects[1]
	--cube.model_matrix = glmath.translate(light_pos)*glmath.scale(0.1)

	gl.uniform(self.uniforms.light_pos, "float", light_pos.x, light_pos.y, light_pos.z)
	gl.uniform(self.uniforms.light_color, "float", 1,0,0)
	gl.uniform(self.uniforms.ambient_color, "float", 0.15,0.15,0.15)

	local speed = 3
	if self.keyboard["left shift"] then
		speed = 10
	end

	if self.keyboard["w"] then
		self.camera.position.x = self.camera.position.x + math.sin(self.camera.rotation.y)*speed*dt
		self.camera.position.z = self.camera.position.z + math.cos(self.camera.rotation.y)*speed*dt
	elseif self.keyboard["s"] then
		self.camera.position.x = self.camera.position.x - math.sin(self.camera.rotation.y)*speed*dt
		self.camera.position.z = self.camera.position.z - math.cos(self.camera.rotation.y)*speed*dt
	end
	if self.keyboard["a"] then
		self.camera.position.x = self.camera.position.x - math.sin(self.camera.rotation.y-(math.pi*0.5))*speed*dt
		self.camera.position.z = self.camera.position.z - math.cos(self.camera.rotation.y-(math.pi*0.5))*speed*dt
	elseif self.keyboard["d"] then
		self.camera.position.x = self.camera.position.x + math.sin(self.camera.rotation.y-(math.pi*0.5))*speed*dt
		self.camera.position.z = self.camera.position.z + math.cos(self.camera.rotation.y-(math.pi*0.5))*speed*dt
	end
	if self.keyboard["q"] then
		self.camera.position.y = self.camera.position.y - speed*dt
	elseif self.keyboard["e"] then
		self.camera.position.y = self.camera.position.y + speed*dt
	end

	self:update_chunks()

	local sensitivity = 0.1
	if self.mouse.left or self.mouse.capture then
		self.camera.rotation.y = (self.camera.rotation.y - self.mouse.dx*sensitivity*dt) %  (math.pi*2)
		self.camera.rotation.x = math.min(math.max(self.camera.rotation.x - self.mouse.dy*sensitivity*dt, -math.pi*0.5), math.pi*0.5)
	end
	self.mouse.dx = 0
	self.mouse.dy = 0


	self:update_camera()
	--local d = (math.sin(self.time*0.443344+12312)+1)*1.5
	--local x = math.sin(self.time*0.5)*d+0.5
	--local y = math.cos(self.time*0.5)*d
	--self.view_matrix = glmath.look_at(vec3(x,2,y), vec3(0,1,0), vec3(0,1,0))
	--self.view_matrix = glmath.look_at(vec3(1,1,1), vec3(0,0.5,0), vec3(0,1,0))

	--print("fps:",1/dt,"dt",dt)
	local vertice_count = 0
	for _, obj in ipairs(self.objects) do
		vertice_count = vertice_count + #obj.vertices
	end
	print("vertice_count", vertice_count)
end

function game:on_init(window)
	print("Starting game...")

	self.window = window
	self.time = 0
	self.view_dist = 1
	self.chunk_w, self.chunk_h, self.chunk_d = 32,16,32

	self.camera = {
		fov = 90,
		ar = 4/3,
		near = 0.01,
		far = 100,
		position = vec3(0,0,0),
		rotation = vec2(0,0)
	}
	self:update_camera()

	self.uniforms = {}
	self.vertex_attributes = {}
	self.textures = {}

	self:load_texture("assets/terrain.png")

	-- setup shader
	self.program = gl.make_program("vertex", "vshader.glsl", "fragment", "fshader.glsl")
	self:add_uniform("light_pos")
	self:add_uniform("light_color")
	self:add_uniform("ambient_color")
	self:add_uniform("tex_map")
	self:add_uniform("MAT_M")
	self:add_uniform("MAT_V")
	--self:add_uniform("MAT_P")
	self:add_uniform("MAT_MVP")
	--self:add_uniform("near")
	--self:add_uniform("far")
	--self:add_uniform("view_pos")
	self:add_vertex_attribute("vPosition")
	self:add_vertex_attribute("vColor")
	self:add_vertex_attribute("vNormal")
	self:add_vertex_attribute("vTexCord")
	gl.use_program(self.program)

	-- enable z-test and face culling
	gl.enable("depth test")
	gl.enable("cull face")
	gl.cull_face("front")
	gl.front_face("cw")

	-- set background color
	gl.clear_color(0,0,0,0)

	random:seed()



	self.objects = {}

	self.cube_tileset = self:generate_cube_tileset(16,16, {
		[4] = {
			top = {tile_id = 1, vec2(1, 1), vec2(1, 0), vec2(0, 0), vec2(0, 1)},
			bottom = {tile_id = 3, vec2(1, 1), vec2(1, 0), vec2(0, 0), vec2(0, 1)},
		}
	})

	local white_cube_colors = {}
	local texture_cube_colors = {}
	for i=1, 36 do
		white_cube_colors[i] = vec4(1,1,1,1)
		texture_cube_colors[i] = vec4(1,1,1,0)
	end

	--local light_cube = self:new_cube(white_cube_colors)
	--table.insert(self.objects, light_cube)

	self.chunk_manager = chunk_manager(self.chunk_w, self.chunk_h, self.chunk_d)
	self.chunk_generator = chunk_generator(self.chunk_w, self.chunk_h, self.chunk_d)
	function self.chunk_manager.on_chunk_missing(_self, chunk_x, chunk_y, chunk_z)
		print("generating chunk", chunk_x, chunk_y, chunk_z)
		local chunk = self.chunk_generator(chunk_x, chunk_y, chunk_z)
		_self:add_chunk(chunk)
		return chunk
	end

	--local obj = self:new_test()
	--obj.model_matrix = glmath.translate(0,0.5,0)*glmath.scale(0.2)
	--table.insert(self.objects, obj)



	local d = 0
	for i=1, d do
		local cube = self:new_cube(white_cube_colors)
		cube.model_matrix = glmath.translate(i,0,0)
		table.insert(self.objects, cube)

		cube = self:new_cube(white_cube_colors)
		cube.model_matrix = glmath.translate(0,0,i)
		table.insert(self.objects, cube)

		cube = self:new_cube(white_cube_colors)
		cube.model_matrix = glmath.translate(-i,0,0)
		table.insert(self.objects, cube)

		cube = self:new_cube(white_cube_colors)
		cube.model_matrix = glmath.translate(0,-i,0)
		table.insert(self.objects, cube)

		cube = self:new_cube(white_cube_colors)
		cube.model_matrix = glmath.translate(0,0,-i)
		table.insert(self.objects, cube)
	end
	for y=1, d do
		for x=1, d do
			local cube = self:new_cube(texture_cube_colors, self.cube_tileset[4])
			cube.model_matrix = glmath.translate(x,(x-1)+(y-1)+0.1,y)
			table.insert(self.objects, cube)

			cube = self:new_cube(texture_cube_colors, self.cube_tileset[3])
			cube.model_matrix = glmath.translate(-x,0.1,y)
			table.insert(self.objects, cube)

			cube = self:new_cube(texture_cube_colors, self.cube_tileset[2])
			cube.model_matrix = glmath.translate(x,0.1,-y)
			table.insert(self.objects, cube)

			cube = self:new_cube(texture_cube_colors, self.cube_tileset[4])
			cube.model_matrix = glmath.translate(-x,0.1,-y)
			table.insert(self.objects, cube)
		end
	end
end


return game
