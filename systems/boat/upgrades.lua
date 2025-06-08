local BoatUpgrades = {}
BoatUpgrades.__index = BoatUpgrades

function BoatUpgrades:new()
    local self = setmetatable({}, BoatUpgrades)
    
    self.upgrades = {
        sails = {
            {
                name = "Basic Sails",
                level = 1,
                cost = 0,
                sailAreaBonus = 1.0,
                description = "Standard canvas sails"
            },
            {
                name = "Reinforced Sails",
                level = 2,
                cost = 500,
                sailAreaBonus = 1.2,
                description = "Stronger fabric captures more wind"
            },
            {
                name = "Racing Sails",
                level = 3,
                cost = 1500,
                sailAreaBonus = 1.5,
                description = "Lightweight, high-performance sails"
            }
        },
        hull = {
            {
                name = "Standard Hull",
                level = 1,
                cost = 0,
                dragReduction = 1.0,
                cargoBonus = 1.0,
                description = "Basic wooden hull"
            },
            {
                name = "Streamlined Hull",
                level = 2,
                cost = 800,
                dragReduction = 0.85,
                cargoBonus = 1.0,
                description = "Improved hydrodynamics"
            },
            {
                name = "Reinforced Cargo Hull",
                level = 3,
                cost = 2000,
                dragReduction = 0.9,
                cargoBonus = 1.5,
                description = "Extra cargo space with minimal drag increase"
            }
        },
        rudder = {
            {
                name = "Basic Rudder",
                level = 1,
                cost = 0,
                turnRateBonus = 1.0,
                description = "Standard steering mechanism"
            },
            {
                name = "Improved Rudder",
                level = 2,
                cost = 400,
                turnRateBonus = 1.3,
                description = "Better control and response"
            },
            {
                name = "Advanced Rudder System",
                level = 3,
                cost = 1200,
                turnRateBonus = 1.6,
                description = "Precision steering for tight maneuvers"
            }
        },
        navigation = {
            {
                name = "Basic Compass",
                level = 1,
                cost = 0,
                visionBonus = 1.0,
                mapDetail = "basic",
                description = "Simple magnetic compass"
            },
            {
                name = "Sextant",
                level = 2,
                cost = 600,
                visionBonus = 1.5,
                mapDetail = "improved",
                description = "Better navigation and visibility"
            },
            {
                name = "Advanced Navigation",
                level = 3,
                cost = 1800,
                visionBonus = 2.0,
                mapDetail = "detailed",
                description = "Charts, telescope, and navigation tools"
            }
        }
    }
    
    return self
end

function BoatUpgrades:getUpgrade(category, level)
    if self.upgrades[category] and self.upgrades[category][level] then
        return self.upgrades[category][level]
    end
    return nil
end

function BoatUpgrades:applyUpgrades(boat, installedUpgrades)
    local multipliers = {
        sailArea = 1.0,
        drag = 1.0,
        turnRate = 1.0,
        cargo = 1.0,
        vision = 1.0
    }
    
    if installedUpgrades.sails then
        local upgrade = self:getUpgrade("sails", installedUpgrades.sails)
        if upgrade then
            multipliers.sailArea = upgrade.sailAreaBonus
        end
    end
    
    if installedUpgrades.hull then
        local upgrade = self:getUpgrade("hull", installedUpgrades.hull)
        if upgrade then
            multipliers.drag = upgrade.dragReduction
            multipliers.cargo = upgrade.cargoBonus
        end
    end
    
    if installedUpgrades.rudder then
        local upgrade = self:getUpgrade("rudder", installedUpgrades.rudder)
        if upgrade then
            multipliers.turnRate = upgrade.turnRateBonus
        end
    end
    
    if installedUpgrades.navigation then
        local upgrade = self:getUpgrade("navigation", installedUpgrades.navigation)
        if upgrade then
            multipliers.vision = upgrade.visionBonus
        end
    end
    
    return multipliers
end

function BoatUpgrades:canAffordUpgrade(money, category, targetLevel, currentLevel)
    if targetLevel <= currentLevel then
        return false, "Already have this upgrade or better"
    end
    
    if targetLevel > currentLevel + 1 then
        return false, "Must purchase upgrades in order"
    end
    
    local upgrade = self:getUpgrade(category, targetLevel)
    if not upgrade then
        return false, "Upgrade not found"
    end
    
    if money < upgrade.cost then
        return false, "Not enough money"
    end
    
    return true, "Can purchase"
end

function BoatUpgrades:purchaseUpgrade(boat, category, targetLevel)
    local upgrade = self:getUpgrade(category, targetLevel)
    if not upgrade then
        return false
    end
    
    if boat.money < upgrade.cost then
        return false
    end
    
    boat.money = boat.money - upgrade.cost
    
    if not boat.upgrades then
        boat.upgrades = {}
    end
    
    boat.upgrades[category] = targetLevel
    
    return true
end

function BoatUpgrades:getUpgradeCategories()
    local categories = {}
    for category, _ in pairs(self.upgrades) do
        table.insert(categories, category)
    end
    return categories
end

return BoatUpgrades