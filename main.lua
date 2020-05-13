local vector = require "vector"

local ffi = require "ffi"

local floor = math.floor
local sin = math.sin
local cos = math.cos
local max = math.max
local noise = love.math.noise
local TAU = math.pi*2

local size = 512

local colormap = {}
local heightmap_2D = {}

local timer = 0
local frame = 0
local time = 0
local test_time = 42

function shader_render(img, shader)
	test_cv:renderTo(function()
		love.graphics.clear(1,0,0,1)
		love.graphics.setShader(shader)
			love.graphics.setBlendMode("replace", "premultiplied")
			love.graphics.draw(img,0,0)
		love.graphics.setShader()
	end)
	love.graphics.setBlendMode("alpha")

	return test_cv:newImageData()
end

function gen_light(img)
	shader_light:send("sun", sun)
	shader_light:send("preci", 0.001)

	local data = shader_render(img, shader_light)
	img:replacePixels(data, nil, 1)
	return data
end

function gen_map(x,y,dens)
	shader_gen:send("dens", dens or 1)
	shader_gen:send("off", {x,y})

	local data = shader_render(chunk_clear, shader_gen)
	local img = love.graphics.newImage(data)
	-- map:replacePixels(map_data, nil, 1)

	data = gen_light(img)
	return data, img
end


function love.load(arg)

	for k,v in pairs(love.graphics.getSystemLimits()) do
		print(k,v)
	end

	-- colormap_data  = love.image.newImageData("C1W.png") -- segfault if remove

	light_color = love.image.newImageData("light_color.png")
	biome_color = love.graphics.newImage("biome_3.png")



	map_data = love.image.newImageData(size, size)
	map = love.graphics.newImage(map_data)


	chunk_clear_data = love.image.newImageData(size, size)
	chunk_clear = love.graphics.newImage(map_data)


	-- shader_light = love.graphics.newShader("light.glsl")
	shader_light = love.graphics.newShader("light_inf.glsl")

	shader_water = love.graphics.newShader("water_simple.glsl")

	shader_gen = love.graphics.newShader("gen_map.glsl")
	shader_gen:send("biome", biome_color)

	test_cv = love.graphics.newCanvas(size, size)

	sun = {0.5, 0.0, 0.5}
	-- map_data, map = gen_map(0,0,1)

	chunks= {}
	density = 1.0

	minimap_size = 64

	lx, ly = 320, 240

	canvas = love.graphics.newCanvas(lx*1, ly)
	canvas:setFilter("nearest", "nearest")

	canvas_2_data = love.image.newImageData(lx, ly)
	canvas_2_data_ptr = ffi.cast("struct ImageData_Pixel_RGBA8 *", canvas_2_data:getFFIPointer())

	canvas_2_data_clear = love.image.newImageData(lx, ly)
	for x=0,lx-1 do
		for y=0,ly-1 do
			canvas_2_data_clear:setPixel(x,y, 0.329, 0.608, 0.922,1)
		end
	end

	-- for x=-2, 2 do
	-- 	for y=-2, 2 do
	-- 		local data, img = gen_map(x, y, density)
	-- 		if not chunks[x] then chunks[x] = {} end
	-- 			chunks[x][y] = {
	-- 			data = data,
	-- 			img = img
	-- 		}
	-- 	end
	-- end

	canvas_2 = love.graphics.newImage(canvas_2_data_clear)

	pos = vector(0, 0)
	dir = vector(-1,-1)
	height = 250
	-- rot = 0
	dist = 1500--800
	vx = 120
	vy = 255 / 1.0 / (1024 / size)

end

