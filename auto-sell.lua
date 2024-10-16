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
local inventoryState = {}

local function getInventoryItems()
    local inventoryFrame = PlayerGui:WaitForChild("InventoryUi").Main.Display.Gear.ItemScrollingFrame
    local currentItems = {}

    for _, item in ipairs(inventoryFrame:GetChildren()) do
        if item:IsA("TextButton") then
            local itemType = item:GetAttribute("ItemType")
            local itemRarity = item:GetAttribute("Rarity")
            if itemType and itemRarity then
                table.insert(currentItems, {name = item.Name, rarity = itemRarity, type = itemType})
            end
        end
    end

    return currentItems
end

local function loadStats()
    local filePath = "inv-stats.txt"

    if isfile(filePath) then
        local content = readfile(filePath)
        inventoryState = {}  -- Reset the inventory state
        for line in content:gmatch("[^\r\n]+") do
            local itemName, itemRarity, itemType = line:match("(%w+), (%w+), (%w+)")
            if itemName and itemRarity and itemType then
                table.insert(inventoryState, {name = itemName, rarity = itemRarity, type = itemType})
            end
        end
    else
        warn("Failed to load inventory stats")
    end
end

local function saveStats()
    local filePath = "inv-stats.txt"
    local content = ""

    for _, item in ipairs(inventoryState) do
        content = content .. string.format("%s, %s, %s\n", item.name, item.rarity, item.type)
    end

    writefile(filePath, content)
end

local function startAutoSell()
    spawn(function()
        while isSelling do
            wait(1)

            local currentInventory = getInventoryItems()
            local itemsToSell = {weapon = {}, chest = {}, helmet = {}, ability = {}}
            local newAbilitiesCount = 0
            local hasLegendaryAbility = false

            for _, item in ipairs(currentInventory) do
                local isNewItem = true
                for _, savedItem in ipairs(inventoryState) do
                    if item.name == savedItem.name and item.rarity == savedItem.rarity and item.type == savedItem.type then
                        isNewItem = false
                        break
                    end
                end

                if isNewItem then
                    if item.type == "ability" then
                        if item.rarity == "Legendary" then
                            hasLegendaryAbility = true
                        end
                        newAbilitiesCount = newAbilitiesCount + 1
                    else
                        table.insert(itemsToSell[item.type], item.name)
                    end
                end
            end

            -- Sell logic based on detected items
            local args = {
                [1] = {
                    ["chest"] = itemsToSell.chest,
                    ["helmet"] = itemsToSell.helmet,
                    ["weapon"] = itemsToSell.weapon,
                    ["ability"] = hasLegendaryAbility and {} or itemsToSell.ability  -- Don't sell abilities if a legendary is present
                }
            }

            game:GetService("ReplicatedStorage").remotes.sellItemEvent:FireServer(unpack(args))

            -- Update inventory state only if no legendary ability was detected
            if not hasLegendaryAbility then
                for _, item in ipairs(currentInventory) do
                    table.insert(inventoryState, item)
                end
                saveStats()  -- Save updated inventory state
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
