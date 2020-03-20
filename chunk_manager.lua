--luacheck: no max line length
local glmath = require("moonglmath")
local utils = require("utils")
local vec2 = utils.vec2
local vec3 = utils.vec3
local vec4 = utils.vec4
local mat4 = utils.mat4




local function new_chunk_manager(chunk_w, chunk_h, chunk_d, _cube_tileset)
	local chunk_manager = {}

	chunk_manager.chunk_w = assert(tonumber(chunk_w))
	chunk_manager.chunk_h = assert(tonumber(chunk_h))
	chunk_manager.chunk_d = assert(tonumber(chunk_d))
	chunk_manager.cube_tileset = _cube_tileset

	chunk_manager.chunks = {}


	local function get_index(chunk_x, chunk_y, chunk_z)
		return "chunk_" .. tostring(assert(tonumber(chunk_x))) .. "" .. tostring(assert(tonumber(chunk_y))) .. "" .. tostring(assert(tonumber(chunk_z)))
	end

	function chunk_manager:get_block(block_x, block_y, block_z)
		local chunk_x, chunk_y, chunk_z, local_x, local_y, local_z = self:block_pos_to_chunk_pos(block_x, block_y, block_z)
		local index = get_index(chunk_x, chunk_y, chunk_z)
		local chunk = self.chunks[index]
		if chunk then
			--local block_id = chunk:get_block(local_x, local_y, local_z)
			local block_id = chunk.data[local_z+1][local_y+1][local_x+1]
			return block_id
		end
	end

	function chunk_manager:set_block(block_x, block_y, block_z, block_id)
		local chunk_x, chunk_y, chunk_z, local_x, local_y, local_z = self:block_pos_to_chunk_pos(block_x, block_y, block_z)
		local index = get_index(chunk_x, chunk_y, chunk_z)
		local chunk = self.chunks[index]
		if chunk then
			--chunk:set_block(local_x, local_y, local_z, block_id)
			chunk.dirty = true
			chunk.data[local_z+1][local_y+1][local_x+1] = block_id
			return true
		end
	end

	function chunk_manager:get_chunk(chunk_x, chunk_y, chunk_z)
		local index = get_index(chunk_x, chunk_y, chunk_z)
		local chunk = self.chunks[index]
		if chunk then
			return chunk
		end
		if self.on_chunk_missing then
			return self:on_chunk_missing(chunk_x, chunk_y, chunk_z)
		end
	end

	function chunk_manager:add_chunk(chunk)
		local index = get_index(chunk.x, chunk.y, chunk.z)
		if not self.chunks[index] then
			self.chunks[index] = chunk
			chunk.dirty = true
			return true
		end
	end

	function chunk_manager:update_chunk(chunk)
		local index = get_index(chunk.x, chunk.y, chunk.z)
		if self.chunks[index] then
			self:remove_chunk(self.chunks[index])
			self.chunks[index] = chunk
			if chunk.object and chunk.dirty then
				self:update_chunk_object()
				chunk.dirty = false
			elseif not chunk.object then
				local vertexBuffer, colorBuffer, normalBuffer, textureBuffer = self:generate_chunk_buffer(chunk)
				local model_matrix = glmath.translate(chunk.x*self.chunk_w, chunk.y*self.chunk_h, chunk.z*self.chunk_d)
				chunk.object = self:new_static_object(vertexBuffer, colorBuffer, normalBuffer, textureBuffer, model_matrix)
			end
			return true
		end
	end

	function chunk_manager:remove_chunk(chunk)
		local index = get_index(chunk.x, chunk.y, chunk.z)
		if self.chunks[index] then
			self.chunks[index] = nil
			return true
		end
	end

	function chunk_manager:block_pos_to_chunk_pos(block_x, block_y, block_z)
		local chunk_x = math.floor(block_x / self.chunk_w)
		local chunk_y = math.floor(block_y / self.chunk_h)
		local chunk_z = math.floor(block_z / self.chunk_d)

		local local_x = block_x % self.chunk_w
		local local_y = block_y % self.chunk_h
		local local_z = block_z % self.chunk_d

		return chunk_x,chunk_y,chunk_z, local_x,local_y,local_z
	end



	function chunk_manager:generate_chunk_buffers(chunk)
		local chunk_data, cube_tileset = chunk.data, self.cube_tileset

		local cube_vertices  = {
			vec4( 0.5, 0.5, 0.5, 1), vec4(-0.5, 0.5, 0.5, 1), vec4(-0.5,-0.5, 0.5, 1), vec4( 0.5,-0.5, 0.5, 1), -- v0,v1,v2,v3 (front)
			vec4( 0.5, 0.5, 0.5, 1), vec4( 0.5,-0.5, 0.5, 1), vec4( 0.5,-0.5,-0.5, 1), vec4( 0.5, 0.5,-0.5, 1), -- v0,v3,v4,v5 (right)
			vec4( 0.5, 0.5, 0.5, 1), vec4( 0.5, 0.5,-0.5, 1), vec4(-0.5, 0.5,-0.5, 1), vec4(-0.5, 0.5, 0.5, 1), -- v0,v5,v6,v1 (top)
			vec4(-0.5, 0.5, 0.5, 1), vec4(-0.5, 0.5,-0.5, 1), vec4(-0.5,-0.5,-0.5, 1), vec4(-0.5,-0.5, 0.5, 1), -- v1,v6,v7,v2 (left)
			vec4(-0.5,-0.5,-0.5, 1), vec4( 0.5,-0.5,-0.5, 1), vec4( 0.5,-0.5, 0.5, 1), vec4(-0.5,-0.5, 0.5, 1), -- v7,v4,v3,v2 (bottom)
			vec4( 0.5,-0.5,-0.5, 1), vec4(-0.5,-0.5,-0.5, 1), vec4(-0.5, 0.5,-0.5, 1), vec4( 0.5, 0.5,-0.5, 1)  -- v4,v7,v6,v5 (back)
		};

		local cube_normals = {
			vec3( 0, 0, 1), vec3( 0, 0, 1), vec3( 0, 0, 1), vec3( 0, 0, 1),  -- v0,v1,v2,v3 (front)
			vec3( 1, 0, 0), vec3( 1, 0, 0), vec3( 1, 0, 0), vec3( 1, 0, 0),  -- v0,v3,v4,v5 (right)
			vec3( 0, 1, 0), vec3( 0, 1, 0), vec3( 0, 1, 0), vec3( 0, 1, 0),  -- v0,v5,v6,v1 (top)
			vec3(-1, 0, 0), vec3(-1, 0, 0), vec3(-1, 0, 0), vec3(-1, 0, 0),  -- v1,v6,v7,v2 (left)
			vec3( 0,-1, 0), vec3( 0,-1, 0), vec3( 0,-1, 0), vec3( 0,-1, 0),  -- v7,v4,v3,v2 (bottom)
			vec3( 0, 0,-1), vec3( 0, 0,-1), vec3( 0, 0,-1), vec3( 0, 0,-1)   -- v4,v7,v6,v5 (back)
		}

		local cube_colors = {
			vec4(1, 1, 1, 0), vec4(1, 1, 0, 0), vec4(1, 0, 0, 0), vec4(1, 0, 1, 0), -- v0,v1,v2,v3 (front)
			vec4(1, 1, 1, 0), vec4(1, 0, 1, 0), vec4(0, 0, 1, 0), vec4(0, 1, 1, 0), -- v0,v3,v4,v5 (right)
			vec4(1, 1, 1, 0), vec4(0, 1, 1, 0), vec4(0, 1, 0, 0), vec4(1, 1, 0, 0), -- v0,v5,v6,v1 (top)
			vec4(1, 1, 0, 0), vec4(0, 1, 0, 0), vec4(0, 0, 0, 0), vec4(1, 0, 0, 0), -- v1,v6,v7,v2 (left)
			vec4(0, 0, 0, 0), vec4(0, 0, 1, 0), vec4(1, 0, 1, 0), vec4(1, 0, 0, 0), -- v7,v4,v3,v2 (bottom)
			vec4(0, 0, 1, 0), vec4(0, 0, 0, 0), vec4(0, 1, 0, 0), vec4(0, 1, 1, 0)  -- v4,v7,v6,v5 (back)
		}

		local cube_face_indices = {
			front 	= { 1, 2, 3,   3, 4, 1}, -- v0-v1-v2, v2-v3-v0 (front)
			right 	= { 5, 6, 7,   7, 8, 5}, -- v0-v3-v4, v4-v5-v0 (right)
			top 	= { 9,10,11,  11,12, 9}, -- v0-v5-v6, v6-v1-v0 (top)
			left 	= {13,14,15,  15,16,13}, -- v1-v6-v7, v7-v2-v1 (left)
			bottom 	= {17,18,19,  19,20,17}, -- v7-v4-v3, v3-v2-v7 (bottom)
			back 	= {21,22,23,  23,24,21}  -- v4-v7-v6, v6-v5-v4 (back)
		}

		local function append_indices(inds, append, position, block_id)
			for i=1, #append do
				inds[#inds+1] = {
					index = append[i],
					position = position,
					block_id = block_id,
				}
			end
		end

		local function append_cube_faces(inds, front, right, top, left, bottom, back, position, block_id)
			if front then
				append_indices(inds, cube_face_indices.front, position, block_id)
			end
			if right then
				append_indices(inds, cube_face_indices.right, position, block_id)
			end
			if top then
				append_indices(inds, cube_face_indices.top, position, block_id)
			end
			if left then
				append_indices(inds, cube_face_indices.left, position, block_id)
			end
			if bottom then
				append_indices(inds, cube_face_indices.bottom, position, block_id)
			end
			if back then
				append_indices(inds, cube_face_indices.back, position, block_id)
			end
		end

		local function is_solid(x,y,z, ox,oy,oz)
			if (x+ox<1) or (y+oy<1) or (z+oz<1) or (x+ox>self.chunk_w) or (y+oy>self.chunk_h) or (z+oz>self.chunk_d) then
				return false
			end
			local center_block_id = chunk_data[z][y][x]
			local other_block_id = chunk_data[z+oz][y+oy][x+ox]
			if (other_block_id ~= 0) and (other_block_id ~= 224) then
				return true
			end
		end

		local indices = {}
		for z=1, self.chunk_d do
			for y=1, self.chunk_h do
				for x=1, self.chunk_w do
					local block_id = assert(chunk_data[z][y][x], ("blockid missing: %d %d %d"):format(x,y,z))
					if block_id ~= 0 then
						local left	 = not is_solid(x,y,z, -1, 0, 0)
						local bottom = not is_solid(x,y,z,  0,-1, 0)
						local back	 = not is_solid(x,y,z,  0, 0,-1)
						local right	 = not is_solid(x,y,z,  1, 0, 0)
						local top	 = not is_solid(x,y,z,  0, 1, 0)
						local front	 = not is_solid(x,y,z,  0, 0, 1)
						local position = vec3((x-1)-(self.chunk_w-1)*0.5, (y-1)-(self.chunk_h-1)*0.5, (z-1)-(self.chunk_d-1)*0.5)
						append_cube_faces(indices, front, right, top, left, bottom, back, position, block_id)
					end
				end
			end
		end

		local vertexBuffer, colorBuffer, normalBuffer, textureBuffer = {},{},{},{}
		for i=1, #indices do
			local index = indices[i]
			local cube_vertex = cube_vertices[index.index]
			cube_vertex = index.position + cube_vertex
			vertexBuffer[i] = cube_vertex
			colorBuffer[i] = cube_colors[index.index]
			normalBuffer[i] = cube_normals[index.index]
			local tex_cords = cube_tileset[index.block_id]
			textureBuffer[i] = tex_cords[index.index]
		end

		return vertexBuffer, colorBuffer, normalBuffer, textureBuffer
		--local model_matrix = glmath.translate(chunk.x*self.chunk_w, chunk.y*self.chunk_h, chunk.z*self.chunk_d)
		--local chunk_obj = self:new_static_object(vertexBuffer, colorBuffer, normalBuffer, textureBuffer, model_matrix)
		--return chunk_obj
	end




	return chunk_manager
end

return new_chunk_manager
