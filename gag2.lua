-- ==========================================
-- [ โหลดการตั้งค่าจาก getgenv ]
-- ==========================================
local Config = getgenv().AutoFarmConfig or {
    TargetPlotID = 1,
    StandPosition = Vector3.new(440.9517517089844, 145.2554168701172, -28.30003929),
    ActionPosition = Vector3.new(433.0979309082031, 145.35540771484375, -18.096395),
    FlySpeed = 60,
    WaterInterval = 10,
    TotalDuration = 240
}

-- ==========================================
-- [ ตั้งค่า Services พื้นฐาน ]
-- ==========================================
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- ==========================================
-- 1. สคริปต์กดปุ่มตอนหน้าโหลดเกม
-- ==========================================
getgenv().autoPressKey = true
local stopAfterSeconds = 10

print("✅ เริ่มระบบกดปุ่ม L(K) อัตโนมัติ...")
task.delay(stopAfterSeconds, function()
    getgenv().autoPressKey = false
    print("🛑 สคริปต์ปุ่มกดหยุดทำงานแล้ว (ครบ " .. stopAfterSeconds .. " วินาที)")
end)

task.spawn(function()
    while getgenv().autoPressKey do
        task.wait(1) 
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.K, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.K, false, game)
    end
end)

-- ==========================================
-- 2. สคริปต์ลบต้นไม้ (รอโหลดเกม 4 วินาที)
-- ==========================================
task.spawn(function()
    print("⏳ กำลังรอ 8 วินาทีเพื่อโหลดต้นไม้...")
    task.wait(8)
    local gardensFolder = Workspace:FindFirstChild("Gardens")
    if gardensFolder then
        for _, plot in pairs(gardensFolder:GetChildren()) do
            local plantsFolder = plot:FindFirstChild("Plants")
            if plantsFolder then
                plantsFolder:ClearAllChildren()
                print("🗑️ ลบต้นไม้ใน " .. plot.Name .. " เรียบร้อยแล้ว")
            end
        end
    else
        print("❌ หาโฟลเดอร์ Gardens ไม่เจอตอนกำลังจะลบต้นไม้")
    end
end)

-- ==========================================
-- 3. สคริปต์ Rollback & UI
-- ==========================================
local SharedModules = ReplicatedStorage:WaitForChild("SharedModules")
local Packet = SharedModules:WaitForChild("Packet")
local RemoteEvent = Packet:WaitForChild("RemoteEvent")
local ranStatus = false

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Fluent " .. Fluent.Version,
    SubTitle = "by dawid",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

do
    local Status = Tabs.Main:AddParagraph({ Title = "Status : Off 🔴", })
    Tabs.Main:AddButton({
        Title = "Turn on",
        Description = "Turn on rollback for unsaved your data",
        Callback = function()
            if ranStatus then
                Fluent:Notify({ Title = "Alert", Content = "Rollback is already ON", Duration = 8 })
            else
                RemoteEvent:FireServer(buffer.fromstring("6\000\001\255"))
                ranStatus = true
                Status:SetTitle("Status : On 🟢")
            end
        end
    })
    Tabs.Main:AddButton({
        Title = "Turn off",
        Description = "Turn off rollback for save your data",
        Callback = function()
            for i = 1, 3 do
                RemoteEvent:FireServer(buffer.fromstring("6\000\000"))
                task.wait()
            end
            ranStatus = false
            Status:SetTitle("Status : Off 🔴")
        end
    })
    Tabs.Main:AddButton({
        Title = "Rejoin", Description = "Rejoin server",
        Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
    })
    if not ranStatus then
        RemoteEvent:FireServer(buffer.fromstring("6\000\001\255"))
        ranStatus = true
        Status:SetTitle("Status : On 🟢")
    end
end

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
Fluent:Notify({ Title = "Fluent", Content = "The script has been loaded & Rollback is ON.", Duration = 8 })
SaveManager:LoadAutoloadConfig()

