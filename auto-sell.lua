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
local weapon_count, chest_count, helmet_count, ability_count = 0, 0, 0, 0
local storedItemList = {}

local function getInventoryItems()
    local inventoryItems = {}
    local inventoryFrame = PlayerGui:WaitForChild("InventoryUi").Main.Display.Gear.ItemScrollingFrame

    for _, item in ipairs(inventoryFrame:GetChildren()) do
        if item:IsA("TextButton") then
            local itemType = item:GetAttribute("ItemType")
            local itemRarity = item:GetAttribute("Rarity")
            if itemType and itemRarity then
                table.insert(inventoryItems, {name = item.Name, category = itemType, rarity = itemRarity})
            end
        end
    end
    return inventoryItems
end

local function saveStats()
    local inventoryItems = getInventoryItems()
    storedItemList = inventoryItems
    
    weapon_count = 0
    chest_count = 0
    helmet_count = 0
    ability_count = 0
    
    for _, item in ipairs(inventoryItems) do
        if item.category == "weapon" then
            weapon_count = weapon_count + 1
        elseif item.category == "chest" then
            chest_count = chest_count + 1
        elseif item.category == "helmet" then
            helmet_count = helmet_count + 1
        elseif item.category == "ability" then
            ability_count = ability_count + 1
        end
    end

    local content = string.format("weapon_count: %d\nchest_count: %d\nhelmet_count: %d\nability_count: %d\n",
        weapon_count, chest_count, helmet_count, ability_count)

    content = content .. "Item Data:\n"
    for _, item in ipairs(inventoryItems) do
        content = content .. string.format("%s,%s,%s\n", item.name, item.category, item.rarity)
    end

    writefile("inv-state.txt", content)
end

local function loadStats()
    if isfile("inv-state.txt") then
        local content = readfile("inv-state.txt")
        local itemDataSection = false
        storedItemList = {}

        for line in content:gmatch("[^\r\n]+") do
            if line == "Item Data:" then
                itemDataSection = true
            elseif itemDataSection then
                local name, category, rarity = line:match("([^,]+),([^,]+),([^,]+)")
                if name and category and rarity then
                    table.insert(storedItemList, {name = name, category = category, rarity = rarity})
                end
            else
                local countName, countValue = line:match("(%w+)_count: (%d+)")
                if countName and countValue then
                    _G[countName .. "_count"] = tonumber(countValue)
                end
            end
        end
    else
        warn("Failed to load inventory stats")
    end
end

local function startAutoSell()
    spawn(function()
        while isSelling do
            wait(1)

            local currentItems = getInventoryItems()
            local newItems = {}
            local hasLegendaryAbility = false
            local itemsToSell = {weapon = {}, chest = {}, helmet = {}, ability = {}}

            -- Identify new items
            for i = #storedItemList + 1, #currentItems do
                table.insert(newItems, currentItems[i])
                if currentItems[i].category == "ability" and currentItems[i].rarity == "Legendary" then
                    hasLegendaryAbility = true
                end
            end

            -- Determine items to sell
            for _, item in ipairs(newItems) do
                if item.category ~= "ability" or (item.category == "ability" and not hasLegendaryAbility) then
                    local categoryCount = _G[item.category .. "_count"]
                    if #itemsToSell[item.category] < 9 and categoryCount + #itemsToSell[item.category] < #currentItems then
                        table.insert(itemsToSell[item.category], categoryCount + #itemsToSell[item.category] + 1)
                    end
                end
            end

            -- Sell items
            if #itemsToSell.weapon > 0 or #itemsToSell.chest > 0 or #itemsToSell.helmet > 0 or #itemsToSell.ability > 0 then
                local args = {
                    [1] = {
                        ["chest"] = itemsToSell.chest,
                        ["ability"] = itemsToSell.ability,
                        ["helmet"] = itemsToSell.helmet,
                        ["ring"] = {},
                        ["weapon"] = itemsToSell.weapon
                    }
                }

                game:GetService("ReplicatedStorage").remotes.sellItemEvent:FireServer(unpack(args))

                -- Update stored item list and save stats only if a legendary ability was found
                if hasLegendaryAbility then
                    for _, item in ipairs(newItems) do
                        if item.category == "ability" then
                            ability_count = ability_count + 1
                            table.insert(storedItemList, item)
                        end
                    end
                    saveStats()
                end
            end
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

loadStats()
