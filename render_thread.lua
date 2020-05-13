local vector = require "vector"
local ffi = require "ffi"
require "love.image"

local floor = math.floor
local sin = math.sin
local cos = math.cos
local max = math.max
local TAU = math.pi*2

local chunks = {}

local channel_tx, channel_rx, canvas_2_data, lx, ly, text_size, off = ...

print(channel_tx, channel_rx, canvas_2_data)
local canvas_2_data_ptr = ffi.cast("struct ImageData_Pixel_RGBA8 *", canvas_2_data:getFFIPointer())

function render(p, phi, height, horizon, scale_height, distance, render_width, render_height)
	-- print("render", render_width, off)
	local sinphi = sin(phi)
	local cosphi = cos(phi)
	local x = p.x
	local y = p.y

	-- local rect = love.graphics.rectangle
	-- local color = love.graphics.setColor

	-- initialize visibility array. Y position for each column on screen
	local ybuffer = {}--ffi.new("float[?]", render_width+1)
	for i=1,render_width do
		-- print("buff:",i)
		ybuffer[i] = render_height
	end


	local prec = 0.5

	-- Raster line and draw a vertical line for each segment
	for i=off, off + render_width-1 do
		local dz = 1.0
		local z = 1.0

		-- Draw from back to the front (high z coordinate to low z coordinate)
		while z < distance do
			-- print("z", z)
			-- Find line on map. This calculation corresponds to a field of view of 90°
			local cosphi_mul = cosphi*z
			local sinphi_mul = sinphi*z

			local pleft_x = -cosphi_mul - sinphi_mul + x
			local pleft_y =  sinphi_mul - cosphi_mul + y

			local pright_x =  cosphi_mul - sinphi_mul + x
			local pright_y = -sinphi_mul - cosphi_mul + y

			-- segment the line
			local dx = (pright_x - pleft_x) / lx
			local dy = (pright_y - pleft_y) / lx

			pleft_x = pleft_x + dx*i
			pleft_y = pleft_y + dy*i


			local chunk_x = floor(pleft_x/text_size)
			local chunk_y = floor(pleft_y/text_size)

			local chunk = chunks[chunk_x] and chunks[chunk_x][chunk_y]

			if chunk then
				local x = floor(pleft_x)%text_size
				local y = floor(pleft_y)%text_size
				-- print(chunk_x, chunk_y, x, y)
				-- print(pleft_x)

				local r,g,b,h = chunk.data:getPixel(x, y)
				local height_on_screen = max(floor((height - h*255) / z * scale_height + horizon), 0)
				height_on_screen = max(floor(height_on_screen), 0)

				local y2 = ybuffer[i+1-off]

				if y2>0 and height_on_screen<y2 then
					for j=height_on_screen, y2-1 do
						-- color(r,g,b)
						local pixel = canvas_2_data_ptr[j * lx + i]
						pixel.r = r*255+0.5
						pixel.g = g*255+0.5
						pixel.b = b*255+0.5
						pixel.a = 255
						-- canvas_2_data:setPixel(i, j, r, g, b)
					end
					-- color(r,g,b)
					-- rect("fill", i, height_on_screen, 1, y2-height_on_screen)
					ybuffer[i+1-off] = height_on_screen
				end
			end

			z = floor(z + dz)
			if z > 200 then
				dz = dz + 0.05
			end
		end
	end
end

while true do
	local data = channel_rx:peek()
	if data then
		-- print(data.type, off)
		if data.type == 1 then
			render(data.pos, data.dir, data.height, data.vx, data.vy, data.dist, data.lx, data.ly)
		else
			chunks = data.data
		end
		-- print("pop",data.type, off)
		channel_rx:pop()
	end
end
