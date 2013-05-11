function love.load()
	screen = {}
	screen.width = love.graphics.getWidth()
	screen.height = love.graphics.getHeight()
	screen.center = { x = screen.width / 2, y = screen.height / 2 }
	state = "splash"
	bestTime = 60.0
	loadImages()
	loadSounds()
	init()
end

function init()
	map = generateMap()
	player = createPlayer()
	paused = false
	win = false
	lose = false
	frames = 0
	timer = 0
	levelTimer = 0
	goalInterval = 4
	target = math.random(#map)
end

function loadImages()
	background = love.graphics.newImage("back.png")
	menu = love.graphics.newImage("menu.png")
	title = love.graphics.newImage("title.png")
	help = love.graphics.newImage("help.png")
	credits = love.graphics.newImage("credits.png")
	pause = love.graphics.newImage("pause.png")
	youwin = love.graphics.newImage("win.png")
	youlose = love.graphics.newImage("lose.png")
end

function loadSounds()
	beepBad = love.audio.newSource("beep-bad.wav", "stream")
	beepGood = love.audio.newSource("beep-good.wav", "stream")
end

function love.update(dt)
	if state ~= "game" or paused or win or lose then return end
	
	levelTimer = levelTimer + dt
	
	if target ~= 0 then
		goal = map[target]
		if not goal.empty and goal.x >= player.x and goal.y >= player.y and goal.x + goal.size <= player.x + player.size and goal.y + goal.size <= player.y + player.size then
			goal.empty = true
			if eat(goal) then
				love.audio.stop(beepGood)
				love.audio.play(beepGood)
				timer = goalInterval
				if full() then
					if levelTimer < bestTime then
						bestTime = math.floor(levelTimer * 10) / 10
					end
					win = true
				end
			else
				lose = true
			end
		end
	end
	
	for i, square in ipairs(map) do
		if square.empty and not square.eating then
			if square.x >= player.x and square.y >= player.y and square.x + square.size <= player.x + player.size and square.y + square.size <= player.y + player.size then
				for i, food in ipairs(player.stomach) do
					if player.x + (food.col - 1) * map.gridSize == square.x and player.x + (food.col) * map.gridSize == square.x + food.size 
						and player.y + (food.row - 1) * map.gridSize == square.y and player.y + (food.row) * map.gridSize == square.y + food.size then
						table.remove(player.stomach, i)
						love.audio.stop(beepBad)
						love.audio.play(beepBad)
						if (food.size == 40) then
							player.stomach.filled[(food.row - 1) * player.stomach.size + food.col] = false
						else
							player.stomach.filled[(food.row - 1) * player.stomach.size + food.col] = false
							player.stomach.filled[(food.row - 1) * player.stomach.size + food.col + 1] = false
							player.stomach.filled[(food.row) * player.stomach.size + food.col] = false
							player.stomach.filled[(food.row) * player.stomach.size + food.col + 1] = false
						end
					end
				end
			end
		end
	end
	
	timer = timer + dt
	frames = frames + 1
	player.timer = player.timer + dt
	
	if player.timer > 0.1 then
		player.timer = player.timer - 0.1
		if player.direction == 0 then
			player.x = player.x + map.gridSize / 2
		elseif player.direction == 1 then
			player.y = player.y - map.gridSize / 2
		elseif player.direction == 2 then
			player.x = player.x - map.gridSize / 2
		elseif player.direction == 3 then
			player.y = player.y + map.gridSize / 2
		end
	end
	
	if player.x < 0 then player.x = 0 end
	if player.x + player.size > screen.width then player.x = screen.width - player.size end
	if player.y < 0 then player.y = 0 end
	if player.y + player.size > screen.height then player.y = screen.height - player.size end
	
	if timer > goalInterval then
		timer = timer - goalInterval
		map[target].empty = true
		repeat
			target = math.random(#map)
		until map[target].empty == false
	end
end

function love.draw()
	if state == "splash" then
		drawSplash()
	elseif state == "menu" then
		drawMenu()
	elseif state == "help" then
		drawHelp()
	elseif state == "credits" then
		drawCredits()
	elseif state == "game" then
		drawGame()
	end
end

function drawSplash()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background, 0, 0)
	love.graphics.draw(title, 160, 160)
end

function drawMenu()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background, 0, 0)
	love.graphics.draw(menu, 160, 160)
	love.graphics.print("BEST TIME: " .. bestTime, 250, 165)
