local vector = require "vector"

local ffi = require "ffi"

local floor = math.floor
local sin = math.sin
local cos = math.cos
local noise = love.math.noise
local TAU = math.pi*2

local size = 16384/8

function torusnoise(x,y, dens)
	local angle_x = TAU * x
	local angle_y = TAU * y
	return noise(
		cos(angle_x) / TAU* dens,
		sin(angle_x) / TAU* dens,
		cos(angle_y) / TAU* dens,
		sin(angle_y) / TAU* dens
	)
end

function pack(...)
	return { n = select("#", ...), ... }
end

local colormap = {}
local heightmap_2D = {}

local timer = 0
local frame = 0

function gen_light(x,y,z)
	local Sun = {x,y,z}
	shader_light:send("sun", Sun)
	test_cv:renderTo(function()
		love.graphics.setShader(shader_light)
			love.graphics.draw(gen_map_color_origin)
		love.graphics.setShader()
	end)

	gen_map_color_data = test_cv:newImageData()
	gen_map_color:replacePixels(gen_map_color_data, nil, 1)
	-- gen_map_color = love.graphics.newImage(gen_map_color_data)
	-- gem_map_color_ptr = ffi.cast("struct ImageData_Pixel_RGBA8 *", gen_map_color_data:getFFIPointer())
end


function gen_map(octa)
	local mul = 0.003
	local v_min = 1000
	local v_max = 0
	for x=0, size-1 do
		heightmap_2D[x+1] = {}
		-- colormap[x+1] = {}
		for y=0, size-1 do
			local v = 0
			local val = 1
			local max = 0
			for i=1, octa or 10 do
				-- print(val)
				max = max + val
				v = v + (val * torusnoise(x/size, y/size, 8/val))
				val = val * 0.5
			end
			v = v / max
			v = v*2
			v = math.max(v-0.60, 0)
			v = math.pow(v, 2)
			if v > v_max then v_max = v end
			if v < v_min then v_min = v end
			-- v = torusnoise(x/size, y/size)
			-- print(v)

			local water_level = 0.1
			local snow_level = 0.9

			v = math.max(v,water_level)
			-- heightmap_2D_1[x+1][y+1] = v*255

			if v <= water_level then -- water
				gen_map_color_origin_data:setPixel(x,y, noise(x*0.1,y*0.1)*0.3, noise(x*0.1,y*0.1)*0.1,1, 1)
			elseif v> snow_level then -- snow
				gen_map_color_origin_data:setPixel(x,y, 1,1,1, 1)
			elseif v>water_level and v < water_level+ 0.01 then -- beach
				gen_map_color_origin_data:setPixel(x,y, 1,0.91,0.79, 1)
			elseif v >0.5 and v < snow_level then -- rock
				gen_map_color_origin_data:setPixel(x,y, 0.5*v, 0.5*v, 0.5*v, 1)
			else
				gen_map_color_origin_data:setPixel(x,y, 0, 0.2+(v+noise(x*1,y*1)*0.02), 0, 1)
			end
			gen_map_height_data:setPixel(x,y,v,v,v,1)
			heightmap_2D[x+1][y+1] = v * 255
		end
	end
	print("min max", v_min, v_max)

	-- for x=350, 400 do
	-- 	for y=300, 350 do
	-- 		if (x>355 and x<395 and y > 305 and y < 345) then
	-- 			gen_map_color_origin_data:setPixel(x,y, 0.5, 0.5, 0.5, 1)
	-- 		else
	-- 			gen_map_color_origin_data:setPixel(x,y, 0.3, 0.3, 0.3, 1)
	-- 		end
	-- 		local tmp = heightmap_2D[x+1][y+1] / 255 + 50 / 255
	-- 		gen_map_height_data:setPixel(x,y,tmp,tmp,tmp,1)
	-- 		heightmap_2D[x+1][y+1] = heightmap_2D[x+1][y+1] + 50
	-- 	end
	-- end

	gen_map_color_origin = love.graphics.newImage(gen_map_color_origin_data)
	gen_map_height = love.graphics.newImage(gen_map_height_data)
	-- shader_light:send("map", gen_map_color_origin)
	shader_light:send("height_map", gen_map_height)
	shader_light:send("preci", 0.2)
	gen_light(0.5, 0.5, 1.4)

	-- function test( x, y, r, g, b, a )
	-- 	if not colormap[x+1] then colormap[x+1] = {} end
	-- 	colormap[x+1][y+1] = {r,g,b}
	-- 	return r,g,b,a
	-- end

	-- gen_map_color_data:mapPixel(test)
end

