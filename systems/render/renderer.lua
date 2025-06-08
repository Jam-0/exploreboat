local Biomes = require("systems.world.biomes")

local Renderer = {}
Renderer.__index = Renderer

function Renderer:new()
    local self = setmetatable({}, Renderer)
    
    self.tileSize = 32
    self.waterColor = {0.2, 0.3, 0.6, 1}
    self.waveAmplitude = 2
    self.waveFrequency = 0.1
    
    self.boatColors = {
        sloop = {0.8, 0.6, 0.4, 1},
        schooner = {0.7, 0.5, 0.3, 1},
        galleon = {0.6, 0.4, 0.2, 1}
    }
    
    -- Load boat image
    self.boatImage = love.graphics.newImage("boat1.png")
    self.boatWidth = self.boatImage:getWidth()
    self.boatHeight = self.boatImage:getHeight()
    
    -- Wake trail system - optimized circular buffer
    self.wakeTrails = {}
    self.maxWakePoints = 50  -- Reduced for performance
    self.wakeIndex = 1
    self.lastWakeTime = 0
    self.wakeInterval = 0.15  -- Slightly less frequent for performance
    
    -- Pre-allocate wake trail buffer to avoid garbage collection
    for i = 1, self.maxWakePoints do
        self.wakeTrails[i] = {x = 0, y = 0, alpha = 0, age = 0, width = 0, active = false}
    end
    
    self.drawCalls = 0
    self.debug = false
    
    return self
end

function Renderer:drawWorld(world, camera)
    self.drawCalls = 0
    
    self:drawOcean(camera)
    
    local visibleBounds = camera:getVisibleBounds()
    
    for _, chunk in ipairs(world:getActiveChunks()) do
        if self:isChunkVisible(chunk, visibleBounds) then
            self:drawChunk(chunk, world)
        end
    end
    
    for _, chunk in ipairs(world:getActiveChunks()) do
        if self:isChunkVisible(chunk, visibleBounds) then
            self:drawChunkFeatures(chunk)
        end
    end
end

function Renderer:drawOcean(camera)
    local bounds = camera:getVisibleBounds()
    local time = love.timer.getTime()
    
    love.graphics.setColor(self.waterColor)
    love.graphics.rectangle("fill", bounds.minX, bounds.minY, 
                           bounds.maxX - bounds.minX, bounds.maxY - bounds.minY)
    
    love.graphics.setColor(1, 1, 1, 0.1)
    local waveSpacing = 100
    for x = bounds.minX - (bounds.minX % waveSpacing), bounds.maxX, waveSpacing do
        for y = bounds.minY - (bounds.minY % waveSpacing), bounds.maxY, waveSpacing do
            local waveOffset = math.sin(x * 0.01 + time) * math.cos(y * 0.01 + time * 0.7) * self.waveAmplitude
            love.graphics.circle("fill", x + waveOffset, y + waveOffset, 20)
        end
    end
    
    self.drawCalls = self.drawCalls + 1
end

function Renderer:isChunkVisible(chunk, bounds)
    local chunkWorldX, chunkWorldY = chunk:getWorldPosition()
    return not (chunkWorldX + chunk.size < bounds.minX or
                chunkWorldX > bounds.maxX or
                chunkWorldY + chunk.size < bounds.minY or
                chunkWorldY > bounds.maxY)
end

function Renderer:drawChunk(chunk, world)
    local chunkWorldX, chunkWorldY = chunk:getWorldPosition()
    
    for x = 0, chunk.size - 1, self.tileSize do
        for y = 0, chunk.size - 1, self.tileSize do
            local tile = chunk:getTile(x, y)
            if tile and not tile.isWater then
                local biomeData = Biomes:getBiomeData(tile.biome)
                love.graphics.setColor(biomeData.color)
                love.graphics.rectangle("fill", 
                    chunkWorldX + x, chunkWorldY + y, 
                    self.tileSize, self.tileSize)
                self.drawCalls = self.drawCalls + 1
            end
        end
    end
end

function Renderer:drawChunkFeatures(chunk)
    for _, city in ipairs(chunk:getCities()) do
        self:drawCity(city)
    end
    
    for _, resource in ipairs(chunk:getResources()) do
        self:drawResource(resource)
    end
end

function Renderer:drawCity(city)
    love.graphics.setColor(0.8, 0.7, 0.6, 1)
    love.graphics.circle("fill", city.x, city.y, 20)
    
    love.graphics.setColor(0.6, 0.5, 0.4, 1)
    love.graphics.rectangle("fill", city.x - 15, city.y - 10, 10, 20)
    love.graphics.rectangle("fill", city.x - 5, city.y - 15, 15, 25)
    love.graphics.rectangle("fill", city.x + 5, city.y - 5, 10, 15)
    
    love.graphics.setColor(0.9, 0.8, 0.2, 1)
    love.graphics.polygon("fill", 
        city.x - 5, city.y - 15,
        city.x, city.y - 20,
        city.x + 5, city.y - 15
    )
    
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(city.name, city.x - 30, city.y + 25)
    
    self.drawCalls = self.drawCalls + 4
end

