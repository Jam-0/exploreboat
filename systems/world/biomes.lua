local Biomes = {}
Biomes.__index = Biomes

Biomes.types = {
    DEEP_OCEAN = {
        name = "Deep Ocean",
        color = {0.1, 0.2, 0.5, 1},
        minElevation = -1,
        maxElevation = -0.5
    },
    OCEAN = {
        name = "Ocean",
        color = {0.2, 0.3, 0.6, 1},
        minElevation = -0.5,
        maxElevation = -0.1
    },
    SHALLOW_WATER = {
        name = "Shallow Water",
        color = {0.3, 0.5, 0.7, 1},
        minElevation = -0.1,
        maxElevation = 0
    },
    BEACH = {
        name = "Beach",
        color = {0.9, 0.8, 0.6, 1},
        minElevation = 0,
        maxElevation = 0.05
    },
    GRASSLAND = {
        name = "Grassland",
        color = {0.3, 0.7, 0.3, 1},
        minElevation = 0.05,
        maxElevation = 0.3
    },
    FOREST = {
        name = "Forest",
        color = {0.2, 0.5, 0.2, 1},
        minElevation = 0.3,
        maxElevation = 0.6
    },
    MOUNTAIN = {
        name = "Mountain",
        color = {0.5, 0.4, 0.3, 1},
        minElevation = 0.6,
        maxElevation = 0.85
    },
    SNOW = {
        name = "Snow",
        color = {0.95, 0.95, 0.95, 1},
        minElevation = 0.85,
        maxElevation = 1
    }
}

function Biomes:getBiome(elevation, x, y)
    for biomeType, biome in pairs(self.types) do
        if elevation >= biome.minElevation and elevation <= biome.maxElevation then
            return biomeType
        end
    end
    
    return "OCEAN"
end

function Biomes:getBiomeData(biomeType)
    return self.types[biomeType] or self.types.OCEAN
end

function Biomes:getColor(biomeType)
    local biome = self:getBiomeData(biomeType)
    return biome.color
end

function Biomes:isWater(biomeType)
    return biomeType == "DEEP_OCEAN" or biomeType == "OCEAN" or biomeType == "SHALLOW_WATER"
end

function Biomes:isLand(biomeType)
    return not self:isWater(biomeType)
end

function Biomes:getResourceProbability(biomeType, resourceType)
    local probabilities = {
        DEEP_OCEAN = {fish = 0.6, whale = 0.3},
        OCEAN = {fish = 0.8, whale = 0.2},
        SHALLOW_WATER = {fish = 0.9, whale = 0.05},
        BEACH = {crab = 0.3, shells = 0.5},
        GRASSLAND = {grain = 0.7, livestock = 0.3},
        FOREST = {wood = 0.8, game = 0.4},
        MOUNTAIN = {iron = 0.6, stone = 0.8},
        SNOW = {fur = 0.4}
    }
    
    local biomeProbabilities = probabilities[biomeType] or {}
    return biomeProbabilities[resourceType] or 0
end

return Biomes