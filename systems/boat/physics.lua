local BoatPhysics = {}
BoatPhysics.__index = BoatPhysics

function BoatPhysics:new()
    local self = setmetatable({}, BoatPhysics)
    
    self.boatTypes = {
        sloop = {
            mass = 1000,
            dragCoefficient = 0.2,
            sailArea = 50,
            rudderEfficiency = 0.8,
            maxSpeed = 60,
            turnRate = 1.5
        },
        schooner = {
            mass = 2500,
            dragCoefficient = 0.25,
            sailArea = 120,
            rudderEfficiency = 0.7,
            maxSpeed = 50,
            turnRate = 1.0
        },
        galleon = {
            mass = 8000,
            dragCoefficient = 0.35,
            sailArea = 300,
            rudderEfficiency = 0.5,
            maxSpeed = 40,
            turnRate = 0.5
        }
    }
    
    return self
end

function BoatPhysics:update(boat, dt, environment)
    local boatType = self.boatTypes[boat.boatType] or self.boatTypes.sloop
    
    -- Apply thrust based on throttle
    if boat.throttle ~= 0 then
        local thrust = boat.throttle * boatType.maxSpeed * 10
        boat.vx = boat.vx + math.cos(boat.angle) * thrust * dt
        boat.vy = boat.vy + math.sin(boat.angle) * thrust * dt
    end
    
    -- Apply ocean current (much weaker)
    local currentForce = environment.current or {x = 0, y = 0}
    boat.vx = boat.vx + currentForce.x * 0.01 * dt
    boat.vy = boat.vy + currentForce.y * 0.01 * dt
    
    -- Apply drag (more drag when moving sideways)
    local forwardSpeed = boat.vx * math.cos(boat.angle) + boat.vy * math.sin(boat.angle)
    local sidewaysSpeed = -boat.vx * math.sin(boat.angle) + boat.vy * math.cos(boat.angle)
    
    -- Higher drag for sideways movement
    forwardSpeed = forwardSpeed * (1 - boatType.dragCoefficient * dt)
    sidewaysSpeed = sidewaysSpeed * (1 - boatType.dragCoefficient * 3 * dt)
    
    -- Convert back to world coordinates
    boat.vx = forwardSpeed * math.cos(boat.angle) - sidewaysSpeed * math.sin(boat.angle)
    boat.vy = forwardSpeed * math.sin(boat.angle) + sidewaysSpeed * math.cos(boat.angle)
    
    -- Limit max speed
    local speed = math.sqrt(boat.vx * boat.vx + boat.vy * boat.vy)
    if speed > boatType.maxSpeed then
        local scale = boatType.maxSpeed / speed
        boat.vx = boat.vx * scale
        boat.vy = boat.vy * scale
    end
    
    -- Update position with collision detection
    local newX = boat.x + boat.vx * dt
    local newY = boat.y + boat.vy * dt
    
    -- Check if new position would be on land
    if environment.world then
        local isWater = self:isPositionWater(newX, newY, environment.world)
        if isWater then
            boat.x = newX
            boat.y = newY
        else
            -- Stop the boat if it would hit land
            boat.vx = boat.vx * 0.3
            boat.vy = boat.vy * 0.3
            boat.throttle = 0
        end
    else
        boat.x = newX
        boat.y = newY
    end
    
    -- Wave bobbing effect (much subtler)
    local waveOffset = self:calculateWaveOffset(boat.x, boat.y, environment.time)
    boat.y = boat.y + waveOffset * 0.05
    
    -- Turn based on rudder, but only when moving
    local minSpeedForTurning = 2
    local turnEfficiency = math.min(1, speed / minSpeedForTurning)
    boat.angularVelocity = boat.rudderAngle * boatType.turnRate * turnEfficiency
    boat.angle = boat.angle + boat.angularVelocity * dt
    
    boat.angle = self:normalizeAngle(boat.angle)
end

function BoatPhysics:calculateWindForce(boat, wind, boatType)
    if not wind then return {x = 0, y = 0} end
    
    local apparentWindAngle = wind.direction - boat.sailAngle
    local sailEfficiency = math.cos(apparentWindAngle)
    
    if sailEfficiency < 0 then
        sailEfficiency = 0
    end
    
    local windForce = wind.strength * sailEfficiency * boatType.sailArea / 100
    
    return {
        x = math.cos(boat.angle) * windForce,
        y = math.sin(boat.angle) * windForce
    }
end

function BoatPhysics:calculateWaveOffset(x, y, time)
    local waveHeight = 2
    local waveFrequency = 0.5
    local waveSpeed = 2
    
    local offset = math.sin(x * 0.01 + time * waveSpeed) * 
                   math.cos(y * 0.01 + time * waveSpeed * 0.7) * 
                   waveHeight
    
    return offset
end

function BoatPhysics:normalizeAngle(angle)
    while angle > math.pi do
        angle = angle - 2 * math.pi
    end
    while angle < -math.pi do
        angle = angle + 2 * math.pi
    end
    return angle
end

function BoatPhysics:isPositionWater(x, y, world)
    local chunkX = math.floor(x / world.chunkSize)
    local chunkY = math.floor(y / world.chunkSize)
    local chunk = world:getOrGenerateChunk(chunkX, chunkY)
    
    if chunk then
        local localX = math.floor(x % world.chunkSize)
        local localY = math.floor(y % world.chunkSize)
        local tile = chunk:getTile(localX, localY)
        
        if tile then
            return tile.isWater
        end
    end
    
    -- Default to water if we can't determine
    return true
end

function BoatPhysics:getBoatTypeStats(boatType)
    return self.boatTypes[boatType] or self.boatTypes.sloop
end

return BoatPhysics