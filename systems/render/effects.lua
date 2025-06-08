local Effects = {}
Effects.__index = Effects

function Effects:new()
    local self = setmetatable({}, Effects)
    
    self.particles = {}
    self.maxParticles = 1000
    
    self.effects = {
        splash = {
            lifetime = 1.0,
            fadeSpeed = 1.0,
            growthRate = 50,
            color = {1, 1, 1, 0.8}
        },
        wake = {
            lifetime = 2.0,
            fadeSpeed = 0.5,
            growthRate = 10,
            color = {1, 1, 1, 0.3}
        },
        rain = {
            lifetime = 1.5,
            speed = 400,
            color = {0.7, 0.7, 0.8, 0.5}
        },
        snow = {
            lifetime = 3.0,
            speed = 100,
            color = {1, 1, 1, 0.8}
        },
        cannon = {
            lifetime = 0.5,
            speed = 300,
            color = {1, 0.8, 0.3, 1}
        }
    }
    
    self.weather = {
        type = "clear",
        intensity = 0,
        windEffect = 0
    }
    
    return self
end

function Effects:update(dt)
    for i = #self.particles, 1, -1 do
        local particle = self.particles[i]
        particle.lifetime = particle.lifetime - dt
        
        if particle.lifetime <= 0 then
            table.remove(self.particles, i)
        else
            self:updateParticle(particle, dt)
        end
    end
    
    self:updateWeather(dt)
end

function Effects:updateParticle(particle, dt)
    if particle.vx then
        particle.x = particle.x + particle.vx * dt
    end
    if particle.vy then
        particle.y = particle.y + particle.vy * dt
    end
    
    if particle.growthRate then
        particle.radius = particle.radius + particle.growthRate * dt
    end
    
    if particle.fadeSpeed then
        particle.alpha = particle.alpha - particle.fadeSpeed * dt
    end
    
    if particle.gravity then
        particle.vy = particle.vy + particle.gravity * dt
    end
end

function Effects:createSplash(x, y, size)
    if #self.particles >= self.maxParticles then return end
    
    local config = self.effects.splash
    
    table.insert(self.particles, {
        type = "splash",
        x = x,
        y = y,
        radius = size or 5,
        alpha = config.color[4],
        lifetime = config.lifetime,
        fadeSpeed = config.fadeSpeed,
        growthRate = config.growthRate,
        color = config.color
    })
    
    for i = 1, 5 do
        local angle = math.random() * math.pi * 2
        local speed = math.random(50, 150)
        self:createDroplet(x, y, angle, speed)
    end
end

function Effects:createDroplet(x, y, angle, speed)
    if #self.particles >= self.maxParticles then return end
    
    table.insert(self.particles, {
        type = "droplet",
        x = x,
        y = y,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed - 50,
        radius = 2,
        alpha = 0.8,
        lifetime = 0.5,
        fadeSpeed = 1.6,
        gravity = 300,
        color = {0.8, 0.8, 1, 0.8}
    })
end

function Effects:createWake(x, y, angle, speed)
    if #self.particles >= self.maxParticles then return end
    
    local config = self.effects.wake
    
    table.insert(self.particles, {
        type = "wake",
        x = x,
        y = y,
        radius = 3,
        alpha = config.color[4] * (speed / 30),
        lifetime = config.lifetime,
        fadeSpeed = config.fadeSpeed,
        growthRate = config.growthRate,
        color = config.color
    })
end

function Effects:createCannonSmoke(x, y, angle)
    if #self.particles >= self.maxParticles then return end
    
    for i = 1, 10 do
        local spread = (math.random() - 0.5) * 0.5
        local particleAngle = angle + spread
        local speed = math.random(100, 200)
        
        table.insert(self.particles, {
            type = "smoke",
            x = x,
            y = y,
            vx = math.cos(particleAngle) * speed,
            vy = math.sin(particleAngle) * speed,
            radius = math.random(5, 10),
            alpha = 0.7,
            lifetime = 1.0,
            fadeSpeed = 0.7,
            growthRate = 15,
            color = {0.5, 0.5, 0.5, 0.7}
        })
    end
