local vector = require "vector"

local ffi = require "ffi"

local floor = math.floor
local sin = math.sin
local cos = math.cos
local noise = love.math.noise
local TAU = math.pi*2

local size = 1024

function torusnoise(x,y, dens)
	local angle_x = TAU * x
	local angle_y = TAU * y
	return noise(
		cos(angle_x) / TAU * dens,
		sin(angle_x) / TAU * dens,
		cos(angle_y) / TAU * dens,
		sin(angle_y) / TAU * dens
	)
end

function pack(...)
	return { n = select("#", ...), ... }
end

local colormap = {}
local heightmap_2D = {}

local timer = 0
local frame = 0

function shader_render(img, shader)
	test_cv:renderTo(function()
		love.graphics.clear(1,0,0,1)
		love.graphics.setShader(shader)
			love.graphics.setBlendMode("replace","premultiplied")
			love.graphics.draw(img,0,0)
		love.graphics.setShader()
	end)
	love.graphics.setBlendMode("alpha")

	return test_cv:newImageData()
end

function gen_light(img)
	shader_light:send("sun", sun)
	shader_light:send("preci", 0.01)

	local data = shader_render(img, shader_light)
	img:replacePixels(data, nil, 1)
	return data
end

function gen_map(x,y,dens)
	shader_gen:send("dens", dens or 1)
	shader_gen:send("off", {x,y})

	local data = shader_render(chunck_clear, shader_gen)
	local img = love.graphics.newImage(data)
	-- map:replacePixels(map_data, nil, 1)

	data = gen_light(img)
	return data, img
end


function love.load(arg)

	for k,v in pairs(love.graphics.getSystemLimits()) do
		print(k,v)
	end

	colormap_data  = love.image.newImageData("C1W.png") -- segfault if remove

	light_color = love.image.newImageData("light_color.png")
	biome_color = love.graphics.newImage("biome.png")



	map_data = love.image.newImageData(size, size)
	map = love.graphics.newImage(map_data)


	chunck_clear_data = love.image.newImageData(size, size)
	chunck_clear = love.graphics.newImage(map_data)


	shader_light = love.graphics.newShader("light.glsl")

	shader_gen = love.graphics.newShader("gen_map.glsl")
	shader_gen:send("biome", biome_color)

	test_cv = love.graphics.newCanvas(size, size)

	sun = {0.5, 0.5, 1,4}
	-- map_data, map = gen_map(0,0,1)

	chuncks= {}
	density = 1.0

	canvas = love.graphics.newCanvas(320*2, 240*2)
	canvas:setFilter("nearest", "nearest")

	pos = vector(0, 0)
	dir = vector(-1,-1)
	height = 250
	-- rot = 0
	dist = 800
	vx = 120
	vy = 255 / 1.0 / (1024 / size)

	sun = {0.5, 0.5, 1.4}
end

function render(p, phi, height, horizon, scale_height, distance, screen_width, screen_height)

	local sinphi = sin(phi)
	local cosphi = cos(phi)
	local x = p.x
	local y = p.y

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

	local prec = 0.01


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

			-- print(chunk_x, chunk_y, chuncks[x+1], chuncks[chunk_x+1] and chuncks[x+1][y+1])
			if not chuncks[chunk_x] or not chuncks[chunk_x][chunk_y] then
				local data, img = gen_map(chunk_x, chunk_y, density)
				if not chuncks[chunk_x] then chuncks[chunk_x] = {} end
				chuncks[chunk_x][chunk_y] = {
					data = data,
					img = img
				}
			end

			local data = chuncks[chunk_x][chunk_y].data
			local x = floor(pleft_x)%size
			local y = floor(pleft_y)%size
			-- print(chunk_x, chunk_y, x, y)
			-- print(pleft_x)

			local r,g,b,h = data:getPixel(x, y)
			-- h = h - z*0.008
			local height_on_screen = floor((height - h*255) / z * scale_height + horizon)

			local y2 = ybuffer[i+1]
			if y2>0 and height_on_screen<y2 then
				-- print(r,g,b)
				color(r,g,b)

				-- local c= gem_map_color_ptr[y * size + x]
				-- color(c.r/255, c.g/255, c.b/255)

				-- color(colormap[x+1][y+1])
				-- print(height_on_screen)
				rect("fill", i, height_on_screen, 1, y2-height_on_screen)
				ybuffer[i+1] = height_on_screen
			end

			pleft_x = pleft_x + dx
			pleft_y = pleft_y + dy
		end
		z = z + dz
		if z > 200 then
			dz = dz + prec
		end
	end