function render(p, phi, height, horizon, scale_height, distance, screen_width, screen_height)

	local sinphi = sin(phi)
	local cosphi = cos(phi)
	local x = p.x
	local y = p.y
	local lx = lx

	local rect = love.graphics.rectangle
	local color = love.graphics.setColor

	-- initialize visibility array. Y position for each column on screen
	local ybuffer = {}--ffi.new("float[?]", screen_width+1)
	for i=1,screen_width do
		-- print("buff:",i)
		ybuffer[i] = screen_height
	end

	local dz = 1.0
	local z = 1.0

	local prec = 0.5


	-- Draw from back to the front (high z coordinate to low z coordinate)
	while z < distance do
		-- print(z)
		-- Find line on map. This calculation corresponds to a field of view of 90°

		local cosphi_mul = cosphi*z
		local sinphi_mul = sinphi*z

		local pleft_x = -cosphi_mul - sinphi_mul + x
		local pleft_y =  sinphi_mul - cosphi_mul + y

		local pright_x =  cosphi_mul - sinphi_mul + x
		local pright_y = -sinphi_mul - cosphi_mul + y

		-- segment the line
		local dx = (pright_x - pleft_x) / screen_width
		local dy = (pright_y - pleft_y) / screen_width

		-- Raster line and draw a vertical line for each segment
		for i=0, screen_width-1 do
			local chunk_x = floor(pleft_x/size)
			local chunk_y = floor(pleft_y/size)

			-- print(chunk_x, chunk_y, chunks[x+1], chunks[chunk_x+1] and chunks[x+1][y+1])
			if not chunks[chunk_x] or not chunks[chunk_x][chunk_y] then
				local data, img = gen_map(chunk_x, chunk_y, density)
				if not chunks[chunk_x] then chunks[chunk_x] = {} end
				chunks[chunk_x][chunk_y] = {
					data = data,
					img = img
				}
			end

			local data = chunks[chunk_x][chunk_y].data
			local x = floor(pleft_x)%size
			local y = floor(pleft_y)%size
			-- print(chunk_x, chunk_y, x, y)
			-- print(pleft_x)

			local r,g,b,h = data:getPixel(x, y)
			local height_on_screen = max(floor((height - h*255) / z * scale_height + horizon), 0)
			-- print(height_on_screen)
			height_on_screen = max(floor(height_on_screen), 0)

			local y2 = ybuffer[i+1]
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
				ybuffer[i+1] = height_on_screen
			end

			pleft_x = pleft_x + dx
			pleft_y = pleft_y + dy
		end
		z = floor(z + dz)
		if z > 200 then
			dz = dz + 0.05
		end
	end
end


local time = math.pi/2

function love.draw()
	canvas_2_data:paste(canvas_2_data_clear,0,0,0,0)
	-- time = math.math.pi
	-- local color = (math.sin(time)*16)%64
	-- canvas:renderTo(function()
	-- 	love.graphics.clear(light_color:getPixel(color ,0))
	-- 	-- love.graphics.clear(1,0,1,1)
		render(pos/density, dir:toPolar().x, height, vx, vy, dist, lx, ly)
	-- end)

	love.graphics.setColor(1,1,1,1)
	-- love.graphics.setColor(light_color:getPixel(color, 1))

	-- shader_water:send("iTime", time)
	-- shader_water:send("iMouse", {love.mouse.getX()/320*2, love.mouse.getY()/240*2})
	-- shader_water:send("pos", {pos.x, pos.y})
	-- love.graphics.setShader(shader_water)

	canvas_2:replacePixels(canvas_2_data)
	love.graphics.draw(canvas_2,0,0,0,320*2/lx,240*2/ly)

	-- love.graphics.draw(canvas,0,0,0,2,2)
	-- love.graphics.setShader()


	love.graphics.setBlendMode("replace","premultiplied")
	for x=0,240*2/minimap_size do
		for y=0,240*2/minimap_size do
			if chunks[x] and chunks[x][y] then
				love.graphics.draw(
					chunks[x][y].img,
					320*2+minimap_size*x,
					minimap_size*y,
					0,
					minimap_size/size,
					minimap_size/size
				)
			end
		end
	end
	love.graphics.setBlendMode("alpha")

	love.graphics.circle("fill", pos.x/size*minimap_size/density + 320*2, pos.y/size*minimap_size/density, 5, segments)
	love.graphics.print(love.timer.getFPS(), 10, 10)
	love.graphics.print(density, 10, 30)