-- ==========================================
-- 4. สคริปต์วางสปริงเกอร์และรดน้ำ (รอ 12 วินาที)
-- ==========================================
task.spawn(function()
    print("⏳ รอ 12 วินาทีก่อนเริ่มระบบฟาร์ม...")
    task.wait(12)
    print("🚀 เริ่มระบบวางสปริงเกอร์และรดน้ำ!")

    local TARGET_PLOT_ID = Config.TargetPlotID
    local Networking = require(SharedModules:WaitForChild("Networking"))
    local PacketRemote = RemoteEvent
    local WATERING_EVENT_ID = 67
    local isFlying = false

    -- ฟังก์ชันถือของ
    local function equipToolByName(toolName)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return nil end
        local containers = { character, LocalPlayer:FindFirstChild("Backpack") }
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and (string.find(string.lower(item.Name), string.lower(toolName), 1, true) or string.find(string.lower(tostring(item:GetAttribute("ItemName") or "")), string.lower(toolName), 1, true)) then
                        if item.Parent ~= character then
                            pcall(function() humanoid:EquipTool(item) end)
                            task.wait(0.1)
                        end
                        return item
                    end
                end
            end
        end
        return nil
    end

    -- 🔍 ฟังก์ชันเช็คว่ามีสปริงเกอร์อยู่ในโฟลเดอร์หรือไม่
    local function hasSprinklerAt(plot, position)
        local sprinklersFolder = plot and plot:FindFirstChild("Sprinklers")
        if not sprinklersFolder then return false end
        for _, child in ipairs(sprinklersFolder:GetChildren()) do
            local part = child:IsA("BasePart") and child or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
            if part and (part.Position - position).Magnitude <= 4 then return true end
        end
        return false
    end

    -- ฟังก์ชันบิน
    local function flyToPosition(targetPos)
        if isFlying then return end
        isFlying = true
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then isFlying = false return end
        local distance = (root.Position - targetPos).Magnitude
        if distance <= 3 then isFlying = false return end 
        local duration = distance / Config.FlySpeed
        print("[Auto Return] บินกลับจุดยืนทันที! ระยะทาง: " .. math.floor(distance) .. " studs")
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Parent = root
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
        local conn
        conn = char:WaitForChild("Humanoid").Died:Connect(function()
            tween:Cancel()
            bodyVelocity:Destroy()
            if conn then conn:Disconnect() end
        end)
        tween:Play()
        tween.Completed:Wait()
        if bodyVelocity.Parent then bodyVelocity:Destroy() end
        if conn then conn:Disconnect() end
        pcall(function() root.Velocity = Vector3.new(0,0,0) end)
        isFlying = false
    end

    -- บินไปจุดยืนเริ่มต้น
    flyToPosition(Config.StandPosition)
    task.wait(0.5)
    
    local gardens = Workspace:FindFirstChild("Gardens")
    local plot = gardens and gardens:FindFirstChild("Plot" .. tostring(TARGET_PLOT_ID))
    
    -- ลูปเช็คสถานะตัวละครกันตาย/กระเด็น
    task.spawn(function()
        while true do
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChild("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not char or not humanoid or humanoid.Health <= 0 or not root then
                LocalPlayer.CharacterAdded:Wait()
                task.wait(0.5)
                flyToPosition(Config.StandPosition)
            elseif (root.Position - Config.StandPosition).Magnitude > 8 and not isFlying then
                flyToPosition(Config.StandPosition)
            end
            task.wait(0.1)
        end
    end)
    
    print("[Auto Farm] เริ่มทำงาน! เช็คสปริงเกอร์และรดน้ำทุกๆ " .. Config.WaterInterval .. " วินาที...")
    local startTime = os.clock()
    
    -- 🔄 ลูปการทำงานหลัก (รดน้ำ + เช็คสปริงเกอร์)
    while (os.clock() - startTime) < Config.TotalDuration do
        
        -- 💡 1. เช็คสปริงเกอร์ตลอดเวลา ถ้าหายให้วางใหม่ทันที
        if plot then
            if not hasSprinklerAt(plot, Config.ActionPosition) then
                print("[Auto Farm] ตรวจพบว่าสปริงเกอร์หายไป! กำลังทำการวางใหม่...")
                local sprinklerTool = equipToolByName("Super Sprinkler")
                if sprinklerTool then
                    Networking.Place.PlaceSprinkler:Fire(Config.ActionPosition, "Super Sprinkler", sprinklerTool, TARGET_PLOT_ID)
                    task.wait(1) -- รอแป๊บนึงหลังวางเสร็จ
                end
            end
        end

        -- 💦 2. ถือบัวรดน้ำแล้วรด
        local wateringTool = equipToolByName("Super Watering Can")
        if wateringTool then
            pcall(function()
                local toolName = wateringTool.Name
                local b = buffer.create(15 + #toolName)
                buffer.writeu16(b, 0, WATERING_EVENT_ID)
                buffer.writef32(b, 2, Config.ActionPosition.X)
                buffer.writef32(b, 6, Config.ActionPosition.Y)
                buffer.writef32(b, 10, Config.ActionPosition.Z)
                buffer.writeu8(b, 14, #toolName)
                buffer.writestring(b, 15, toolName)
                PacketRemote:FireServer(b, { wateringTool })
            end)
        end
        
        -- รอเวลาตามรอบ
        task.wait(Config.WaterInterval)
    end
    
    print("[Auto Farm] ครบเวลาแล้ว! กำลังทำการ Rejoin เซิร์ฟเวอร์ใหม่...")
    task.wait(1)
    pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)
