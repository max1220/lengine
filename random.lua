--luacheck: no max line length
local random = {}


-- initialize the seedbox to random values
function random:seed()
	local seedbox = {}
	for i=0, 255 do
		seedbox[i] = math.random()
	end
	self.seedbox = seedbox
end


-- return a random number for i
function random:noise_1d(i)
	local seed_index = math.floor(i)%255
	return self.seedbox[seed_index]
end


-- simple 1D continuous noise function
function random:continuous_noise_1d(f)
	local a,b = self:noise_1d(f), self:noise_1d(f+1)
	local p = f%1
	local v = (p*b)+((1-p)*a)
	return v
end


-- return a random number for x,y
function random:noise_2d(x,y)
	local seed_index = math.floor((x + y*15731)%255)
	return self.seedbox[seed_index]
end


-- simple 2D continuous noise function
function random:continuous_noise_2d(x,y)
	local xi,xf = math.floor(x), x%1
	local yi,yf = math.floor(y), y%1
	local n00 = self:noise_2d(xi,yi)
	local n01 = self:noise_2d(xi,yi+1)
	local n10 = self:noise_2d(xi+1,yi)
	local n11 = self:noise_2d(xi+1,yi+1)

	local nx = (n11*yf)+(n10*(1-yf))
	local ny = (n01*yf)+(n00*(1-yf))

	local v = (nx*xf)+(ny*(1-xf))

	return v
end


-- renders a graph of the 1D CNF to stdout
function random:test_1d(width, height)
	local min,max = math.huge, 0
	for i=0, height-1 do
		local v = self:continuous_noise_1d(i/10)
		min,max = math.min(min, v), math.max(max, v)
		print(("%5.2f: %5.2f   |"):format(i, v) .. (" "):rep(math.floor(v*width)).."#" .. (" "):rep(math.floor((1-v)*width)) .. "|")
	end
	print("1D CNF min:",min, "max:", max)
end


-- renders a graph of the 2D CNF to stdout
function random:test_2d(width, height)
	local min,max = math.huge, 0
	for y=0,height-1 do
		for x=0,width-1 do
			local v = self:continuous_noise_2d(x/10,y/10)
			min,max = math.min(min, v), math.max(max, v)
			if (v > 0.5) then
				io.write("#")
			else
				io.write(" ")
			end
		end
		io.write("\n")
	end
	print("2D CNF min:",min, "max:", max)
end

return random
