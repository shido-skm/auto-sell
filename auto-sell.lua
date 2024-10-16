local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
MainFrame.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
MainFrame.Parent = ScreenGui

local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0, 150, 0, 30)
SaveButton.Position = UDim2.new(0.5, -75, 0.2, 0)
SaveButton.Text = "Save Stats"
SaveButton.Parent = MainFrame

local SellToggle = Instance.new("TextButton")
SellToggle.Size = UDim2.new(0, 150, 0, 30)
SellToggle.Position = UDim2.new(0.5, -75, 0.6, 0)
SellToggle.Text = "Sell: OFF"
SellToggle.Parent = MainFrame

local isSelling = false
local weapon_IDs = 0
local chest_IDs = 0
local helmet_IDs = 0
local ability_IDs = 0

-- Function to save inventory stats
local function saveStats()
    local file = io.open("inv-stats.txt", "w")
    if file then
        file:write("Weapon IDs: " .. weapon_IDs .. "\n")
        file:write("Chest IDs: " .. chest_IDs .. "\n")
        file:write("Helmet IDs: " .. helmet_IDs .. "\n")
        file:write("Ability IDs: " .. ability_IDs .. "\n")
        
        -- List all items (you need to implement getInventoryItems)
        local items = getInventoryItems()
        for _, item in ipairs(items) do
            file:write(string.format("%s, %s, %s\n", item.name, item.rarity, item.category))
        end
        
        file:close()
    else
        warn("Failed to save inventory stats")
    end
end

local function startAutoSell()
    spawn(function()
        local oldItems = getInventoryItems()
        while isSelling do
            wait(1)  -- Check every second
            local newItems = getInventoryItems()
            local itemsToSell = {}
            local newAbilities = {}
            local hasLegendaryAbility = false
            
            for _, item in ipairs(newItems) do
                if not table.find(oldItems, item) then
                    if item.category == "ability" then
                        table.insert(newAbilities, item)
                        if item.rarity == "Legendary" then
                            hasLegendaryAbility = true
                        end
                    else
                        table.insert(itemsToSell, item)
                    end
                end
            end
            
            if hasLegendaryAbility then
                -- If there's a legendary ability, only sell new weapons, chests, and helmets
                sellItems(itemsToSell)  -- Sell only weapons, chests, helmets
                ability_IDs = ability_IDs + #newAbilities  -- Add count of new abilities
            else
                -- If no legendary ability, sell all new items
                sellItems(itemsToSell)
                ability_IDs = ability_IDs + #newAbilities  -- Add count of new abilities
            end
            
            oldItems = newItems
        end
    end)
end

local function toggleSell()
    isSelling = not isSelling
    SellToggle.Text = isSelling and "Sell: ON" or "Sell: OFF"
    
    if isSelling then
        startAutoSell()
    end
end

SaveButton.MouseButton1Click:Connect(saveStats)
SellToggle.MouseButton1Click:Connect(toggleSell)