end

function drawHelp()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background, 0, 0)
	love.graphics.draw(help, 160, 160)
end

function drawCredits()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(background, 0, 0)
	love.graphics.draw(credits, 160, 160)
end

function drawGame()
	drawMap()
	drawPlayer()
	if paused then drawPause() end
	if lose then drawYouLose() end
	if win then drawYouWin() end
end

function drawPause()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(pause, 160, 160)
end

function drawYouLose()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(youlose, 160, 160)
end

function drawYouWin()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(youwin, 160, 160)
end

function full()
	for i = 1, #player.stomach.filled do
		if not player.stomach.filled[i] then
			return false
		end
	end
	return true
end

function love.keypressed(key)

	if paused and key ~= "p" then return end
	
	if state == "splash" then
		state = "menu"
	elseif state == "menu" and key == "q" then
		love.event.quit()
	elseif state == "menu" and key == "p" then
		state = "game"
		init()
	elseif state == "menu" and key == "h" then
		state = "help"
	elseif state == "menu" and key == "c" then
		state = "credits"
	elseif state == "help" then
		state = "menu"
	elseif state == "credits" then
		state = "menu"
	elseif state == "game" then
		if win or lose then
			state = "menu"
		elseif key == "q" then
			state = "menu"
		elseif key == "p" then
			paused = not paused
		elseif key == "right" then
			player.direction = 0
		elseif key == "up" then
			player.direction = 1
		elseif key == "left" then
			player.direction = 2
		elseif key == "down" then
			player.direction = 3
		end
	end
end

function eat(food)
	local canEat = false
	for r = 1, player.stomach.size - food.size/map.gridSize + 1 do
		for c = 1, player.stomach.size - food.size/map.gridSize + 1 do
			local start = (r-1) * player.stomach.size + c
			if not player.stomach.filled[start] then
				canEat = true
				for i = 1, food.size/map.gridSize do
					for j = 1, food.size/map.gridSize do
						if player.stomach.filled[start + (i - 1) * player.stomach.size + (j - 1)] then
							canEat = false
							break
						end
					end
					if not canEat then break end
				end
				if canEat then
					for i = 1, food.size/map.gridSize do
						for j = 1, food.size/map.gridSize do
							player.stomach.filled[start + (i - 1) * player.stomach.size + (j - 1)] = true
						end
					end
					food.row = r
					food.col = c
					table.insert(player.stomach, food)
					return true
				end
			end
		end
	end
	return false
end

function createPlayer()
	local player = {}
	player.size = 160
	player.x = screen.center.x - player.size / 2 
	player.y = screen.center.y - player.size / 2
	player.color = { red = 0, green = 0, blue = 0, alpha = 255 }
	player.style = "line"
	player.speedx = 500
	player.speedy = 500
	player.direction = -1
	player.timer = 0
	player.total = 0
	player.eaten = {}
	player.stomach = {}
	player.stomach.size = player.size/map.gridSize
	player.stomach.filled = {}
	for row = 1, player.stomach.size do
		for col = 1, player.stomach.size do
			player.stomach.filled[(row - 1) * player.stomach.size + col] = false
		end
	end

	return player
end

function generateMap()
	map = {}
	map.gridSize = 40
	map.rows = screen.height / map.gridSize
	map.cols = screen.width / map.gridSize
	used = {}
	for i = 1, (screen.width/map.gridSize) * (screen.height/map.gridSize) do
		used[i] = false
	end

	fill(map.gridSize * 2)
	fill()
	return map
end