end


local time = math.pi/2

function love.draw()
	-- time = math.math.pi
	local color = (math.sin(time)*16)%64
	canvas:renderTo(function()
		love.graphics.clear(light_color:getPixel(color ,0))
		render(pos/density, dir:toPolar().x, height, vx, vy, dist, 320, 240)
	end)

	love.graphics.setColor(1,1,1,1)
	love.graphics.setColor(light_color:getPixel(color, 1))
	love.graphics.draw(canvas,0,0,0,2,2)

	-- love.graphics.setBlendMode("replace","premultiplied")
	-- for x=1,2 do
	-- 	for y=1,10 do
	-- 		love.graphics.draw(chuncks[x][y].img,320*2+size*(x-1),size*(y-1),0,1,1)
	-- 	end
	-- end
	-- love.graphics.setBlendMode("alpha")

	love.graphics.circle("fill", (pos.x%size)*240*2/size + 320*2, (pos.y%size)*240*2/size, 5, segments)
	love.graphics.print(love.timer.getFPS(), 10, 10)
	love.graphics.print(density, 200, 30)
end

function love.update(dt)
	timer = timer + dt
	if timer > 0.250 then
		frame = (frame + 1)%4
		timer = 0
	end
	if love.keyboard.isDown("space") then height = height + (dt * 100) end
	if love.keyboard.isDown("lshift") then height = height - (dt * 100) end

	if love.keyboard.isDown("w") then pos = pos - (dir * dt * 100) end
	if love.keyboard.isDown("s") then pos = pos + (dir * dt * 100) end
	if love.keyboard.isDown("a") then pos = pos + (dir:perpendicular() * dt * 100) end
	if love.keyboard.isDown("d") then pos = pos - (dir:perpendicular() * dt * 100) end

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
		time = love.mouse.getX()/640*math.pi*2
		sun = {0.5+math.cos(time)*4, 0.5, math.sin(time)*8}
		chuncks={}
	end

	if love.keyboard.isDown("2") then
		time = math.pi/2
		sun = {(love.mouse.getX()-320*2)/(240*2), love.mouse.getY()/(240*2), 2}
		chuncks={}
	end

	if  love.keyboard.isDown("6") then
		density = love.mouse.getX()/640*10
		chuncks={}
		vy = 255 / density / (1024 / size)
		pos = pos * 0
	end

	if play_time then
		time = time + dt / 4
		sun = {0.5+math.cos(time)*4, 0.5, math.sin(time)*8}
		-- map_data, map = gen_map(0,0,dens)
	end

	local chunk_x = floor(pos.x/size)
	local chunk_y = floor(pos.y/size)

	-- print(chunk_x, chunk_y, chuncks[x+1], chuncks[chunk_x+1] and chuncks[x+1][y+1])
	if not chuncks[chunk_x] or not chuncks[chunk_x][chunk_y] then
		local data, img = gen_map(chunk_x, chunk_y, density)
		if not chuncks[chunk_x] then chuncks[chunk_x] = {} end
		chuncks[chunk_x][chunk_y] = {
			data = data,
			img = img
		}
	end

	local r,g,b,sol = chuncks[chunk_x][chunk_y].data:getPixel(pos.x/density%size, pos.y/density%size)
	--
	if height < sol*255 + 10*density then
		height = sol*255 + 10*density
	end

	-- require("lovebird").update()
	-- print(pos)
end

 function love.wheelmoved(x, y)
	 if y~=0 then
 		density = density + 0.1*y
		if density < 0.1 then density = 0.1 end
 		chuncks={}
 		vy = 255 / density / (1024 / size)
 		-- pos = pos * 0
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