end

function Effects:setWeather(weatherType, intensity)
    self.weather.type = weatherType
    self.weather.intensity = intensity or 0.5
end

function Effects:updateWeather(dt)
    if self.weather.type == "rain" then
        self:updateRain(dt)
    elseif self.weather.type == "snow" then
        self:updateSnow(dt)
    elseif self.weather.type == "storm" then
        self:updateStorm(dt)
    end
end

function Effects:updateRain(dt)
    local particlesToCreate = math.floor(self.weather.intensity * 10)
    
    for i = 1, particlesToCreate do
        if #self.particles < self.maxParticles then
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()
            
            table.insert(self.particles, {
                type = "rain",
                x = math.random(-100, screenWidth + 100),
                y = -10,
                vx = self.weather.windEffect * 50,
                vy = 400 + math.random(0, 200),
                width = 1,
                height = math.random(10, 20),
                alpha = 0.5,
                lifetime = 3.0,
                color = {0.7, 0.7, 0.8, 0.5}
            })
        end
    end
end

function Effects:updateSnow(dt)
    local particlesToCreate = math.floor(self.weather.intensity * 5)
    
    for i = 1, particlesToCreate do
        if #self.particles < self.maxParticles then
            local screenWidth = love.graphics.getWidth()
            
            table.insert(self.particles, {
                type = "snow",
                x = math.random(-100, screenWidth + 100),
                y = -10,
                vx = math.sin(love.timer.getTime() * 2 + i) * 20 + self.weather.windEffect * 30,
                vy = 50 + math.random(0, 50),
                radius = math.random(2, 4),
                alpha = 0.8,
                lifetime = 5.0,
                fadeSpeed = 0.2,
                color = {1, 1, 1, 0.8}
            })
        end
    end
end

function Effects:updateStorm(dt)
    self:updateRain(dt)
    
    if math.random() < 0.01 * self.weather.intensity then
        self:createLightning()
    end
end

function Effects:createLightning()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    local x = math.random(0, screenWidth)
    
    table.insert(self.particles, {
        type = "lightning",
        x = x,
        y = 0,
        endY = screenHeight * 0.7,
        width = math.random(2, 5),
        alpha = 1,
        lifetime = 0.2,
        fadeSpeed = 5,
        color = {1, 1, 0.9, 1}
    })
end

function Effects:draw()
    for _, particle in ipairs(self.particles) do
        self:drawParticle(particle)
    end
end

function Effects:drawParticle(particle)
    love.graphics.setColor(particle.color[1], particle.color[2], 
                          particle.color[3], particle.alpha)
    
    if particle.type == "splash" or particle.type == "wake" then
        love.graphics.circle("line", particle.x, particle.y, particle.radius)
    elseif particle.type == "droplet" or particle.type == "snow" then
        love.graphics.circle("fill", particle.x, particle.y, particle.radius)
    elseif particle.type == "smoke" then
        love.graphics.circle("fill", particle.x, particle.y, particle.radius)
    elseif particle.type == "rain" then
        love.graphics.line(particle.x, particle.y, 
                          particle.x + particle.vx * 0.1, 
                          particle.y + particle.height)
    elseif particle.type == "lightning" then
        love.graphics.setLineWidth(particle.width)
        local segments = 10
        local lastX = particle.x
        local lastY = particle.y
        
        for i = 1, segments do
            local nextY = particle.y + (particle.endY - particle.y) * (i / segments)
            local nextX = lastX + math.random(-20, 20)
            love.graphics.line(lastX, lastY, nextX, nextY)
            lastX = nextX
            lastY = nextY
        end
        love.graphics.setLineWidth(1)
    end
end

function Effects:clear()
    self.particles = {}
end

function Effects:getParticleCount()
    return #self.particles
end

return Effects