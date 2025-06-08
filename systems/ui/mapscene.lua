local Biomes = require("systems.world.biomes")

local MapScene = {}
MapScene.__index = MapScene

function MapScene:new()
    local self = setmetatable({}, MapScene)
    
    self.active = false
    self.world = nil
    self.player = nil
    
    -- Map rendering settings
    self.scale = 0.5
    self.minScale = 0.1
    self.maxScale = 3.0
    self.offsetX = 0
    self.offsetY = 0
    
    -- Camera/view settings
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    -- Fog of war settings
    self.showAll = false  -- Toggle for testing
    self.exploredTiles = {}
    self.visibilityRadius = 2000
    
    -- Interaction
    self.dragging = false
    self.dragStart = {x = 0, y = 0, offsetX = 0, offsetY = 0}
    
    -- UI elements
    self.font = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(24)
    
    return self
end

function MapScene:activate(world, player)
    self.active = true
    self.world = world
    self.player = player
    
    -- Update screen dimensions
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    -- Center map on player
    self.offsetX = 0
    self.offsetY = 0
    
    -- Copy explored tiles from the game map
    local gameMap = require("systems.ui.map")
    if gameMap and gameMap.exploredTiles then
        self.exploredTiles = gameMap.exploredTiles
    end
end

function MapScene:deactivate()
    self.active = false
end

function MapScene:isActive()
    return self.active
end

function MapScene:update(dt)
    if not self.active then return end
    
    -- Update exploration if not showing all
    if not self.showAll then
        self:updateExploration()
    end
end

function MapScene:updateExploration()
    if not self.player then return end
    
    local tileSize = 100
    local startX = math.floor((self.player.x - self.visibilityRadius) / tileSize)
    local endX = math.floor((self.player.x + self.visibilityRadius) / tileSize)
    local startY = math.floor((self.player.y - self.visibilityRadius) / tileSize)
    local endY = math.floor((self.player.y + self.visibilityRadius) / tileSize)
    
    for x = startX, endX do
        for y = startY, endY do
            local worldX = x * tileSize
            local worldY = y * tileSize
            local distance = math.sqrt((worldX - self.player.x)^2 + (worldY - self.player.y)^2)
            
            if distance <= self.visibilityRadius then
                local key = x .. "," .. y
                self.exploredTiles[key] = true
            end
        end
    end
end

function MapScene:draw()
    if not self.active then return end
    
    -- Clear screen with dark background
    love.graphics.clear(0.1, 0.1, 0.2, 1)
    
    love.graphics.push()
    
    -- Apply map transformation
    love.graphics.translate(self.screenWidth / 2, self.screenHeight / 2)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-self.player.x - self.offsetX, -self.player.y - self.offsetY)
    
    -- Draw terrain
    self:drawTerrain()
    
    -- Draw cities
    self:drawCities()
    
    -- Draw player
    self:drawPlayer()
    
    love.graphics.pop()
    
    -- Draw UI overlay
    self:drawUI()
end

function MapScene:drawTerrain()
    if not self.world then return end
    
    local tileSize = 100
    local viewRadius = math.max(self.screenWidth, self.screenHeight) / self.scale + tileSize * 2
    
    local startX = math.floor((self.player.x + self.offsetX - viewRadius) / tileSize)
    local endX = math.floor((self.player.x + self.offsetX + viewRadius) / tileSize)
    local startY = math.floor((self.player.y + self.offsetY - viewRadius) / tileSize)
    local endY = math.floor((self.player.y + self.offsetY + viewRadius) / tileSize)
    
    for x = startX, endX do
        for y = startY, endY do
            local key = x .. "," .. y
            local shouldDraw = self.showAll or self.exploredTiles[key]
            
            if shouldDraw then
                local worldX = x * tileSize
                local worldY = y * tileSize
                
                -- Get chunk and tile data
                local chunkX = math.floor(worldX / self.world.chunkSize)
                local chunkY = math.floor(worldY / self.world.chunkSize)
                local chunk = self.world:getOrGenerateChunk(chunkX, chunkY)
                
                if chunk then
                    local localX = worldX % self.world.chunkSize
                    local localY = worldY % self.world.chunkSize
                    local tile = chunk:getTile(localX, localY)
                    
                    if tile then
                        local biomeData = Biomes:getBiomeData(tile.biome)
                        local color = biomeData.color
                        
                        -- Dim unexplored areas slightly if not showing all
                        if not self.showAll and not self.exploredTiles[key] then
                            love.graphics.setColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5, 0.8)
                        else
                            love.graphics.setColor(color)
                        end
                        
                        love.graphics.rectangle("fill", worldX, worldY, tileSize, tileSize)
                    end
                end
            end
        end
    end
