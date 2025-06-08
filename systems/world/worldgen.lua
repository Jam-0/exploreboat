local Chunk = require("systems.world.chunk")
local Biomes = require("systems.world.biomes")

local WorldGen = {}
WorldGen.__index = WorldGen

function WorldGen:new(config)
    local self = setmetatable({}, WorldGen)
    
    self.seed = config.seed or os.time()
    self.chunkSize = config.chunkSize or 512
    self.chunks = {}
    self.activeChunks = {}
    
    -- Minecraft-style configurable render distance
    self.renderDistance = config.renderDistance or 4  -- Can be adjusted for performance
    self.unloadDistance = self.renderDistance + 2     -- Unload chunks beyond this
    
    -- Chunk management
    self.lastPlayerChunkX = nil
    self.lastPlayerChunkY = nil
    self.chunksToGenerate = {}
    self.maxChunksPerFrame = 1  -- Generate max 1 chunk per frame to avoid stutters
    
    self.noiseScale = {
        continent = 0.001,
        island = 0.005,
        detail = 0.02
    }
    
    self.windDirection = math.random() * math.pi * 2
    self.windStrength = 20 + math.random() * 40
    
    math.randomseed(self.seed)
    
    return self
end

function WorldGen:generateInitialChunks(playerX, playerY)
    local chunkX = math.floor(playerX / self.chunkSize)
    local chunkY = math.floor(playerY / self.chunkSize)
    
    for dx = -1, 1 do
        for dy = -1, 1 do
            local x, y = chunkX + dx, chunkY + dy
            self:getOrGenerateChunk(x, y)
        end
    end
end

function WorldGen:getOrGenerateChunk(chunkX, chunkY)
    local key = chunkX .. "," .. chunkY
    
    if not self.chunks[key] then
        self.chunks[key] = self:generateChunk(chunkX, chunkY)
    end
    
    return self.chunks[key]
end

function WorldGen:generateChunk(chunkX, chunkY)
    local chunk = Chunk:new(chunkX, chunkY, self.chunkSize)
    
    for x = 0, self.chunkSize - 1 do
        for y = 0, self.chunkSize - 1 do
            local worldX = chunkX * self.chunkSize + x
            local worldY = chunkY * self.chunkSize + y
            
            local elevation = self:getElevation(worldX, worldY)
            local biome = Biomes:getBiome(elevation, worldX, worldY)
            
            chunk:setTile(x, y, {
                elevation = elevation,
                biome = biome,
                isWater = elevation < 0
            })
        end
    end
    
    self:generateCities(chunk)
    self:generateResources(chunk)
    
    chunk.generated = true
    return chunk
end

function WorldGen:getElevation(x, y)
    local continentNoise = self:noise(x * self.noiseScale.continent, y * self.noiseScale.continent, 0)
    local islandNoise = self:noise(x * self.noiseScale.island, y * self.noiseScale.island, 100)
    local detailNoise = self:noise(x * self.noiseScale.detail, y * self.noiseScale.detail, 200)
    
    local elevation = continentNoise * 0.7 + islandNoise * 0.2 + detailNoise * 0.1
    
    elevation = (elevation - 0.3) * 2
    
    -- Ensure water near spawn point (0, 0)
    local distanceFromSpawn = math.sqrt(x * x + y * y)
    if distanceFromSpawn < 1500 then
        local waterBlend = math.min(1, distanceFromSpawn / 1500)
        elevation = elevation * waterBlend - (1 - waterBlend) * 0.5
    end
    
    return math.max(-1, math.min(1, elevation))
end

