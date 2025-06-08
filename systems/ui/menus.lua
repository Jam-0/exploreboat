local Menus = {}
Menus.__index = Menus

function Menus:new()
    local self = setmetatable({}, Menus)
    
    self.activeMenu = nil
    self.menus = {}
    
    self.buttonHeight = 40
    self.buttonWidth = 200
    self.padding = 10
    
    self.font = love.graphics.newFont(16)
    self.titleFont = love.graphics.newFont(24)
    
    self:initializeMenus()
    
    return self
end

function Menus:initializeMenus()
    self.menus.main = {
        title = "Ocean Trading Adventure",
        buttons = {
            {text = "New Game", action = function() self:startNewGame() end},
            {text = "Load Game", action = function() self:loadGame() end},
            {text = "Settings", action = function() self:openMenu("settings") end},
            {text = "Quit", action = function() love.event.quit() end}
        }
    }
    
    self.menus.pause = {
        title = "Paused",
        buttons = {
            {text = "Resume", action = function() self:closeMenu() end},
            {text = "Save Game", action = function() self:saveGame() end},
            {text = "Settings", action = function() self:openMenu("settings") end},
            {text = "Main Menu", action = function() self:openMenu("main") end}
        }
    }
    
    self.menus.settings = {
        title = "Settings",
        buttons = {
            {text = "Graphics", action = function() self:openMenu("graphics") end},
            {text = "Audio", action = function() self:openMenu("audio") end},
            {text = "Controls", action = function() self:openMenu("controls") end},
            {text = "Back", action = function() self:goBack() end}
        }
    }
    
    self.menus.trade = {
        title = "Trading Post",
        dynamic = true,
        generateButtons = function(market)
            local buttons = {}
            
            for resourceType, data in pairs(market:getAllPrices()) do
                table.insert(buttons, {
                    text = string.format("%s - $%.2f (S:%d D:%d)", 
                        resourceType:gsub("^%l", string.upper),
                        data.price,
                        data.supply,
                        data.demand
                    ),
                    action = function() self:openTradeDialog(resourceType, market) end
                })
            end
            
            table.insert(buttons, {text = "Close", action = function() self:closeMenu() end})
            return buttons
        end
    }
    
    self.menuStack = {}
end

function Menus:openMenu(menuName, data)
    local menu = self.menus[menuName]
    if menu then
        self.activeMenu = menuName
        self.menuData = data
        
        if menu.dynamic and menu.generateButtons then
            menu.buttons = menu.generateButtons(data)
        end
        
        table.insert(self.menuStack, menuName)
    end
end

function Menus:closeMenu()
    self.activeMenu = nil
    self.menuData = nil
    self.menuStack = {}
end

function Menus:goBack()
    table.remove(self.menuStack)
    if #self.menuStack > 0 then
        self.activeMenu = self.menuStack[#self.menuStack]
    else
        self:closeMenu()
    end
end

function Menus:update(dt)
end

function Menus:draw()
    if not self.activeMenu then return end
    
    local menu = self.menus[self.activeMenu]
    if not menu then return end
    
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    
    local menuHeight = #menu.buttons * (self.buttonHeight + self.padding) + 100
    local menuY = centerY - menuHeight / 2
    
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", centerX - 150, menuY - 20, 300, menuHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf(menu.title, centerX - 150, menuY, 300, "center")
    
    love.graphics.setFont(self.font)
    
    local buttonY = menuY + 60
    for i, button in ipairs(menu.buttons) do
        self:drawButton(button, centerX - self.buttonWidth / 2, buttonY)
        buttonY = buttonY + self.buttonHeight + self.padding
    end
end

function Menus:drawButton(button, x, y)
    local mx, my = love.mouse.getPosition()
    local hover = mx >= x and mx <= x + self.buttonWidth and
                  my >= y and my <= y + self.buttonHeight
    
    if hover then
        love.graphics.setColor(0.3, 0.4, 0.6, 1)
    else
        love.graphics.setColor(0.2, 0.3, 0.5, 1)
    end
    
    love.graphics.rectangle("fill", x, y, self.buttonWidth, self.buttonHeight)
    
    love.graphics.setColor(0.1, 0.2, 0.3, 1)
    love.graphics.rectangle("line", x, y, self.buttonWidth, self.buttonHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(button.text, x, y + self.buttonHeight / 2 - 8, self.buttonWidth, "center")
end

function Menus:mousepressed(x, y, mouseButton)
    if not self.activeMenu then return end
    
    local menu = self.menus[self.activeMenu]
    if not menu then return end
    
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    local menuHeight = #menu.buttons * (self.buttonHeight + self.padding) + 100
    local menuY = centerY - menuHeight / 2
    
    local buttonY = menuY + 60
    for i, button in ipairs(menu.buttons) do
        local buttonX = centerX - self.buttonWidth / 2
        
        if x >= buttonX and x <= buttonX + self.buttonWidth and
           y >= buttonY and y <= buttonY + self.buttonHeight then
            if button.action then
                button.action()
            end
            break
        end
        
        buttonY = buttonY + self.buttonHeight + self.padding
    end
end

function Menus:startNewGame()
    self:closeMenu()
end

function Menus:loadGame()
end

function Menus:saveGame()
end

function Menus:openTradeDialog(resourceType, market)
end

function Menus:isActive()
    return self.activeMenu ~= nil
end

function Menus:getCurrentMenu()
    return self.activeMenu
end

return Menus