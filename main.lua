vector = require "vector"
local ffi = require "ffi"

function drawVerticalLine(x, y, y2, color)
	if y2>0 and y <= y2 then
		-- print(x,y, y2, y2-y)
		love.graphics.setColor(color)
		love.graphics.rectangle("fill", x, y, 1, y2-y)
		-- love.graphics.line(x, y, x, y2)
	end
end

function pack(...)
	return { n = select("#", ...), ... }
end

local colormap = {}
local heightmap_1D = {}
local heightmap_2D = {}

local timer = 0
local frame = 0

function love.load(arg)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	heightmap_data = love.image.newImageData("C1W_HEIGHT.png")
	colormap_data  = love.image.newImageData("C1W.png")
	map =  love.graphics.newImage(colormap_data)

	for x=0, heightmap_data:getWidth()-1 do
		-- heightmap[x+1] = {}
		for y=0,heightmap_data:getHeight()-1 do
			-- print(x,y)
			heightmap_1D[x+1+y*heightmap_data:getHeight()] = heightmap_data:getPixel(x, y)*255
		end
	end

	for x=0, heightmap_data:getWidth()-1 do
		heightmap_2D[x+1] = {}
		for y=0,heightmap_data:getHeight()-1 do
			-- print(x,y)
			heightmap_2D[x+1][y+1] = heightmap_data:getPixel(x, y)*255
		end
	end


	-- for x=0, colormap_data:getWidth()-1 do
	-- 	colormap[x+1] = {}
	-- 	for y=0,colormap_data:getHeight()-1 do
	-- 		-- print(x,y)
	-- 		colormap[x+1][y+1] = pack(colormap_data:getPixel(x, y))
	-- 	end
	-- end

	canvas = love.graphics.newCanvas(320*2, 240*2)
	canvas:setFilter("nearest", "nearest")

	pos = vector(512, 512)
	dir = vector(1,0)
	height = 100
	-- rot = 0
	dist = 550
	vx, vy = 120, 300
	prec = 0.05
end

function render(p, phi, height, horizon, scale_height, distance, screen_width, screen_height)

	local floor = math.floor
	local sinphi = math.sin(phi)
	local cosphi = math.cos(phi)
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


	-- Draw from back to the front (high z coordinate to low z coordinate)
	while z < distance do
		-- print(z)
		-- Find line on map. This calculation corresponds to a field of view of 90°
		local pleft_x = -cosphi*z - sinphi*z + x
		local pleft_y =  sinphi*z - cosphi*z + y

		local pright_x =  cosphi*z - sinphi*z + p.x
		local pright_y = -sinphi*z - cosphi*z + p.y

		-- segment the line
		local dx = (pright_x - pleft_x) / screen_width
		local dy = (pright_y - pleft_y) / screen_width

		-- Raster line and draw a vertical line for each segment
		for i=0, screen_width-1 do
			local ybuff = screen_height
			local x = floor(pleft_x)%1024
			local y = floor(pleft_y)%1024
			-- print(x,y,i,ybuffer[i+1])
			local height_on_screen = floor((height - heightmap_2D[x+1][y+1]) / z * scale_height + horizon)

			local y2 = ybuffer[i+1]
			-- print(y2)
			if y2>0 and height_on_screen<y2 then
				color(colormap_data:getPixel(x, y+(1024*frame)))
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

function love.draw()
	canvas:renderTo(function()
		love.graphics.clear(56/255, 108/255, 193/255)
		render(pos, dir:toPolar().x, height, vx, vy, dist, 320*2, 240*2)
	end)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvas,0,0,0,1,1);
	love.graphics.draw(map,0,240*2,0,0.625,0.625)
	love.graphics.circle("fill", (pos.x%1024)*0.625, (pos.y%1024)*0.625 + 240*2, 5, segments)
	love.graphics.print(love.timer.getFPS(), 200, 5)
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

	local sol = heightmap_2D[math.floor(pos.x%1023)+1][math.floor(pos.y%1023)+1]

	if height < sol + 10 then
		height = sol + 10
	end

	-- require("lovebird").update()
end

function love.keypressed( key, scancode, isrepeat )
	print(key,scancode,isrepeat)
	if key == "escape" or key == "c" then
		love.event.quit()
	end
end