function Renderer:drawResource(resource)
    if resource.type == "fish" then
        love.graphics.setColor(0.5, 0.5, 0.8, 0.6)
        love.graphics.circle("fill", resource.x, resource.y, 15)
        love.graphics.setColor(0.7, 0.7, 1, 0.8)
        love.graphics.circle("line", resource.x, resource.y, 15)
    elseif resource.type == "whale" then
        love.graphics.setColor(0.3, 0.3, 0.5, 0.7)
        love.graphics.ellipse("fill", resource.x, resource.y, 25, 15)
        love.graphics.setColor(0.5, 0.5, 0.7, 0.9)
        love.graphics.ellipse("line", resource.x, resource.y, 25, 15)
    end
    
    self.drawCalls = self.drawCalls + 2
end

function Renderer:updateWakeTrail(boat)
    local speed = math.sqrt(boat.vx^2 + boat.vy^2)
    local currentTime = love.timer.getTime()
    local deltaTime = love.timer.getDelta()
    
    -- Add wake points using circular buffer (no memory allocation)
    if speed > 0.1 and (currentTime - self.lastWakeTime) >= self.wakeInterval then
        -- Calculate wake position behind the boat
        local wakeDistance = (self.boatHeight * 0.25) / 2
        local wakeX = boat.x - math.cos(boat.angle) * wakeDistance
        local wakeY = boat.y - math.sin(boat.angle) * wakeDistance
        
        -- Reuse existing wake point (circular buffer)
        local point = self.wakeTrails[self.wakeIndex]
        point.x = wakeX
        point.y = wakeY
        point.alpha = 1.0
        point.age = 0
        point.width = math.max(0.3, speed / 20)
        point.active = true
        
        -- Move to next index (circular)
        self.wakeIndex = (self.wakeIndex % self.maxWakePoints) + 1
        self.lastWakeTime = currentTime
    end
    
    -- Update all wake points (age them) - single loop, no table operations
    for i = 1, self.maxWakePoints do
        local point = self.wakeTrails[i]
        if point.active then
            point.age = point.age + deltaTime
            point.alpha = math.max(0, 1 - point.age / 4) -- Fade over 4 seconds
            
            if point.alpha <= 0 then
                point.active = false
            end
        end
    end
end

function Renderer:drawWakeTrail()
    love.graphics.setLineWidth(2)
    
    -- Draw wake trail - only active points
    for i = 1, self.maxWakePoints do
        local point = self.wakeTrails[i]
        if point.active and point.alpha > 0.1 then
            love.graphics.setColor(1, 1, 1, point.alpha * 0.3)
            love.graphics.circle("line", point.x, point.y, point.width * 3)
        end
    end
    
    love.graphics.setLineWidth(1)
end

function Renderer:drawBoat(boat)
    -- Update wake trail
    self:updateWakeTrail(boat)
    
    -- Draw wake trail first (behind boat)
    self:drawWakeTrail()
    
    love.graphics.push()
    love.graphics.translate(boat.x, boat.y)
    -- Rotate by angle + 90 degrees since the top of the image is the front
    love.graphics.rotate(boat.angle + math.pi/2)
    -- Scale down to 1/4 size
    love.graphics.scale(0.25, 0.25)
    
    -- Set color to white to display image normally
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw the boat image centered
    love.graphics.draw(self.boatImage, 
        -self.boatWidth/2, -self.boatHeight/2)
    
    love.graphics.pop()
    
    -- Draw immediate wake if moving (outside of scaled context)
    if boat.throttle > 0.1 then
        love.graphics.push()
        love.graphics.translate(boat.x, boat.y)
        love.graphics.rotate(boat.angle + math.pi/2)
        
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("line", 0, self.boatHeight/8 - 2, 3)
        love.graphics.circle("line", 0, self.boatHeight/8 + 1, 5)
        
        love.graphics.pop()
    end
    
    -- Draw rudder indicator if turned significantly (outside of scaled context)
    if math.abs(boat.rudderAngle) > 0.3 then
        love.graphics.push()
        love.graphics.translate(boat.x, boat.y)
        love.graphics.rotate(boat.angle + math.pi/2)
        
        love.graphics.setColor(1, 1, 0, 0.7)
        love.graphics.translate(0, self.boatHeight/8)
        love.graphics.rotate(boat.rudderAngle * 0.5)
        love.graphics.rectangle("fill", -1, 0, 2, 5)
        
        love.graphics.pop()
    end
    
    self.drawCalls = self.drawCalls + 1
end

function Renderer:drawEffects(effects)
    for _, effect in ipairs(effects) do
        if effect.type == "splash" then
            self:drawSplash(effect)
        elseif effect.type == "wake" then
            self:drawWake(effect)
        end
    end
end

function Renderer:drawSplash(splash)
    love.graphics.setColor(1, 1, 1, splash.alpha)
    love.graphics.circle("line", splash.x, splash.y, splash.radius)
    self.drawCalls = self.drawCalls + 1
end

function Renderer:drawWake(wake)
    love.graphics.setColor(1, 1, 1, wake.alpha * 0.3)
    love.graphics.circle("fill", wake.x, wake.y, wake.radius)
    self.drawCalls = self.drawCalls + 1
end

function Renderer:drawDebugInfo()
    if not self.debug then return end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Draw calls: " .. self.drawCalls, 10, 10)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 30)
end

function Renderer:toggleDebug()
    self.debug = not self.debug
end

return Renderer