local Map = {}
Map.__index = Map

function Map:new()
    local self = setmetatable({}, Map)
    
    self.visible = false
    self.width = 600
    self.height = 400
    self.x = 0
    self.y = 0
    
    self.scale = 0.01
    self.minScale = 0.001
    self.maxScale = 0.1
    
    self.offsetX = 0
    self.offsetY = 0
    
    self.dragStart = nil
    self.isDragging = false
    
    self.exploredTiles = {}
    self.visibilityRadius = 2000
    
    return self
end

function Map:update(dt, player, world)
    self.player = player
    self.world = world
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    self.x = (screenWidth - self.width) / 2
    self.y = (screenHeight - self.height) / 2
    
    self:updateExploration(player.x, player.y)
end

function Map:updateExploration(playerX, playerY)
    local tileSize = 100
    local startX = math.floor((playerX - self.visibilityRadius) / tileSize)
    local endX = math.floor((playerX + self.visibilityRadius) / tileSize)
    local startY = math.floor((playerY - self.visibilityRadius) / tileSize)
    local endY = math.floor((playerY + self.visibilityRadius) / tileSize)
    
    for x = startX, endX do
        for y = startY, endY do
            local worldX = x * tileSize
            local worldY = y * tileSize
            local distance = math.sqrt((worldX - playerX)^2 + (worldY - playerY)^2)
            
            if distance <= self.visibilityRadius then
                local key = x .. "," .. y
                self.exploredTiles[key] = true
            end
        end
    end
end

function Map:draw()
    if not self.visible then return end
    
    love.graphics.push()
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", self.x - 10, self.y - 30, self.width + 20, self.height + 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Map", self.x + self.width / 2 - 20, self.y - 25)
    love.graphics.print("X to close", self.x + self.width - 80, self.y - 25)
    
    love.graphics.setScissor(self.x, self.y, self.width, self.height)
    
    love.graphics.translate(self.x + self.width / 2, self.y + self.height / 2)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.player.x - self.offsetX, -self.player.y - self.offsetY)
    
    self:drawTerrain()
    self:drawCities()
    self:drawPlayer()
    
    love.graphics.setScissor()
    love.graphics.pop()
    
    self:drawControls()
end

function Map:drawTerrain()
    local tileSize = 100
    local viewRadius = math.max(self.width, self.height) / self.scale / 2 + tileSize * 2
    
    local startX = math.floor((self.player.x + self.offsetX - viewRadius) / tileSize)
    local endX = math.floor((self.player.x + self.offsetX + viewRadius) / tileSize)
    local startY = math.floor((self.player.y + self.offsetY - viewRadius) / tileSize)
    local endY = math.floor((self.player.y + self.offsetY + viewRadius) / tileSize)
    
    for x = startX, endX do
        for y = startY, endY do
            local key = x .. "," .. y
            if self.exploredTiles[key] then
                local worldX = x * tileSize
                local worldY = y * tileSize
                
                local chunkX = math.floor(worldX / self.world.chunkSize)
                local chunkY = math.floor(worldY / self.world.chunkSize)
                local chunk = self.world:getOrGenerateChunk(chunkX, chunkY)
                
                if chunk then
                    local localX = worldX % self.world.chunkSize
                    local localY = worldY % self.world.chunkSize
                    local tile = chunk:getTile(localX, localY)
                    
                    if tile then
                        if tile.isWater then
                            love.graphics.setColor(0.2, 0.3, 0.6, 0.6)
                        else
                            love.graphics.setColor(0.3, 0.6, 0.3, 0.8)
                        end
                        
                        love.graphics.rectangle("fill", worldX, worldY, tileSize, tileSize)
                    end
                end
            end
        end
    end
end

function Map:drawCities()
    if not self.world then return end
    
    love.graphics.setColor(1, 0.8, 0.2, 1)
    
    for _, chunk in ipairs(self.world.activeChunks or {}) do
        for _, city in ipairs(chunk:getCities()) do
            local tileX = math.floor(city.x / 100)
            local tileY = math.floor(city.y / 100)
            local key = tileX .. "," .. tileY
            
            if self.exploredTiles[key] then
                love.graphics.circle("fill", city.x, city.y, 5 / self.scale)
                
                love.graphics.push()
                love.graphics.scale(1 / self.scale, 1 / self.scale)
                love.graphics.print(city.name, city.x * self.scale + 10, city.y * self.scale - 10)
                love.graphics.pop()
            end
        end
    end
end

function Map:drawPlayer()
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.push()
    love.graphics.translate(self.player.x, self.player.y)
    love.graphics.rotate(self.player.angle)
    
    local size = 10 / self.scale
    love.graphics.polygon("fill",
        0, -size,
        -size/2, size,
        0, size/2,
        size/2, size
    )
    
    love.graphics.pop()
end

function Map:drawControls()
    local controlsY = self.y + self.height + 5
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print("Mouse wheel: Zoom | Click and drag: Pan", self.x, controlsY)
end

function Map:mousepressed(x, y, button)
    if not self.visible then return end
    
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + self.height then
        if button == 1 then
            self.isDragging = true
            self.dragStart = {x = x, y = y, offsetX = self.offsetX, offsetY = self.offsetY}
        end
    end
end

function Map:mousereleased(x, y, button)
    if button == 1 then
        self.isDragging = false
        self.dragStart = nil
    end
end

function Map:mousemoved(x, y, dx, dy)
    if self.isDragging and self.dragStart then
        self.offsetX = self.dragStart.offsetX + (x - self.dragStart.x) / self.scale
        self.offsetY = self.dragStart.offsetY + (y - self.dragStart.y) / self.scale
    end
end

function Map:wheelmoved(x, y)
    if not self.visible then return end
    
    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()
    
    if mouseX >= self.x and mouseX <= self.x + self.width and
       mouseY >= self.y and mouseY <= self.y + self.height then
        local oldScale = self.scale
        
        if y > 0 then
            self.scale = math.min(self.scale * 1.2, self.maxScale)
        elseif y < 0 then
            self.scale = math.max(self.scale / 1.2, self.minScale)
        end
    end
end

return Map