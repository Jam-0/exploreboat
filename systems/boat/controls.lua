local BoatControls = {}
BoatControls.__index = BoatControls

function BoatControls:new()
    local self = setmetatable({}, BoatControls)
    
    self.keys = {
        forward = "w",
        backward = "s",
        left = "a",
        right = "d",
        anchor = "space"
    }
    
    self.keysPressed = {}
    self.throttleSpeed = 2
    self.rudderSpeed = 1.5
    
    return self
end

function BoatControls:update(boat, dt)
    -- Handle steering (rudder)
    if self.keysPressed[self.keys.left] then
        boat.rudderAngle = math.max(-1, boat.rudderAngle - self.rudderSpeed * dt)
    elseif self.keysPressed[self.keys.right] then
        boat.rudderAngle = math.min(1, boat.rudderAngle + self.rudderSpeed * dt)
    else
        -- Return rudder to center when not steering
        boat.rudderAngle = boat.rudderAngle * (1 - dt * 3)
        if math.abs(boat.rudderAngle) < 0.05 then
            boat.rudderAngle = 0
        end
    end
    
    -- Handle throttle (forward/backward thrust)
    if self.keysPressed[self.keys.forward] then
        boat.throttle = math.min(1, boat.throttle + self.throttleSpeed * dt)
    elseif self.keysPressed[self.keys.backward] then
        boat.throttle = math.max(-0.5, boat.throttle - self.throttleSpeed * dt)
    else
        -- Return throttle to neutral when not accelerating
        boat.throttle = boat.throttle * (1 - dt * 4)
        if math.abs(boat.throttle) < 0.05 then
            boat.throttle = 0
        end
    end
    
    -- Anchor (emergency brake)
    if self.keysPressed[self.keys.anchor] then
        boat.vx = boat.vx * 0.9
        boat.vy = boat.vy * 0.9
        boat.throttle = 0
    end
end

function BoatControls:keypressed(key, boat)
    self.keysPressed[key] = true
end

function BoatControls:keyreleased(key, boat)
    self.keysPressed[key] = nil
end

function BoatControls:normalizeAngle(angle)
    while angle > math.pi do
        angle = angle - 2 * math.pi
    end
    while angle < -math.pi do
        angle = angle + 2 * math.pi
    end
    return angle
end

function BoatControls:getControlScheme()
    return self.keys
end

function BoatControls:setControlScheme(newKeys)
    for action, key in pairs(newKeys) do
        if self.keys[action] then
            self.keys[action] = key
        end
    end
end

return BoatControls