function love.load(arg)

	for k,v in pairs(love.graphics.getSystemLimits()) do
		print(k,v)
	end

	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	heightmap_data = love.image.newImageData("C1W_HEIGHT.png")
	colormap_data  = love.image.newImageData("C1W.png")
	map =  love.graphics.newImage(colormap_data)
	light_color = love.image.newImageData("light_color.png")

	gen_map_color_origin_data = love.image.newImageData(size,size)
	gen_map_height_data = love.image.newImageData(size,size)

	gen_map_color = love.graphics.newImage(gen_map_color_origin_data)

	print(gem_map_color_ptr)
	-- p.pointer[y * p.width + x]

	shader_light = love.graphics.newShader("light.glsl")

	test_cv = love.graphics.newCanvas(size,size)

	gen_map(8)

	-- for x=0, heightmap_data:getWidth()-1 do
	-- 	heightmap_2D[x+1] = {}
	-- 	for y=0,heightmap_data:getHeight()-1 do
	-- 		-- print(x,y)
	-- 		heightmap_2D[x+1][y+1] = heightmap_data:getPixel(x, y)*255
	-- 	end
	-- end

	-- for x=0, size-1 do
	-- 	-- heightmap_2D_1[x+1] = {}
	-- 	for y=0, size-1 do
	-- 		gen_map_data:setPixel(x,y, 0.5, 0.5, 0.5, 0)
	-- 	end
	-- end



	-- for i=1, 1000 do
	-- 	local x = math.random(10, 1000)
	-- 	local y = math.random(10, 1000)
	-- 	local h = heightmap_2D_1[x+1][y+1]
	-- 	for px=1,2 do
	-- 		for py=1,2 do
	-- 			print(x,y,px,py)
	-- 			heightmap_2D_1[x+px+1][y+py+1] = h + 0.5
	-- 			gen_map_data:setPixel(x+px,y+py, 1, 1, 0.7)
	-- 		end
	-- 	end
	-- end

	canvas = love.graphics.newCanvas(320*2, 240*2)
	canvas:setFilter("nearest", "nearest")

	pos = vector(512, 512)
	dir = vector(1,0)
	height = 250
	-- rot = 0
	dist = 550
	vx, vy = 120, 255
end

function render(p, phi, height, horizon, scale_height, distance, screen_width, screen_height)

	local sinphi = sin(phi)
	local cosphi = cos(phi)
	local x = p.x
	local y = p.y

	local rect = love.graphics.rectangle
	local color = love.graphics.setColor

	-- initialize visibility array. Y position for each column on screen
	local ybuffer = ffi.new("float[?]", screen_width+1)
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
			local x = floor(pleft_x)%size
			local y = floor(pleft_y)%size

			-- local h = gen_map_height_data:getPixel(x, y) * 255
			local h = heightmap_2D[x+1][y+1]
			local height_on_screen = floor((height - h) / z * scale_height + horizon)

			local y2 = ybuffer[i+1]
			if y2>0 and height_on_screen<y2 then
				color(gen_map_color_data:getPixel(x, y))

				-- local c= gem_map_color_ptr[y * size + x]
				-- color(c.r/255, c.g/255, c.b/255)

				-- color(colormap[x+1][y+1])

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
		render(pos, dir:toPolar().x, height, vx, vy, dist, 320, 240)
	end)

	love.graphics.setColor(1,1,1,1)
	love.graphics.setColor(light_color:getPixel(color, 1))
	love.graphics.draw(canvas,0,0,0,2,2)
	love.graphics.draw(gen_map_color,320*2,0,0,240*2/size,240*2/size)

	love.graphics.circle("fill", (pos.x%size)*240*2/size + 320*2, (pos.y%size)*240*2/size, 5, segments)
	love.graphics.print(love.timer.getFPS(), 200, 5)
	love.graphics.print(color.." "..math.sin(time)*16, 200, 30)
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
		gen_light(0.5+math.cos(time)*4, 0.5, math.sin(time)*8)
	end

	if love.keyboard.isDown("2") then
		time = math.pi/2
		gen_light((love.mouse.getX()-320*2)/(240*2), love.mouse.getY()/(240*2), 2)
	end

	if play_time then
		time = time + dt / 4
		gen_light(0.5+math.cos(time)*4, 0.5, math.sin(time)*8)
	end

	local sol = gen_map_height_data:getPixel(pos.x%size, pos.y%size)*255
	--
	if height < sol + 10 then
		height = sol + 10
	end

	-- require("lovebird").update()
end

local val = 1

function love.keypressed( key, scancode, isrepeat )
	print(key,scancode,isrepeat)


	if key == "3" then
		play_time = not play_time
	end

	if key == "5" then
		gen_map(floor(love.mouse.getX()/640*10)+1)
		print(floor(love.mouse.getX()/640*10)+1)
	end

	if key == "escape" or key == "c" then
		love.event.quit()
	end
end
