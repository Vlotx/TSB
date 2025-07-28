local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "the strongest battlegrounds ",
    SubTitle = "by กูเองควย",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    Fluent:Notify({
        Title = "Notification",
        Content = "This is a notification",
        SubContent = "SubContent", -- Optional
        Duration = 5 -- Set to nil to make the notification not disappear
    })



local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local tp = false
local selectedPlayerName = nil
local trashCanList = {}
local trashIndex = 1

-- สร้าง Toggle เปิด/ปิด Auto Teleport
local Toggle = Tabs.Main:AddToggle("AutoTeleportToggle", {
    Title = "ฆ่าผู้เล่น",
    Default = false,
})

Toggle:OnChanged(function(state)
    tp = state
end)

local function CreatePlayerDropdown()
    local localPlayer = Players.LocalPlayer
    if not localPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        localPlayer = Players.LocalPlayer
    end

    local localPlayerName = localPlayer.Name

    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name ~= localPlayerName then
            table.insert(playerNames, player.Name)
        end
    end

    local Dropdown = Tabs.Main:AddDropdown("PlayerDropdown", {
        Title = "เลือกผู้เล่น",
        Values = playerNames,
        Multi = false,
        Default = playerNames[1] or nil,
    })

    Dropdown:OnChanged(function(playerName)
        selectedPlayerName = playerName
    end)

    Players.PlayerAdded:Connect(function()
        local updatedNames = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name ~= localPlayerName then
                table.insert(updatedNames, player.Name)
            end
        end
        Dropdown:SetValues(updatedNames)
    end)

    Players.PlayerRemoving:Connect(function()
        local updatedNames = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name ~= localPlayerName then
                table.insert(updatedNames, player.Name)
            end
        end
        Dropdown:SetValues(updatedNames)
    end)
end

CreatePlayerDropdown()

local function ClickCenter()
    local center = workspace.CurrentCamera.ViewportSize / 2
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
end

local function RefreshTrashCanList(trashFolder)
    trashCanList = {}
    if not trashFolder then return end
    for _, trashModel in ipairs(trashFolder:GetChildren()) do
        if trashModel:IsA("Model") and trashModel.Name == "Trashcan" then
            local meshPart = trashModel:FindFirstChild("Trashcan")
            if meshPart and meshPart:IsA("MeshPart") then
                table.insert(trashCanList, meshPart)
            end
        end
    end
end

local function TeleportAndClick()
    local me = Players.LocalPlayer
    if not (me and me.Character and me.Character:FindFirstChild("HumanoidRootPart")) then return end
    local myHRP = me.Character.HumanoidRootPart

    local trashCanInMe = me.Character:FindFirstChild("Trash Can")
    local trashFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Trash")

    if trashCanInMe and trashCanInMe:IsA("MeshPart") then
        local targetPlayer = Players:FindFirstChild(selectedPlayerName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = targetPlayer.Character.HumanoidRootPart
            myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 2)
            task.wait(0.3)
            ClickCenter()
        end
    else
        if #trashCanList == 0 then
            RefreshTrashCanList(trashFolder)
            trashIndex = 1
        end

        while #trashCanList > 0 do
            local currentTrash = trashCanList[trashIndex]

            if currentTrash and currentTrash.Parent then
                local broken = currentTrash.Parent:GetAttribute("Broken")
                if broken == "flash" then
                    trashIndex = trashIndex + 1
                    if trashIndex > #trashCanList then
                        trashIndex = 1
                    end
                else
                    myHRP.CFrame = currentTrash.CFrame * CFrame.new(0, 0, 2)
                    task.wait(1) -- ✅ รอ 1 วิ ก่อนคลิก
                    ClickCenter()

                    trashIndex = trashIndex + 1
                    if trashIndex > #trashCanList then
                        trashIndex = 1
                    end
                    break
                end
            else
                table.remove(trashCanList, trashIndex)
                if trashIndex > #trashCanList then
                    trashIndex = 1
                end
            end
        end
    end
end



task.spawn(function()
    while true do
        task.wait(0.1) -- ทำให้เช็คบ่อยขึ้น
        if tp and selectedPlayerName then
            TeleportAndClick()
        end
    end
end)

end


-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
