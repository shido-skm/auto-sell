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

-- Function to save the toggle state
local function saveToggleState()
    local file = io.open("auto_sell_state.txt", "w")
    if file then
        file:write(tostring(isSelling))
        file:close()
    else
        warn("Failed to save auto-sell state")
    end
end

-- Function to load the toggle state
local function loadToggleState()
    local file = io.open("auto_sell_state.txt", "r")
    if file then
        local content = file:read("*all")
        file:close()
        isSelling = (content == "true")
        SellToggle.Text = isSelling and "Sell: ON" or "Sell: OFF"
        if isSelling then
            startAutoSell()
        end
    else
        warn("No saved auto-sell state found")
    end
end

-- Rest of the functions (getInventoryItems, saveStats, sellItems) remain the same

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
            
            if not hasLegendaryAbility then
                for _, item in ipairs(newAbilities) do
                    table.insert(itemsToSell, item)
                end
            end
            
            sellItems(itemsToSell)
            
            -- Update counts (file I/O part remains the same)
            
            oldItems = newItems
        end
    end)
end

local function toggleSell()
    isSelling = not isSelling
    SellToggle.Text = isSelling and "Sell: ON" or "Sell: OFF"
    
    saveToggleState()  -- Save the new state
    
    if isSelling then
        startAutoSell()
    end
end

SaveButton.MouseButton1Click:Connect(saveStats)
SellToggle.MouseButton1Click:Connect(toggleSell)

-- Load the toggle state when the script starts
loadToggleState()
