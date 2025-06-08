local Trading = {}
Trading.__index = Trading

function Trading:new()
    local self = setmetatable({}, Trading)
    
    self.tradeFees = 0.02
    self.reputationMultiplier = {
        hostile = 1.5,
        unfriendly = 1.2,
        neutral = 1.0,
        friendly = 0.9,
        allied = 0.8
    }
    
    self.tradeHistory = {}
    self.reputation = {}
    
    return self
end

function Trading:canTrade(player, market)
    local distance = math.sqrt((player.x - market.x)^2 + (player.y - market.y)^2)
    return distance < 100
end

function Trading:buyFromMarket(player, market, resourceType, quantity)
    if not self:canTrade(player, market) then
        return false, "Too far from market"
    end
    
    local resource = market.resources[resourceType]
    if not resource then
        return false, "Resource not available at this market"
    end
    
    if resource.supply < quantity then
        return false, "Not enough supply"
    end
    
    local cargoSpace = self:getAvailableCargoSpace(player)
    if cargoSpace < quantity then
        return false, "Not enough cargo space"
    end
    
    local reputation = self:getReputation(player, market.cityId)
    local priceMultiplier = self.reputationMultiplier[reputation] or 1.0
    
    local unitPrice = resource.currentPrice * priceMultiplier * (1 + self.tradeFees)
    local totalCost = unitPrice * quantity
    
    if player.money < totalCost then
        return false, "Not enough money"
    end
    
    local success, marketCost = market:buyResource(resourceType, quantity)
    if not success then
        return false, marketCost
    end
    
    player.money = player.money - totalCost
    
    if not player.cargo[resourceType] then
        player.cargo[resourceType] = 0
    end
    player.cargo[resourceType] = player.cargo[resourceType] + quantity
    
    self:recordTrade(player, market.cityId, "buy", resourceType, quantity, totalCost)
    self:updateReputation(player, market.cityId, quantity * 0.1)
    
    return true, {
        resource = resourceType,
        quantity = quantity,
        totalCost = totalCost,
        unitPrice = unitPrice
    }
end

function Trading:sellToMarket(player, market, resourceType, quantity)
    if not self:canTrade(player, market) then
        return false, "Too far from market"
    end
    
    if not player.cargo[resourceType] or player.cargo[resourceType] < quantity then
        return false, "Not enough cargo"
    end
    
    local reputation = self:getReputation(player, market.cityId)
    local priceMultiplier = self.reputationMultiplier[reputation] or 1.0
    
    local success, marketValue = market:sellResource(resourceType, quantity)
    if not success then
        return false, marketValue
    end
    
    local totalValue = marketValue / priceMultiplier * (1 - self.tradeFees)
    
    player.money = player.money + totalValue
    player.cargo[resourceType] = player.cargo[resourceType] - quantity
    
    if player.cargo[resourceType] <= 0 then
        player.cargo[resourceType] = nil
    end
    
    self:recordTrade(player, market.cityId, "sell", resourceType, quantity, totalValue)
    self:updateReputation(player, market.cityId, quantity * 0.1)
    
    return true, {
        resource = resourceType,
        quantity = quantity,
        totalValue = totalValue,
        unitPrice = totalValue / quantity
    }
end

function Trading:getAvailableCargoSpace(player)
    local usedSpace = 0
    for _, quantity in pairs(player.cargo) do
        usedSpace = usedSpace + quantity
    end
    return player.maxCargo - usedSpace
end

function Trading:getCargoValue(player, market)
    local totalValue = 0
    for resourceType, quantity in pairs(player.cargo) do
        local price = market:getPrice(resourceType)
        totalValue = totalValue + (price * quantity * 0.9)
    end
    return totalValue
end

function Trading:recordTrade(player, cityId, tradeType, resourceType, quantity, value)
    if not self.tradeHistory[cityId] then
        self.tradeHistory[cityId] = {}
    end
    
    table.insert(self.tradeHistory[cityId], {
        type = tradeType,
        resource = resourceType,
        quantity = quantity,
        value = value,
        timestamp = os.time()
    })
    
    if #self.tradeHistory[cityId] > 100 then
        table.remove(self.tradeHistory[cityId], 1)
    end
end

function Trading:getReputation(player, cityId)
    if not self.reputation[cityId] then
        self.reputation[cityId] = {
            value = 0,
            level = "neutral"
        }
    end
    return self.reputation[cityId].level
end

function Trading:updateReputation(player, cityId, change)
    if not self.reputation[cityId] then
        self.reputation[cityId] = {
            value = 0,
            level = "neutral"
        }
    end
    
    self.reputation[cityId].value = self.reputation[cityId].value + change
    
    local value = self.reputation[cityId].value
    if value < -50 then
        self.reputation[cityId].level = "hostile"
    elseif value < -20 then
        self.reputation[cityId].level = "unfriendly"
    elseif value < 20 then
        self.reputation[cityId].level = "neutral"
    elseif value < 50 then
        self.reputation[cityId].level = "friendly"
    else
        self.reputation[cityId].level = "allied"
    end
end

function Trading:getTradeSummary(cityId)
    if not self.tradeHistory[cityId] then
        return {
            totalTrades = 0,
            totalBought = 0,
            totalSold = 0,
            totalSpent = 0,
            totalEarned = 0
        }
    end
    
    local summary = {
        totalTrades = #self.tradeHistory[cityId],
        totalBought = 0,
        totalSold = 0,
        totalSpent = 0,
        totalEarned = 0
    }
    
    for _, trade in ipairs(self.tradeHistory[cityId]) do
        if trade.type == "buy" then
            summary.totalBought = summary.totalBought + trade.quantity
            summary.totalSpent = summary.totalSpent + trade.value
        else
            summary.totalSold = summary.totalSold + trade.quantity
            summary.totalEarned = summary.totalEarned + trade.value
        end
    end
    
    return summary
end

return Trading