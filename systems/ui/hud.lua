local HUD = {}
HUD.__index = HUD

function HUD:new()
    local self = setmetatable({}, HUD)
    
    self.padding = 10
    self.fontSize = 16
    self.barHeight = 20
    self.barWidth = 200
    
    self.compassSize = 80
    self.windIndicatorSize = 60
    
    self.font = love.graphics.newFont(self.fontSize)
    
    return self
end

function HUD:update(dt, player)
    self.player = player
end

function HUD:draw(player)
    love.graphics.push()
    love.graphics.setFont(self.font)
    
    self:drawStats(player)
    self:drawCompass(player)
    self:drawThrottleIndicator(player)
    self:drawCargo(player)
    self:drawSpeedometer(player)
    
    love.graphics.pop()
end

function HUD:drawStats(player)
    local x = self.padding
    local y = self.padding
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x - 5, y - 5, 250, 80)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Money: $%d", player.money), x, y)
    
    y = y + 25
    love.graphics.print(string.format("Boat: %s", player.boatType:gsub("^%l", string.upper)), x, y)
    
    y = y + 25
    local usedCargo = 0
    for _, quantity in pairs(player.cargo) do
        usedCargo = usedCargo + quantity
    end
    love.graphics.print(string.format("Cargo: %d / %d", usedCargo, player.maxCargo), x, y)
end

function HUD:drawCompass(player)
    local screenWidth = love.graphics.getWidth()
    local x = screenWidth - self.compassSize - self.padding * 2
    local y = self.padding + self.compassSize / 2
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", x, y, self.compassSize / 2 + 5)
    
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("line", x, y, self.compassSize / 2)
    
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(-player.angle)
    
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.polygon("fill", 
        0, -self.compassSize / 2 + 10,
        -5, -self.compassSize / 2 + 20,
        5, -self.compassSize / 2 + 20
    )
    
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print("N", -5, -self.compassSize / 2 + 25)
    
    love.graphics.pop()
    
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.polygon("fill",
        0, -5,
        -10, 10,
        0, 5,
        10, 10
    )
    love.graphics.pop()
end

function HUD:drawThrottleIndicator(player)
    local screenWidth = love.graphics.getWidth()
    local x = screenWidth - self.windIndicatorSize - self.padding * 2
    local y = self.padding * 2 + self.compassSize + self.windIndicatorSize / 2
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.circle("fill", x, y, self.windIndicatorSize / 2 + 5)
    
    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)
    love.graphics.circle("line", x, y, self.windIndicatorSize / 2)
    
    -- Draw throttle indicator needle
    love.graphics.push()
    love.graphics.translate(x, y)
    
    -- Throttle ranges from -0.5 (reverse) to 1 (full forward)
    -- Map to angle from -90° to +90°
    local throttleAngle = player.throttle * math.pi / 2
    
    local needleLength = self.windIndicatorSize / 2 - 10
    
    -- Color based on throttle
    if player.throttle > 0 then
        love.graphics.setColor(0.2, 0.8, 0.2, 1) -- Green for forward
    elseif player.throttle < 0 then
        love.graphics.setColor(0.8, 0.2, 0.2, 1) -- Red for reverse
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Gray for neutral
    end
    
    love.graphics.setLineWidth(3)
    love.graphics.line(0, 0, 
        math.sin(throttleAngle) * needleLength,
        -math.cos(throttleAngle) * needleLength)
    love.graphics.setLineWidth(1)
    
    -- Center dot
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 0, 0, 3)
    
    love.graphics.pop()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("Throttle: %.1f", player.throttle), 
        x - self.windIndicatorSize, y + self.windIndicatorSize / 2 + 5, 
        self.windIndicatorSize * 2, "center")
end

function HUD:drawCargo(player)
    local x = self.padding
    local y = 120
    
    local cargoItems = 0
    for _ in pairs(player.cargo) do
        cargoItems = cargoItems + 1
    end
    
    if cargoItems > 0 then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", x - 5, y - 5, 250, 20 + cargoItems * 20)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Cargo:", x, y)
        y = y + 20
        
        for resource, quantity in pairs(player.cargo) do
            love.graphics.setColor(0.8, 0.8, 0.8, 1)
            love.graphics.print(string.format("  %s: %d", resource:gsub("^%l", string.upper), quantity), x, y)
            y = y + 20
        end
    end
end

function HUD:drawSpeedometer(player)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local x = screenWidth - 150 - self.padding
    local y = screenHeight - 60 - self.padding
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x - 5, y - 5, 150, 60)
    
    local speed = math.sqrt(player.vx^2 + player.vy^2)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Speed: %.1f kts", speed), x, y)
    
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", x, y + 25, 140, self.barHeight)
    
    local speedPercent = math.min(speed / 30, 1)
    local barColor = {0.2, 0.8, 0.2, 1}
    if speedPercent > 0.8 then
        barColor = {0.8, 0.8, 0.2, 1}
    elseif speedPercent > 0.95 then
        barColor = {0.8, 0.2, 0.2, 1}
    end
    
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", x, y + 25, 140 * speedPercent, self.barHeight)
end

function HUD:mousepressed(x, y, button)
end

return HUD