local Market = {}
Market.__index = Market

function Market:new(cityData)
    local self = setmetatable({}, Market)
    
    self.cityId = cityData.name or "Unknown Port"
    self.x = cityData.x
    self.y = cityData.y
    self.population = cityData.population or 5000
    
    self.resources = {}
    self.priceHistory = {}
    self.updateInterval = 30
    self.timeSinceUpdate = 0
    
    self:initializeMarket()
    
    return self
end

function Market:initializeMarket()
    local resourceTypes = {
        fish = {
            basePrice = 10,
            baseSupply = 100,
            baseDemand = 80,
            volatility = 0.3
        },
        grain = {
            basePrice = 15,
            baseSupply = 150,
            baseDemand = 120,
            volatility = 0.2
        },
        wood = {
            basePrice = 20,
            baseSupply = 80,
            baseDemand = 100,
            volatility = 0.15
        },
        spices = {
            basePrice = 100,
            baseSupply = 20,
            baseDemand = 30,
            volatility = 0.5
        },
        silk = {
            basePrice = 150,
            baseSupply = 10,
            baseDemand = 15,
            volatility = 0.4
        },
        iron = {
            basePrice = 40,
            baseSupply = 60,
            baseDemand = 70,
            volatility = 0.25
        },
        gems = {
            basePrice = 500,
            baseSupply = 5,
            baseDemand = 8,
            volatility = 0.6
        }
    }
    
    for resourceType, config in pairs(resourceTypes) do
        local supplyMultiplier = 0.5 + math.random() * 1.5
        local demandMultiplier = 0.5 + math.random() * 1.5
        
        self.resources[resourceType] = {
            supply = config.baseSupply * supplyMultiplier,
            demand = config.baseDemand * demandMultiplier,
            basePrice = config.basePrice,
            currentPrice = config.basePrice,
            volatility = config.volatility,
            trend = (math.random() - 0.5) * 0.1
        }
        
        self.priceHistory[resourceType] = {config.basePrice}
    end
end

function Market:update(dt)
    self.timeSinceUpdate = self.timeSinceUpdate + dt
    
    if self.timeSinceUpdate >= self.updateInterval then
        self.timeSinceUpdate = 0
        self:updatePrices()
        self:updateSupplyDemand()
    end
end

function Market:updatePrices()
    for resourceType, resource in pairs(self.resources) do
        local supplyDemandRatio = resource.supply / (resource.demand + 1)
        local priceMultiplier = 2 / (1 + supplyDemandRatio)
        
        local randomFactor = 1 + (math.random() - 0.5) * resource.volatility
        
        resource.trend = resource.trend * 0.9 + (math.random() - 0.5) * 0.1
        
        local newPrice = resource.basePrice * priceMultiplier * randomFactor * (1 + resource.trend)
        
        newPrice = math.max(resource.basePrice * 0.2, math.min(resource.basePrice * 5, newPrice))
        
        resource.currentPrice = resource.currentPrice * 0.7 + newPrice * 0.3
        
        table.insert(self.priceHistory[resourceType], resource.currentPrice)
        if #self.priceHistory[resourceType] > 20 then
            table.remove(self.priceHistory[resourceType], 1)
        end
    end
end

function Market:updateSupplyDemand()
    for resourceType, resource in pairs(self.resources) do
        local supplyChange = (math.random() - 0.5) * 20
        local demandChange = (math.random() - 0.5) * 15
        
        resource.supply = math.max(10, resource.supply + supplyChange)
        resource.demand = math.max(10, resource.demand + demandChange)
        
        local populationFactor = self.population / 10000
        resource.demand = resource.demand * (0.8 + 0.4 * populationFactor)
    end
end

function Market:buyResource(resourceType, quantity)
    local resource = self.resources[resourceType]
    if not resource then
        return false, "Resource not available"
    end
    
    if resource.supply < quantity then
        return false, "Not enough supply"
    end
    
    local totalCost = resource.currentPrice * quantity
    
    resource.supply = resource.supply - quantity
    resource.demand = resource.demand + quantity * 0.1
    
    self:immediateUpdatePrice(resourceType)
    
    return true, totalCost
end

function Market:sellResource(resourceType, quantity)
    local resource = self.resources[resourceType]
    if not resource then
        return false, "Market doesn't trade this resource"
    end
    
    local totalValue = resource.currentPrice * quantity * 0.9
    
    resource.supply = resource.supply + quantity
    resource.demand = resource.demand - quantity * 0.1
    
    self:immediateUpdatePrice(resourceType)
    
    return true, totalValue
end

function Market:immediateUpdatePrice(resourceType)
    local resource = self.resources[resourceType]
    local supplyDemandRatio = resource.supply / (resource.demand + 1)
    local priceMultiplier = 2 / (1 + supplyDemandRatio)
    
    local newPrice = resource.basePrice * priceMultiplier
    resource.currentPrice = resource.currentPrice * 0.9 + newPrice * 0.1
end

function Market:getPrice(resourceType)
    local resource = self.resources[resourceType]
    return resource and resource.currentPrice or 0
end

function Market:getSupply(resourceType)
    local resource = self.resources[resourceType]
    return resource and resource.supply or 0
end

function Market:getDemand(resourceType)
    local resource = self.resources[resourceType]
    return resource and resource.demand or 0
end

function Market:getAllPrices()
    local prices = {}
    for resourceType, resource in pairs(self.resources) do
        prices[resourceType] = {
            price = resource.currentPrice,
            supply = resource.supply,
            demand = resource.demand,
            trend = resource.trend > 0 and "rising" or "falling"
        }
    end
    return prices
end

return Market