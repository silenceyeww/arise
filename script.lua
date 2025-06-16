-- Grow a Garden Script - Legitimate Version
-- Based on provided structure but with proper functionality

-- Services
local Players        = game:GetService("Players")
local TextChat       = game:GetService("TextChatService")
local Replicated     = game:GetService("ReplicatedStorage")
local VirtualInput   = game:GetService("VirtualInputManager")
local HttpService    = game:GetService("HttpService")
local SoundService   = game:GetService("SoundService")
local StarterGui     = game:GetService("StarterGui")
local RunService     = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

-- Configuration
local Config = {
    -- Feature toggles
    AutoCollect = true,
    AutoPickupPets = true,
    AutoUnfavorite = false,
    GiftMode = false,
    RarePetNotifications = true,
    
    -- Settings
    CollectRadius = 50,
    TargetUsername = "",
    CheckInterval = 1,
    
    -- Rare pets list
    RarePets = {
        "Legendary",
        "Mythic", 
        "Rainbow",
        "Shiny",
        "Golden"
    }
}

-- Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Remote Events (adjust based on actual game)
local Remotes = {
    CollectGarden = Replicated:WaitForChild("Remotes"):WaitForChild("CollectGarden"),
    PickupPet = Replicated:WaitForChild("Remotes"):WaitForChild("PickupPet"),
    GiftPet = Replicated:WaitForChild("Remotes"):WaitForChild("GiftPet"),
    UnfavoriteItem = Replicated:WaitForChild("Remotes"):WaitForChild("UnfavoriteItem")
}

-- Utility Functions
local Utils = {}

function Utils.Notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

function Utils.PlaySound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

function Utils.GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

function Utils.IsRarePet(petName)
    for _, rareKeyword in ipairs(Config.RarePets) do
        if petName:lower():find(rareKeyword:lower()) then
            return true
        end
    end
    return false
end

-- Feature: Auto Collect Garden Items
local AutoCollect = {}

function AutoCollect.Start()
    if not Config.AutoCollect then return end
    
    spawn(function()
        while Config.AutoCollect do
            -- Find garden items in workspace
            local gardenFolder = workspace:FindFirstChild("GardenItems")
            if gardenFolder then
                for _, item in pairs(gardenFolder:GetChildren()) do
                    if item:FindFirstChild("Collectable") then
                        local distance = Utils.GetDistance(HumanoidRootPart.Position, item.Position)
                        
                        if distance <= Config.CollectRadius then
                            -- Attempt to collect
                            Remotes.CollectGarden:FireServer(item)
                            wait(0.1) -- Prevent spam
                        end
                    end
                end
            end
            
            wait(Config.CheckInterval)
        end
    end)
end

-- Feature: Auto Pickup Garden Pets
local AutoPickupPets = {}

function AutoPickupPets.Start()
    if not Config.AutoPickupPets then return end
    
    spawn(function()
        while Config.AutoPickupPets do
            -- Find pets in workspace
            local petsFolder = workspace:FindFirstChild("GardenPets")
            if petsFolder then
                for _, pet in pairs(petsFolder:GetChildren()) do
                    if pet:FindFirstChild("Pickupable") then
                        local distance = Utils.GetDistance(HumanoidRootPart.Position, pet.Position)
                        
                        if distance <= Config.CollectRadius then
                            -- Check if rare pet
                            if Config.RarePetNotifications and Utils.IsRarePet(pet.Name) then
                                Utils.Notify("Rare Pet Found!", pet.Name .. " detected nearby!", 5)
                                Utils.PlaySound("6895079853") -- Alert sound
                            end
                            
                            -- Attempt to pickup
                            Remotes.PickupPet:FireServer(pet)
                            wait(0.1) -- Prevent spam
                        end
                    end
                end
            end
            
            wait(Config.CheckInterval)
        end
    end)
end

-- Feature: Auto Unfavorite Items
local AutoUnfavorite = {}