function fill(size)
	if (size) then
		for i = 1, (screen.width / size) * (screen.height / size) / 3 do
			local square = {}
			square.style = "fill"
			square.size = size
			square.color = randomColor()
			square.empty = false
			square.eating = false
			repeat
				square.x = (math.random(screen.width / map.gridSize - (size/map.gridSize) + 1) - 1) * map.gridSize
				square.y = (math.random(screen.height / map.gridSize - (size/map.gridSize) + 1) - 1) * map.gridSize
			until take(square.x, square.y, square.size)
			table.insert(map, square)
		end
	else
		size = map.gridSize
		for i = 1, map.rows do
			for j = 1, map.cols do
				if not used[(i - 1) * map.cols + j] then
					used[(i - 1) * map.cols + j] = true
					local square = {}
					square.style = "fill"
					square.size = size
					square.color = randomColor()
					square.empty = false
					square.x = (j - 1) * map.gridSize
					square.y = (i - 1) * map.gridSize
					table.insert(map, square)
				end
			end
		end
	end
end

function take(x, y, size)
	local row = y / map.gridSize + 1
	local col = x / map.gridSize + 1
	local cells = size / map.gridSize
	
	free = true
	for i = row, row + cells - 1 do
		for j = col, col + cells - 1 do
			if used[(i - 1) * map.cols + j] then
				free = false
			end
		end
	end
	
	if free then
		for i = row, row + cells - 1 do
			for j = col, col + cells - 1 do
				used[(i - 1) * map.cols + j] = true
			end
		end
		return true
	else
		return false
	end
end

function generateMapOld()
	map = {}
	map.border = 10
	
	for i = 1, 100 do
		table.insert(map, randomSquare())
	end
	
	return map
end

function drawMap()
	for i, square in ipairs(map) do
		if not square.empty then
			love.graphics.setColor(square.color.red, square.color.green, square.color.blue, square.color.alpha)
			love.graphics.rectangle(square.style, square.x, square.y, square.size, square.size)
			love.graphics.setColor(255,255,255)
			love.graphics.rectangle("line", square.x, square.y, square.size, square.size)
			if i == target and frames % 50 > 25 then
				love.graphics.setColor(100, 100, 100)
				love.graphics.rectangle("fill", square.x, square.y, square.size, square.size)
				love.graphics.setColor(0,0,0)
				love.graphics.rectangle("line", square.x, square.y, square.size, square.size)
			end
		end
	end
end

function drawPlayer()
	for i, food in ipairs(player.stomach) do
		love.graphics.setColor(food.color.red, food.color.green, food.color.blue, 255)
		love.graphics.rectangle("fill", player.x + (food.col - 1) * map.gridSize, player.y + (food.row - 1) * map.gridSize, food.size/map.gridSize * map.gridSize, food.size/map.gridSize * map.gridSize)
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("line", player.x + (food.col - 1) * map.gridSize, player.y + (food.row - 1) * map.gridSize, food.size/map.gridSize * map.gridSize, food.size/map.gridSize * map.gridSize)
	end
	love.graphics.setColor(player.color.red, player.color.green, player.color.blue)
	for i = 0, 3 do
		love.graphics.rectangle("line", player.x + i, player.y + i, player.size - 2 * i, player.size - 2 * i)
	end
end

function randomSquare()
	local square = {}
	square.size = math.random(100)
	square.x = map.border + math.random(screen.width - square.size - 2 * map.border)
	square.y = map.border + math.random(screen.height - square.size - 2 * map.border)
	square.color = randomColor()
	square.style = "line"
	return square
end

function randomColor()
	local steps = 2
	local color = {}
	repeat
	color.red = (255 / steps) * (math.random(steps + 1) - 1)
	color.green = (255 / steps) * (math.random(steps + 1) - 1)
	color.blue = (255 / steps) * (math.random(steps+ 1) - 1)
	color.alpha = 255
	until not (color.red == 0 and color.green == 0 and color.blue == 0) and not (color.red == 255 and color.green == 255 and color.blue == 255)
	return color
end





































