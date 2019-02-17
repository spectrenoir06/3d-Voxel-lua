vector = require "vector"


function drawVerticalLine(x, y, y2, color)
	if y <= y2 then
		love.graphics.setColor(color)
		love.graphics.line(x, y, x, y2)
	end
end



function love.load(arg)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	heightmap_data = love.image.newImageData("C1W_HEIGHT.png")
	colormap_data  = love.image.newImageData("C1W.png")
	map =  love.graphics.newImage(colormap_data)

	-- canvas = love.graphics.newCanvas( 800, 600 )

	heightmap = {}

	for x=0, heightmap_data:getWidth()-1 do
		heightmap[x+1] = {}
		for y=0,heightmap_data:getHeight()-1 do
			-- print(x,y)
			heightmap[x+1][y+1] = heightmap_data:getPixel(x, y)*255
		end
	end

	colormap = {}

	for x=0, colormap_data:getWidth()-1 do
		colormap[x+1] = {}
		for y=0,colormap_data:getHeight()-1 do
			-- print(x,y)
			colormap[x+1][y+1] = table.pack(colormap_data:getPixel(x, y))
		end
	end

	canvas = love.graphics.newCanvas(320, 240)
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
	local sinphi = math.sin(phi);
	local cosphi = math.cos(phi);

	-- initialize visibility array. Y position for each column on screen
	local ybuffer = {}
	for i=1,screen_width do
		-- print("buff:",i)
		ybuffer[i] = screen_height
	end

	local dz = 1.0
	local z = 1.0

	-- Draw from back to the front (high z coordinate to low z coordinate)
	while z < distance do
		-- print(z)

	-- for z=1,distance do
	-- for z=distance,1,-1 do
		-- Find line on map. This calculation corresponds to a field of view of 90°

		pleft =
		{
			(-cosphi*z - sinphi*z) + p.x,
			( sinphi*z - cosphi*z) + p.y
		}

		pright =
		{
			( cosphi*z - sinphi*z) + p.x,
			(-sinphi*z - cosphi*z) + p.y
		}

		-- segment the line
		local dx = (pright[1] - pleft[1]) / screen_width
		local dy = (pright[2] - pleft[2]) / screen_width

		-- Raster line and draw a vertical line for each segment
		for i=0, screen_width-1 do
			local x = floor(pleft[1]%1023)+1
			local y = floor(pleft[2]%1023)+1
			-- print(x,y,i,ybuffer[i+1])
			local height_on_screen = floor((height - heightmap[x][y]) / z * scale_height + horizon)
			-- print(z,i,height_on_screen)
			-- drawVerticalLine(i, height_on_screen, ybuffer[i+1], {z/200,0.01,0.01})
			drawVerticalLine(i+1, height_on_screen, ybuffer[i+1], colormap[x][y])
			-- drawVerticalLine(i, height_on_screen, 600, colormap[x][y])
			if height_on_screen < ybuffer[i+1] then
				ybuffer[i+1] = height_on_screen
			end
			pleft[1] = pleft[1] + dx
			pleft[2] = pleft[2] + dy
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
		render(pos, dir:toPolar().x, height, vx, vy, dist, 320, 240)
	end);
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(canvas,0,0,0,2,2);
	love.graphics.draw(map,320*2,0,0,0.625,0.625)
	love.graphics.circle("fill", (pos.x%1024)*0.625 + 640, (pos.y%1024)*0.625, 5, segments)
	love.graphics.print(love.timer.getFPS(), 200, 5)
end


function love.update(dt)
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


	local sol = heightmap[math.floor(pos.x%1023)+1][math.floor(pos.y%1023)+1]

	if height < sol + 10 then
		height = sol + 10
	end

	require("lovebird").update()
end

function love.keypressed( key, scancode, isrepeat )
	print(key,scancode,isrepeat)
	if key == "escape" or key == "c" then
		love.event.quit()
	end
end