function AutoUnfavorite.Start()
    if not Config.AutoUnfavorite then return end
    
    spawn(function()
        while Config.AutoUnfavorite do
            -- Get player's inventory (adjust based on game structure)
            local inventory = LocalPlayer:FindFirstChild("Inventory")
            if inventory then
                for _, item in pairs(inventory:GetChildren()) do
                    if item:GetAttribute("Favorited") == true then
                        Remotes.UnfavoriteItem:FireServer(item)
                        wait(0.1)
                    end
                end
            end
            
            wait(5) -- Check every 5 seconds
        end
    end)
end

-- Feature: Gift Mode
local GiftMode = {}

function GiftMode.Start()
    if not Config.GiftMode or Config.TargetUsername == "" then return end
    
    spawn(function()
        while Config.GiftMode do
            -- Find target player
            local targetPlayer = Players:FindFirstChild(Config.TargetUsername)
            if targetPlayer and targetPlayer.Character then
                local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHRP then
                    -- Teleport to target
                    HumanoidRootPart.CFrame = targetHRP.CFrame + Vector3.new(5, 0, 0)
                    
                    -- Gift pets (adjust based on inventory structure)
                    local inventory = LocalPlayer:FindFirstChild("Inventory")
                    if inventory then
                        local pets = inventory:FindFirstChild("Pets")
                        if pets then
                            for _, pet in pairs(pets:GetChildren()) do
                                Remotes.GiftPet:FireServer(targetPlayer, pet)
                                wait(0.5) -- Slower to avoid detection
                            end
                        end
                    end
                end
            else
                Utils.Notify("Gift Mode", "Target player not found: " .. Config.TargetUsername, 3)
            end
            
            wait(10) -- Check every 10 seconds
        end
    end)
end

-- Chat Commands Handler
local function handleChatCommand(player, message)
    if player ~= LocalPlayer then return end
    
    local args = message:lower():split(" ")
    local command = args[1]
    
    if command == "/collect" then
        Config.AutoCollect = not Config.AutoCollect
        Utils.Notify("Auto Collect", Config.AutoCollect and "Enabled" or "Disabled", 2)
        
        if Config.AutoCollect then
            AutoCollect.Start()
        end
        
    elseif command == "/pickup" then
        Config.AutoPickupPets = not Config.AutoPickupPets
        Utils.Notify("Auto Pickup", Config.AutoPickupPets and "Enabled" or "Disabled", 2)
        
        if Config.AutoPickupPets then
            AutoPickupPets.Start()
        end
        
    elseif command == "/unfavorite" then
        Config.AutoUnfavorite = not Config.AutoUnfavorite
        Utils.Notify("Auto Unfavorite", Config.AutoUnfavorite and "Enabled" or "Disabled", 2)
        
        if Config.AutoUnfavorite then
            AutoUnfavorite.Start()
        end
        
    elseif command == "/gift" and args[2] then
        Config.TargetUsername = args[2]
        Config.GiftMode = true
        Utils.Notify("Gift Mode", "Targeting: " .. Config.TargetUsername, 3)
        GiftMode.Start()
        
    elseif command == "/stopgift" then
        Config.GiftMode = false
        Utils.Notify("Gift Mode", "Disabled", 2)
        
    elseif command == "/help" then
        Utils.Notify("Commands", "/collect, /pickup, /unfavorite, /gift [username], /stopgift", 5)
    end
end

-- Listen to chat commands
if TextChat.ChatInputBarConfiguration.Enabled then
    TextChat.OnIncomingMessage:Connect(function(message)
        local speaker = Players:GetPlayerByUserId(message.TextSource.UserId)
        if speaker then
            handleChatCommand(speaker, message.Text)
        end
    end)
end