end

function MapScene:drawCities()
    if not self.world then return end
    
    love.graphics.setColor(1, 0.8, 0.2, 1)
    
    for _, chunk in ipairs(self.world.activeChunks or {}) do
        for _, city in ipairs(chunk:getCities()) do
            local tileX = math.floor(city.x / 100)
            local tileY = math.floor(city.y / 100)
            local key = tileX .. "," .. tileY
            
            if self.showAll or self.exploredTiles[key] then
                -- Draw city icon
                local size = 15 / self.scale
                love.graphics.circle("fill", city.x, city.y, size)
                
                -- Draw city name
                love.graphics.push()
                love.graphics.scale(1 / self.scale, 1 / self.scale)
                love.graphics.setFont(self.font)
                love.graphics.print(city.name, city.x * self.scale + 20, city.y * self.scale - 8)
                love.graphics.pop()
            end
        end
    end
end

function MapScene:drawPlayer()
    if not self.player then return end
    
    love.graphics.setColor(1, 0.2, 0.2, 1)
    
    love.graphics.push()
    love.graphics.translate(self.player.x, self.player.y)
    love.graphics.rotate(self.player.angle)
    
    local size = 20 / self.scale
    love.graphics.polygon("fill",
        0, -size,
        -size/2, size,
        0, size/2,
        size/2, size
    )
    
    love.graphics.pop()
end

function MapScene:drawUI()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, self.screenWidth, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("World Map", 20, 10)
    
    -- Instructions
    love.graphics.setFont(self.font)
    love.graphics.print("ESC: Close | Mouse Wheel: Zoom | Drag: Pan | F: Toggle Fog", 20, self.screenHeight - 60)
    
    -- Show current mode
    local mode = self.showAll and "Show All: ON" or "Show All: OFF"
    love.graphics.print(mode, self.screenWidth - 150, 10)
    
    -- Coordinates
    local coords = string.format("Player: %.0f, %.0f", self.player.x or 0, self.player.y or 0)
    love.graphics.print(coords, self.screenWidth - 200, self.screenHeight - 40)
    
    -- Zoom level
    local zoom = string.format("Zoom: %.1fx", self.scale)
    love.graphics.print(zoom, self.screenWidth - 200, self.screenHeight - 60)
end

function MapScene:mousepressed(x, y, button)
    if not self.active then return end
    
    if button == 1 then
        self.dragging = true
        self.dragStart = {
            x = x, 
            y = y, 
            offsetX = self.offsetX, 
            offsetY = self.offsetY
        }
    end
end

function MapScene:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
end

function MapScene:mousemoved(x, y, dx, dy)
    if not self.active then return end
    
    if self.dragging and self.dragStart then
        self.offsetX = self.dragStart.offsetX + (x - self.dragStart.x) / self.scale
        self.offsetY = self.dragStart.offsetY + (y - self.dragStart.y) / self.scale
    end
end

function MapScene:wheelmoved(x, y)
    if not self.active then return end
    
    local oldScale = self.scale
    
    if y > 0 then
        self.scale = math.min(self.scale * 1.2, self.maxScale)
    elseif y < 0 then
        self.scale = math.max(self.scale / 1.2, self.minScale)
    end
end

function MapScene:keypressed(key)
    if not self.active then return end
    
    if key == "escape" then
        self:deactivate()
        return true
    elseif key == "f" then
        self.showAll = not self.showAll
        return true
    end
    
    return false
end

function MapScene:resize(w, h)
    self.screenWidth = w
    self.screenHeight = h
end

return MapScene