end

function love.update(dt)
	timer = timer + dt
	test_time = test_time + dt
	time = time + dt
	if timer > 0.250 then
		frame = (frame + 1)%4
		timer = 0
	end

	local speed = love.keyboard.isDown("lctrl") and 500 or 100

	if love.keyboard.isDown("space") then height = height + (dt * (speed)) end
	if love.keyboard.isDown("lshift") then height = height - (dt * (speed)) end

	if love.keyboard.isDown("w") then pos = pos - (dir * dt * (speed)) end
	if love.keyboard.isDown("s") then pos = pos + (dir * dt * (speed)) end
	if love.keyboard.isDown("a") then pos = pos + (dir:perpendicular() * dt * (speed)) end
	if love.keyboard.isDown("d") then pos = pos - (dir:perpendicular() * dt * (speed)) end

	if love.keyboard.isDown("q") then dir:rotateInplace(-dt * 1) end
	if love.keyboard.isDown("e") then dir:rotateInplace(dt * 1) end

	if love.keyboard.isDown("left")  then dir:rotateInplace(-dt * 1) end
	if love.keyboard.isDown("right") then dir:rotateInplace(dt * 1) end


	if love.keyboard.isDown("up")   then vx = vx + (320 * dt) end
	if love.keyboard.isDown("down") then vx = vx - (320 * dt) end

	if vx < -300 then vx = -300 end
	if vx > 300  then vx = 300 end

	if love.keyboard.isDown("r") then dist = dist + 1 end
	if love.keyboard.isDown("t") then dist = dist - 1 end

	if love.keyboard.isDown("h") then vy = vy + 1 end
	if love.keyboard.isDown("j") then vy = vy - 1 end

	if love.keyboard.isDown("1") then
		-- time = love.mouse.getX()/640*math.pi*2
		sun = {math.cos(time), 0.0, math.sin(time)}
		chunks={}
	end

	if love.keyboard.isDown("2") then
		-- time = math.pi/2
		sun = {(love.mouse.getX()-320*2)/(240*2), love.mouse.getY()/(240*2), 2}
		chunks={}
	end

	if  love.keyboard.isDown("6") then
		-- density = love.mouse.getX()/640*10
		chunks={}
		-- vy = 255 / density / (1024 / size)
	end

	if play_time then
		sun = {0.5+math.cos(time)*4, 0.5, math.sin(time)*8}
		-- map_data, map = gen_map(0,0,dens)
	end

	local chunk_x = floor(pos.x/density/size)
	local chunk_y = floor(pos.y/density/size)
	--
	-- print(chunk_x, chunk_y, chunks[x+1], chunks[chunk_x+1] and chunks[x+1][y+1])
	if not chunks[chunk_x] or not chunks[chunk_x][chunk_y] then
		local data, img = gen_map(chunk_x, chunk_y, density)
		if not chunks[chunk_x] then chunks[chunk_x] = {} end
		chunks[chunk_x][chunk_y] = {
			data = data,
			img = img
		}
	end
	--
	local r,g,b,sol = chunks[chunk_x][chunk_y].data:getPixel(pos.x/density%size, pos.y/density%size)
	-- --
	if height < sol*255 + 10 then
		height = sol*255 + 10
	end

	require("lovebird").update()
	-- print(pos)
end

 function love.wheelmoved(x, y)
	 if y~=0 then
 		density = density + 0.1*y
		if density < 0.1 then density = 0.1 end
 		chunks={}
 		vy = 255 / density / (1024 / size)
 	end
end

local val = 1

function love.keypressed( key, scancode, isrepeat )
	print(key,scancode,isrepeat)

	if key == "3" then
		play_time = not play_time
	end

	if key == "escape" or key == "c" then
		love.event.quit()
	end
end