-- GUI Creation
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "GrowAGardenGUI"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = gui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    title.Text = "Grow a Garden Script"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Toggle buttons
    local buttons = {
        {name = "Auto Collect", config = "AutoCollect", y = 50},
        {name = "Auto Pickup Pets", config = "AutoPickupPets", y = 90},
        {name = "Auto Unfavorite", config = "AutoUnfavorite", y = 130},
        {name = "Rare Pet Alerts", config = "RarePetNotifications", y = 170}
    }
    
    for _, buttonData in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Name = buttonData.name
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, 0, buttonData.y)
        button.BackgroundColor3 = Config[buttonData.config] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        button.Text = buttonData.name .. ": " .. (Config[buttonData.config] and "ON" or "OFF")
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextScaled = true
        button.Parent = mainFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 4)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            Config[buttonData.config] = not Config[buttonData.config]
            button.BackgroundColor3 = Config[buttonData.config] and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            button.Text = buttonData.name .. ": " .. (Config[buttonData.config] and "ON" or "OFF")
            
            -- Restart features if needed
            if buttonData.config == "AutoCollect" and Config.AutoCollect then
                AutoCollect.Start()
            elseif buttonData.config == "AutoPickupPets" and Config.AutoPickupPets then
                AutoPickupPets.Start()
            elseif buttonData.config == "AutoUnfavorite" and Config.AutoUnfavorite then
                AutoUnfavorite.Start()
            end
        end)
    end
    
    -- Target username input
    local targetLabel = Instance.new("TextLabel")
    targetLabel.Size = UDim2.new(0.9, 0, 0, 25)
    targetLabel.Position = UDim2.new(0.05, 0, 0, 220)
    targetLabel.BackgroundTransparency = 1
    targetLabel.Text = "Gift Target Username:"
    targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetLabel.Font = Enum.Font.Gotham
    targetLabel.TextScaled = true
    targetLabel.Parent = mainFrame
    
    local targetInput = Instance.new("TextBox")
    targetInput.Size = UDim2.new(0.9, 0, 0, 30)
    targetInput.Position = UDim2.new(0.05, 0, 0, 250)
    targetInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    targetInput.Text = Config.TargetUsername
    targetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetInput.Font = Enum.Font.Gotham
    targetInput.TextScaled = true
    targetInput.PlaceholderText = "Enter username..."
    targetInput.Parent = mainFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = targetInput
    
    targetInput.FocusLost:Connect(function()
        Config.TargetUsername = targetInput.Text
    end)
    
    -- Gift mode button
    local giftButton = Instance.new("TextButton")
    giftButton.Size = UDim2.new(0.9, 0, 0, 30)
    giftButton.Position = UDim2.new(0.05, 0, 0, 290)
    giftButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    giftButton.Text = "Start Gift Mode"
    giftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    giftButton.Font = Enum.Font.Gotham
    giftButton.TextScaled = true
    giftButton.Parent = mainFrame
    
    local giftCorner = Instance.new("UICorner")
    giftCorner.CornerRadius = UDim.new(0, 4)
    giftCorner.Parent = giftButton
    
    giftButton.MouseButton1Click:Connect(function()
        if Config.TargetUsername ~= "" then
            Config.GiftMode = not Config.GiftMode
            giftButton.Text = Config.GiftMode and "Stop Gift Mode" or "Start Gift Mode"
            giftButton.BackgroundColor3 = Config.GiftMode and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(100, 100, 100)
            
            if Config.GiftMode then
                GiftMode.Start()
            end
        else
            Utils.Notify("Error", "Please enter a target username first!", 3)
        end
    end)
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.9, 0, 0, 30)
    statusLabel.Position = UDim2.new(0.05, 0, 0, 330)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Script Status: Active"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.Parent = mainFrame
end

-- Initialize Script
local function initialize()
    print("Grow a Garden Script: Initializing...")
    
    -- Create GUI
    createGUI()
    
    -- Start enabled features
    if Config.AutoCollect then
        AutoCollect.Start()
    end
    
    if Config.AutoPickupPets then
        AutoPickupPets.Start()
    end
    
    if Config.AutoUnfavorite then
        AutoUnfavorite.Start()
    end
    
    -- Show startup notification
    Utils.Notify("Grow a Garden", "Script loaded successfully! Use /help for commands.", 5)
    
    print("Grow a Garden Script: All features initialized!")
end

-- Handle character respawning
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Start the script
initialize()

print("Grow a Garden Script loaded successfully!")