function WorldGen:generateCities(chunk)
    local potentialSites = {}
    
    for x = 0, self.chunkSize - 1, 32 do
        for y = 0, self.chunkSize - 1, 32 do
            local tile = chunk:getTile(x, y)
            if tile and not tile.isWater then
                local hasCoast = false
                for dx = -16, 16, 4 do
                    for dy = -16, 16, 4 do
                        local nearbyTile = chunk:getTile(x + dx, y + dy)
                        if nearbyTile and nearbyTile.isWater then
                            hasCoast = true
                            break
                        end
                    end
                    if hasCoast then break end
                end
                
                if hasCoast then
                    table.insert(potentialSites, {x = x, y = y})
                end
            end
        end
    end
    
    if #potentialSites > 0 and math.random() < 0.3 then
        local site = potentialSites[math.random(#potentialSites)]
        chunk:addCity({
            x = chunk.x * self.chunkSize + site.x,
            y = chunk.y * self.chunkSize + site.y,
            name = self:generateCityName(),
            population = math.random(1000, 50000),
            type = "port"
        })
    end
end

function WorldGen:generateResources(chunk)
    for i = 1, math.random(0, 5) do
        local x = math.random(0, self.chunkSize - 1)
        local y = math.random(0, self.chunkSize - 1)
        local tile = chunk:getTile(x, y)
        
        if tile and tile.isWater then
            chunk:addResource({
                x = chunk.x * self.chunkSize + x,
                y = chunk.y * self.chunkSize + y,
                type = math.random() < 0.7 and "fish" or "whale",
                amount = math.random(10, 100)
            })
        end
    end
end

function WorldGen:generateCityName()
    local prefixes = {"Port", "Bay", "Cape", "Point", "Harbor"}
    local suffixes = {"haven", "mouth", "shore", "cove", "town"}
    return prefixes[math.random(#prefixes)] .. " " .. suffixes[math.random(#suffixes)]
end

function WorldGen:noise(x, y, z)
    return (math.sin(x + z) * math.cos(y + z) + 1) / 2
end

function WorldGen:updateChunks(playerX, playerY)
    local chunkX = math.floor(playerX / self.chunkSize)
    local chunkY = math.floor(playerY / self.chunkSize)
    
    -- Only update if player moved to a different chunk (like Minecraft)
    if self.lastPlayerChunkX ~= chunkX or self.lastPlayerChunkY ~= chunkY then
        self.lastPlayerChunkX = chunkX
        self.lastPlayerChunkY = chunkY
        
        -- Minecraft-style: Queue chunks for generation instead of generating immediately
        self:queueChunksForGeneration(chunkX, chunkY)
        
        -- Unload distant chunks (like Minecraft)
        self:unloadDistantChunks(chunkX, chunkY)
        
        -- Update active chunks list
        self:updateActiveChunksList(chunkX, chunkY)
    end
    
    -- Process chunk generation queue (max 1 per frame to prevent stutters)
    self:processChunkGeneration()
end

function WorldGen:queueChunksForGeneration(centerX, centerY)
    -- Queue chunks in spiral pattern (closest first, like Minecraft)
    for distance = 0, self.renderDistance do
        for dx = -distance, distance do
            for dy = -distance, distance do
                if math.abs(dx) == distance or math.abs(dy) == distance then
                    local x, y = centerX + dx, centerY + dy
                    local key = x .. "," .. y
                    
                    if not self.chunks[key] then
                        -- Add to generation queue if not already queued
                        local alreadyQueued = false
                        for _, queuedChunk in ipairs(self.chunksToGenerate) do
                            if queuedChunk.x == x and queuedChunk.y == y then
                                alreadyQueued = true
                                break
                            end
                        end
                        
                        if not alreadyQueued then
                            table.insert(self.chunksToGenerate, {x = x, y = y, priority = distance})
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by priority (closest chunks first)
    table.sort(self.chunksToGenerate, function(a, b) return a.priority < b.priority end)
end

function WorldGen:processChunkGeneration()
    local generated = 0
    while generated < self.maxChunksPerFrame and #self.chunksToGenerate > 0 do
        local chunkInfo = table.remove(self.chunksToGenerate, 1)
        local key = chunkInfo.x .. "," .. chunkInfo.y
        
        if not self.chunks[key] then
            self.chunks[key] = self:generateChunk(chunkInfo.x, chunkInfo.y)
            generated = generated + 1
        end
    end
end

function WorldGen:unloadDistantChunks(centerX, centerY)
    local chunksToRemove = {}
    
    for key, chunk in pairs(self.chunks) do
        local distance = math.max(math.abs(chunk.x - centerX), math.abs(chunk.y - centerY))
        if distance > self.unloadDistance then
            table.insert(chunksToRemove, key)
        end
    end
    
    -- Unload distant chunks to prevent memory growth
    for _, key in ipairs(chunksToRemove) do
        self.chunks[key] = nil
    end
end

function WorldGen:updateActiveChunksList(centerX, centerY)
    self.activeChunks = {}
    
    for dx = -self.renderDistance, self.renderDistance do
        for dy = -self.renderDistance, self.renderDistance do
            local x, y = centerX + dx, centerY + dy
            local key = x .. "," .. y
            local chunk = self.chunks[key]
            
            if chunk then
                table.insert(self.activeChunks, chunk)
            end
        end
    end
end

function WorldGen:getWindAt(x, y)
    local variation = math.sin(x * 0.0001 + self.seed) * 0.3
    return {
        direction = self.windDirection + variation,
        strength = self.windStrength * (0.8 + math.sin(y * 0.0001) * 0.2)
    }
end

function WorldGen:getCurrentAt(x, y)
    local angle = math.atan2(y, x) + self.seed * 0.1
    local strength = 2 + math.sin(angle * 3) * 1
    
    return {
        x = math.cos(angle) * strength,
        y = math.sin(angle) * strength
    }
end

function WorldGen:getActiveChunks()
    return self.activeChunks
end

return WorldGen