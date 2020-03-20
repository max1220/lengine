local random = require("random")

local function new_chunk_generator(_chunk_w, _chunk_h, _chunk_d)
	local function chunk_generator(chunk_x, chunk_y, chunk_z)
		local chunk_w, chunk_h, chunk_d = _chunk_w, _chunk_h, _chunk_d
		local _floor = math.floor
		local chunk = {
			x = chunk_x,
			y = chunk_y,
			z = chunk_z
		}
		local chunk_data = {}
		for z=1, chunk_d do
			local cplane = {}
			for y=1, chunk_h do
				local cline = {}
				for x=1, chunk_w do
					local block_x = (x-1)+(chunk_w*chunk_x)
					local block_z = (z-1)+(chunk_d*chunk_z)
					local h = _floor(random:continuous_noise_2d(block_x/10,block_z/10)*(chunk_h-1)+1)
					if y < h then
						cline[x] = 3
					elseif y == h then
						if (x==1) or (z==1) or (x==chunk_w) or (z==chunk_d) then
							cline[x] = 7
						else
							cline[x] = 4
						end
					elseif y < chunk_h*0.5 then
						cline[x] = 224
					else
						cline[x] = 0
					end
				end
				cplane[y] = cline
			end
			chunk_data[z] = cplane
		end
		chunk.data = chunk_data
		return chunk
	end
	return chunk_generator
end

return new_chunk_generator
