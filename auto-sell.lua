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
local weapon_IDs = {}
local chest_IDs = {}
local helmet_IDs = {}
local ability_IDs = {}
 
local function getInventoryItems()
    weapon_IDs = {}
    chest_IDs = {}
    helmet_IDs = {}
    ability_IDs = {}
 
    local inventoryFrame = PlayerGui:WaitForChild("InventoryUi").Main.Display.Gear.ItemScrollingFrame
 
    for _, item in ipairs(inventoryFrame:GetChildren()) do
        if item:IsA("TextButton") then
            local itemType = item:GetAttribute("ItemType")
            if itemType then
                if itemType == "weapon" then
                    table.insert(weapon_IDs, #weapon_IDs + 1)
                elseif itemType == "chest" then
                    table.insert(chest_IDs, #chest_IDs + 1)
                elseif itemType == "helmet" then
                    table.insert(helmet_IDs, #helmet_IDs + 1)
                elseif itemType == "ability" then
                    table.insert(ability_IDs, #ability_IDs + 1)
                end
            end
        end
    end
end
 
local function loadStats()
    local saveFolder = "folder"
    if not isfolder(saveFolder) then makefolder(saveFolder) end
    local filePath = saveFolder .. "/inv-stats.txt"
 
    if isfile(filePath) then
        local content = readfile(filePath)
        for line in content:gmatch("[^\r\n]+") do
            local idName, idValues = line:match("(%w+)_IDs: (.+)")
            if idName and idValues then
                local idList = {}
                for id in idValues:gmatch("%d+") do
                    table.insert(idList, tonumber(id))
                end
                _G[idName .. "_IDs"] = idList
            end
        end
    else
        warn("Failed to load inventory stats")
    end
end
 
local function saveStats()
    getInventoryItems()
 
    local saveFolder = "folder"
    if not isfolder(saveFolder) then makefolder(saveFolder) end
    local filePath = saveFolder .. "/inv-stats.txt"
 
    local content = string.format("weapon_IDs: %s\nchest_IDs: %s\nhelmet_IDs: %s\nability_IDs: %s\n",
        table.concat(weapon_IDs, ","),
        table.concat(chest_IDs, ","),
        table.concat(helmet_IDs, ","),
        table.concat(ability_IDs, ","))
 
    writefile(filePath, content)
end
 
local function startAutoSell()
    spawn(function()
        while isSelling do
            wait(1)
 
            local inventoryFrame = PlayerGui:WaitForChild("InventoryUi").Main.Display.Gear.ItemScrollingFrame
            local currentInventoryState = {
                weapon = {},
                chest = {},
                helmet = {},
                ability = {}
            }
            local itemsToSell = {
                weapon = {},
                chest = {},
                helmet = {},
                ability = {}
            }
 
            for _, item in ipairs(inventoryFrame:GetChildren()) do
                if item:IsA("TextButton") then
                    local itemType = item:GetAttribute("ItemType")
                    local itemRarity = item:GetAttribute("Rarity")
                    if itemType and itemRarity then
                        table.insert(currentInventoryState[itemType], {name = item.Name, rarity = itemRarity})
                    end
                end
            end
 
            for itemType, items in pairs(currentInventoryState) do
                local savedIDs = _G[itemType .. "_IDs"]
                for i, item in ipairs(items) do
                    if i > #savedIDs and item.rarity ~= "legendary" then
                        table.insert(itemsToSell[itemType], item.name)
                    end
                end
            end
 
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
 
                saveStats()
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
getInventoryItems()
