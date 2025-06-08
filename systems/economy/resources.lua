local Resources = {}
Resources.__index = Resources

Resources.types = {
    fish = {
        name = "Fish",
        category = "food",
        baseValue = 10,
        weight = 1,
        perishable = true,
        perishRate = 0.1,
        icon = "fish",
        description = "Fresh caught fish, a staple food source"
    },
    grain = {
        name = "Grain",
        category = "food",
        baseValue = 15,
        weight = 1,
        perishable = true,
        perishRate = 0.05,
        icon = "grain",
        description = "Wheat and other grains for bread and feed"
    },
    wood = {
        name = "Wood",
        category = "material",
        baseValue = 20,
        weight = 2,
        perishable = false,
        icon = "wood",
        description = "Timber for construction and fuel"
    },
    spices = {
        name = "Spices",
        category = "luxury",
        baseValue = 100,
        weight = 0.5,
        perishable = false,
        icon = "spices",
        description = "Exotic spices from distant lands"
    },
    silk = {
        name = "Silk",
        category = "luxury",
        baseValue = 150,
        weight = 0.3,
        perishable = false,
        icon = "silk",
        description = "Fine silk fabric, highly valued"
    },
    iron = {
        name = "Iron",
        category = "material",
        baseValue = 40,
        weight = 3,
        perishable = false,
        icon = "iron",
        description = "Raw iron for tools and weapons"
    },
    gems = {
        name = "Gems",
        category = "luxury",
        baseValue = 500,
        weight = 0.1,
        perishable = false,
        icon = "gems",
        description = "Precious stones and jewels"
    },
    whale_oil = {
        name = "Whale Oil",
        category = "special",
        baseValue = 200,
        weight = 2,
        perishable = false,
        icon = "oil",
        description = "Valuable oil from whaling"
    },
    maps = {
        name = "Maps",
        category = "special",
        baseValue = 300,
        weight = 0.1,
        perishable = false,
        icon = "map",
        description = "Nautical charts and exploration maps"
    },
    rum = {
        name = "Rum",
        category = "luxury",
        baseValue = 80,
        weight = 1.5,
        perishable = false,
        icon = "rum",
        description = "Popular alcoholic beverage"
    }
}

Resources.categories = {
    food = {
        name = "Food",
        priceVolatility = 0.3,
        demandMultiplier = 1.2
    },
    material = {
        name = "Materials",
        priceVolatility = 0.2,
        demandMultiplier = 1.0
    },
    luxury = {
        name = "Luxury Goods",
        priceVolatility = 0.5,
        demandMultiplier = 0.8
    },
    special = {
        name = "Special Items",
        priceVolatility = 0.6,
        demandMultiplier = 0.5
    }
}

function Resources:new()
    local self = setmetatable({}, Resources)
    return self
end

function Resources:getResourceData(resourceType)
    return self.types[resourceType]
end

function Resources:getCategoryData(category)
    return self.categories[category]
end

function Resources:getAllResources()
    local resourceList = {}
    for resourceType, data in pairs(self.types) do
        table.insert(resourceList, {
            id = resourceType,
            data = data
        })
    end
    return resourceList
end

function Resources:getResourcesByCategory(category)
    local filtered = {}
    for resourceType, data in pairs(self.types) do
        if data.category == category then
            table.insert(filtered, {
                id = resourceType,
                data = data
            })
        end
    end
    return filtered
end

function Resources:calculateCargoWeight(cargo)
    local totalWeight = 0
    for resourceType, quantity in pairs(cargo) do
        local resource = self:getResourceData(resourceType)
        if resource then
            totalWeight = totalWeight + (resource.weight * quantity)
        end
    end
    return totalWeight
end

function Resources:applyPerishables(cargo, deltaTime)
    local losses = {}
    
    for resourceType, quantity in pairs(cargo) do
        local resource = self:getResourceData(resourceType)
        if resource and resource.perishable then
            local loss = quantity * resource.perishRate * deltaTime
            if loss > 0.1 then
                losses[resourceType] = math.floor(loss)
                cargo[resourceType] = math.max(0, quantity - losses[resourceType])
                if cargo[resourceType] == 0 then
                    cargo[resourceType] = nil
                end
            end
        end
    end
    
    return losses
end

function Resources:getResourceValue(resourceType, quantity, priceMultiplier)
    local resource = self:getResourceData(resourceType)
    if not resource then
        return 0
    end
    
    priceMultiplier = priceMultiplier or 1.0
    return resource.baseValue * quantity * priceMultiplier
end

function Resources:canStack(resourceType)
    local resource = self:getResourceData(resourceType)
    return resource and resource.category ~= "special"
end

function Resources:getResourceColor(resourceType)
    local colors = {
        food = {0.8, 0.6, 0.3, 1},
        material = {0.5, 0.5, 0.5, 1},
        luxury = {0.8, 0.7, 0.9, 1},
        special = {0.9, 0.9, 0.3, 1}
    }
    
    local resource = self:getResourceData(resourceType)
    if resource then
        return colors[resource.category] or {1, 1, 1, 1}
    end
    return {1, 1, 1, 1}
end

return Resources