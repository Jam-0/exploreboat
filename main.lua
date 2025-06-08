local Camera = require("systems.render.camera")
local Renderer = require("systems.render.renderer")
local WorldGen = require("systems.world.worldgen")
local BoatPhysics = require("systems.boat.physics")
local BoatControls = require("systems.boat.controls")
local Market = require("systems.economy.market")
local HUD = require("systems.ui.hud")
local Map = require("systems.ui.map")
local MapScene = require("systems.ui.mapscene")

local game = {
    world = nil,
    player = nil,
    camera = nil,
    renderer = nil,
    boatPhysics = nil,
    boatControls = nil,
    markets = {},
    deltaTime = 0,
    time = 0,
    paused = false
}

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    math.randomseed(os.time())
    
    game.camera = Camera:new()
    game.renderer = Renderer:new()
    game.boatPhysics = BoatPhysics:new()
    game.boatControls = BoatControls:new()
    
    game.world = WorldGen:new({
        seed = math.random(1, 999999),
        chunkSize = 512
    })
    
    game.player = {
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        angle = 0,
        angularVelocity = 0,
        throttle = 0,
        rudderAngle = 0,
        mass = 1000,
        dragCoefficient = 0.2,
        money = 1000,
        cargo = {},
        maxCargo = 50,
        boatType = "sloop"
    }
    
    game.ui = {
        hud = HUD:new(),
        map = Map:new(),
        mapScene = MapScene:new()
    }
    
    game.world:generateInitialChunks(game.player.x, game.player.y)
end

function love.update(dt)
    if game.paused then return end
    
    -- Update map scene if active
    if game.ui.mapScene:isActive() then
        game.ui.mapScene:update(dt)
        return  -- Skip game updates when map is open
    end
    
    game.deltaTime = dt
    game.time = game.time + dt
    
    game.boatControls:update(game.player, dt)
    
    game.boatPhysics:update(game.player, dt, {
        wind = game.world:getWindAt(game.player.x, game.player.y),
        current = game.world:getCurrentAt(game.player.x, game.player.y),
        time = game.time,
        world = game.world
    })
    
    game.camera:follow(game.player.x, game.player.y, dt)
    
    game.world:updateChunks(game.player.x, game.player.y)
    
    for _, market in pairs(game.markets) do
        market:update(dt)
    end
    
    game.ui.hud:update(dt, game.player)
    game.ui.map:update(dt, game.player, game.world)
end

function love.draw()
    -- Draw map scene if active
    if game.ui.mapScene:isActive() then
        game.ui.mapScene:draw()
        return
    end
    
    -- Normal game drawing
    game.camera:apply()
    
    game.renderer:drawWorld(game.world, game.camera)
    
    game.renderer:drawBoat(game.player)
    
    game.camera:clear()
    
    game.ui.hud:draw(game.player)
    
    if game.ui.map.visible then
        game.ui.map:draw()
    end
end

function love.keypressed(key)
    -- Handle map scene input first
    if game.ui.mapScene:isActive() then
        if game.ui.mapScene:keypressed(key) then
            return  -- Map scene handled the key
        end
    end
    
    if key == "escape" then
        game.paused = not game.paused
    elseif key == "m" then
        if game.ui.mapScene:isActive() then
            game.ui.mapScene:deactivate()
        else
            game.ui.mapScene:activate(game.world, game.player)
        end
    elseif key == "tab" then
        -- Keep old small map for quick reference
        game.ui.map.visible = not game.ui.map.visible
    end
    
    -- Only handle boat controls if map scene is not active
    if not game.ui.mapScene:isActive() then
        game.boatControls:keypressed(key, game.player)
    end
end

function love.keyreleased(key)
    if not game.ui.mapScene:isActive() then
        game.boatControls:keyreleased(key, game.player)
    end
end

function love.mousepressed(x, y, button)
    if game.ui.mapScene:isActive() then
        game.ui.mapScene:mousepressed(x, y, button)
        return
    end
    
    game.ui.hud:mousepressed(x, y, button)
    if game.ui.map.visible then
        game.ui.map:mousepressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if game.ui.mapScene:isActive() then
        game.ui.mapScene:mousereleased(x, y, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    if game.ui.mapScene:isActive() then
        game.ui.mapScene:mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(x, y)
    if game.ui.mapScene:isActive() then
        game.ui.mapScene:wheelmoved(x, y)
    elseif game.ui.map.visible then
        game.ui.map:wheelmoved(x, y)
    end
end

function love.resize(w, h)
    game.camera:resize(w, h)
    game.ui.mapScene:resize(w, h)
end