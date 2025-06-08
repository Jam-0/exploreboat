local Camera = {}
Camera.__index = Camera

function Camera:new()
    local self = setmetatable({}, Camera)
    
    self.x = 0
    self.y = 0
    self.scale = 1
    self.rotation = 0
    
    self.targetX = 0
    self.targetY = 0
    self.targetScale = 1
    
    self.smoothing = 5
    self.bounds = nil
    
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.shakeTime = 0
    
    return self
end

function Camera:follow(targetX, targetY, dt)
    self.targetX = targetX
    self.targetY = targetY
    
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    
    self.x = self.x + dx * self.smoothing * dt
    self.y = self.y + dy * self.smoothing * dt
    
    if self.bounds then
        self:constrainToBounds()
    end
    
    if self.shakeDuration > 0 then
        self:updateShake(dt)
    end
end

function Camera:setPosition(x, y)
    self.x = x
    self.y = y
    self.targetX = x
    self.targetY = y
end

function Camera:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
    self.targetX = self.x
    self.targetY = self.y
end

function Camera:zoom(factor)
    self.targetScale = self.targetScale * factor
    self.targetScale = math.max(0.1, math.min(5, self.targetScale))
end

function Camera:setZoom(scale)
    self.scale = scale
    self.targetScale = scale
end

function Camera:shake(intensity, duration)
    self.shakeIntensity = intensity
    self.shakeDuration = duration
    self.shakeTime = 0
end

function Camera:updateShake(dt)
    self.shakeTime = self.shakeTime + dt
    self.shakeDuration = self.shakeDuration - dt
    
    if self.shakeDuration <= 0 then
        self.shakeIntensity = 0
        self.shakeDuration = 0
    end
end

function Camera:apply()
    love.graphics.push()
    
    love.graphics.translate(self.screenWidth / 2, self.screenHeight / 2)
    
    if self.shakeDuration > 0 then
        local shakeX = (math.random() - 0.5) * self.shakeIntensity
        local shakeY = (math.random() - 0.5) * self.shakeIntensity
        love.graphics.translate(shakeX, shakeY)
    end
    
    love.graphics.scale(self.scale, self.scale)
    love.graphics.rotate(self.rotation)
    love.graphics.translate(-self.x, -self.y)
end

function Camera:clear()
    love.graphics.pop()
end

function Camera:setBounds(minX, minY, maxX, maxY)
    self.bounds = {
        minX = minX,
        minY = minY,
        maxX = maxX,
        maxY = maxY
    }
end

function Camera:constrainToBounds()
    if not self.bounds then return end
    
    local halfWidth = self.screenWidth / (2 * self.scale)
    local halfHeight = self.screenHeight / (2 * self.scale)
    
    self.x = math.max(self.bounds.minX + halfWidth, 
                      math.min(self.bounds.maxX - halfWidth, self.x))
    self.y = math.max(self.bounds.minY + halfHeight, 
                      math.min(self.bounds.maxY - halfHeight, self.y))
end

function Camera:worldToScreen(worldX, worldY)
    local screenX = (worldX - self.x) * self.scale + self.screenWidth / 2
    local screenY = (worldY - self.y) * self.scale + self.screenHeight / 2
    return screenX, screenY
end

function Camera:screenToWorld(screenX, screenY)
    local worldX = (screenX - self.screenWidth / 2) / self.scale + self.x
    local worldY = (screenY - self.screenHeight / 2) / self.scale + self.y
    return worldX, worldY
end

function Camera:getVisibleBounds()
    local halfWidth = self.screenWidth / (2 * self.scale)
    local halfHeight = self.screenHeight / (2 * self.scale)
    
    return {
        minX = self.x - halfWidth,
        minY = self.y - halfHeight,
        maxX = self.x + halfWidth,
        maxY = self.y + halfHeight
    }
end

function Camera:resize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Camera:getScale()
    return self.scale
end

function Camera:getPosition()
    return self.x, self.y
end

return Camera