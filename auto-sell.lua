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
local currentItems = {}
local weapon_IDs = 0
local chest_IDs = 0
local helmet_IDs = 0
local ability_IDs = 0

-- Function to load inventory stats from a file
local function loadStats()
    local file = io.open("inv-stats.txt", "r")
    if file then
        for line in file:lines() do
            -- Parse item information
            if line:find(",") then
                local itemName, rarity, category = line:match("([^,]+), ([^,]+), ([^,]+)")
                table.insert(currentItems, {name = itemName, rarity = rarity, category = category})
            else
                -- Update ID counts
                local idName, idValue = line:match("(%w+)_IDs: (%d+)")
                if idName and idValue then
                    _G[idName .. "_IDs"] = tonumber(idValue)
                end
            end
        end
        file:close()
    else
        warn("Failed to load inventory stats")
    end
end

-- Function to save the inventory stats to a file
local function saveStats()
    local file = io.open("inv-stats.txt", "w")
    if file then
        for _, item in ipairs(currentItems) do
            file:write(string.format("%s, %s, %s\n", item.name, item.rarity, item.category))
        end
        file:write(string.format("weapon_IDs: %d\nchest_IDs: %d\nhelmet_IDs: %d\nability_IDs: %d\n",
            weapon_IDs, chest_IDs, helmet_IDs, ability_IDs))
        file:close()
    else
        warn("Failed to save inventory stats")
    end
end

-- Function to get the current inventory items
local function getInventoryItems()
    local items = {}
    -- Logic to retrieve items and populate the items table (same logic as before)
    return items
end

local function startAutoSell()
    spawn(function()
        local oldItems = currentItems -- Initial state
        while isSelling do
            wait(1) -- Check every second
            local newItems = getInventoryItems()
            local itemsToSell = {}
            local newAbilities = {}
            local hasLegendaryAbility = false
            
            -- Compare new items with old items
            for _, newItem in ipairs(newItems) do
                if not table.find(oldItems, newItem) then
                    if newItem.category == "ability" then
                        table.insert(newAbilities, newItem)
                        if newItem.rarity == "Legendary" then
                            hasLegendaryAbility = true
                        end
                    else
                        table.insert(itemsToSell, newItem)
                    end
                end
            end
            
            if hasLegendaryAbility then
                -- Sell only weapons, chests, and helmets
                sellItems(itemsToSell) -- Implement sellItems function as necessary
                ability_IDs = ability_IDs + #newAbilities -- Update ability_IDs count
            else
                -- Sell all new items including abilities
                sellItems(newItems) -- Implement sellItems function as necessary
            end

            currentItems = newItems -- Update the current items list
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

-- Load initial item state
loadStats() -- Load current items and ID counts when script starts
