local Chunk = {}
Chunk.__index = Chunk

function Chunk:new(x, y, size)
    local self = setmetatable({}, Chunk)
    
    self.x = x
    self.y = y
    self.size = size
    self.terrain = {}
    self.cities = {}
    self.resources = {}
    self.generated = false
    
    for i = 0, size - 1 do
        self.terrain[i] = {}
    end
    
    return self
end

function Chunk:setTile(x, y, tileData)
    if x >= 0 and x < self.size and y >= 0 and y < self.size then
        self.terrain[x][y] = tileData
    end
end

function Chunk:getTile(x, y)
    if x >= 0 and x < self.size and y >= 0 and y < self.size then
        return self.terrain[x][y]
    end
    return nil
end

function Chunk:addCity(city)
    table.insert(self.cities, city)
end

function Chunk:addResource(resource)
    table.insert(self.resources, resource)
end

function Chunk:getCities()
    return self.cities
end

function Chunk:getResources()
    return self.resources
end

function Chunk:getWorldPosition()
    return self.x * self.size, self.y * self.size
end

function Chunk:containsPoint(worldX, worldY)
    local chunkWorldX, chunkWorldY = self:getWorldPosition()
    return worldX >= chunkWorldX and worldX < chunkWorldX + self.size and
           worldY >= chunkWorldY and worldY < chunkWorldY + self.size
end

function Chunk:serialize()
    return {
        x = self.x,
        y = self.y,
        size = self.size,
        terrain = self.terrain,
        cities = self.cities,
        resources = self.resources,
        generated = self.generated
    }
end

function Chunk:deserialize(data)
    self.x = data.x
    self.y = data.y
    self.size = data.size
    self.terrain = data.terrain
    self.cities = data.cities
    self.resources = data.resources
    self.generated = data.generated
end

return Chunk