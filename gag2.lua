-- ==========================================
-- [ แก้บั๊กค้าง 25% ] บังคับข้ามการรอ Assets
-- ==========================================
pcall(function()
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    ReplicatedFirst:RemoveDefaultLoadingScreen()
    
    -- บังคับปิด UI โหลดเกมให้เร็วที่สุด
    if game:IsLoaded() == false then
        game.Loaded:Wait()
    end
    
    local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and (gui.Name:lower():find("load") or gui.Name:lower():find("intro")) then
            gui:Destroy()
        end
    end
end)

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
local RunService = game:GetService("RunService")

-- จำรหัสเซิร์ฟเวอร์ปัจจุบันไว้ตั้งแต่ตอนเริ่มรันสคริปต์ เพื่อใช้ในการ Rejoin กลับห้องเดิม
local CurrentJobId = game.JobId

-- ==========================================
-- 🌀 [ระบบ ข้ามหน้าโหลดเกมอัตโนมัติ]
-- ==========================================
pcall(function()
    local ReplicatedFirst = game:GetService("ReplicatedFirst")
    ReplicatedFirst:RemoveDefaultLoadingScreen()
    
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local IntroGui = PlayerGui:FindFirstChild("IntroGui") or PlayerGui:FindFirstChild("LoadingGui")
    if IntroGui then IntroGui:Destroy() end
end)

-- ==========================================
-- 🧱 [ระบบ Noclip เดิน/บินทะลุกำแพงกันติดบั๊ก]
-- ==========================================
task.spawn(function()
    RunService.Stepped:Connect(function()
        pcall(function()
            if LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end)
end)

-- ==========================================
-- 🔍 [ฟังก์ชันช่วยแปลงและดักจับเวลาบนจอเกม]
-- ==========================================
local function GetInGameTime()
    local timeSeconds = 999 -- ค่าเริ่มต้นให้เป็นกลางวันไว้ก่อนหากหา UI ไม่เจอ
    pcall(function()
        local ScreenGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui") 
        local TimeLabel = ScreenGui and ScreenGui:FindFirstChild("TimeLabel") 
        
        if TimeLabel and TimeLabel.Text then
            local text = TimeLabel.Text
            local min, sec = text:match("(%d+):(%d+)")
            if min and sec then
                timeSeconds = (tonumber(min) * 60) + tonumber(sec)
            end
        end
    end)
    return timeSeconds
end

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
-- 2. เรียกใช้งานสคริปต์แยก (ซ่อนต้นไม้เพื่อลดแลค)
-- ==========================================
-- ดึงระบบซ่อนต้นไม้จากไฟล์แยกที่คุณสร้างไว้บน GitHub มาทำงานร่วมกันแบบสะอาดตา
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kdkddkod57-lab/auto-gag2/main/hideplants.lua"))()
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
    local Status = Tabs.Main:AddParagraph({ Title = "Status : Off 🔴" })
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
    
    -- 🛠️ แก้ไขปุ่มกดให้ Rejoin กลับมาเข้าเซิร์ฟเวอร์ห้องเดิม (Same Server)
    Tabs.Main:AddButton({
        Title = "Rejoin", 
        Description = "Rejoin to the SAME server",
        Callback = function() 
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, CurrentJobId, LocalPlayer) 
            end)
        end
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
    
    local OriginalWaterInterval = Config.WaterInterval
    local EscapePos = Config.StandPosition + Vector3.new(20, 0, 20)

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

    -- ฟังก์ชันเช็คสปริงเกอร์ในโฟลเดอร์
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

    -- ⏰ [ลูปตรวจสอบเวลาบนจอเพื่อจัดการวาร์ปหลบภัยกลางคืน]
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local totalSeconds = GetInGameTime()
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                
                -- เงื่อนไข: เวลาบนจอน้อยกว่าหรือเท่ากับ 2:30 (150 วิ) หรือช่วงฉุกเฉิน 0:30 (30 วิ)
                if totalSeconds <= 150 or totalSeconds <= 30 then
                    Config.WaterInterval = 99999 -- สั่งหยุดลูปการรดน้ำ
                    if root and not isFlying then
                        root.CFrame = CFrame.new(EscapePos)
                        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    end
                -- เงื่อนไขกลางวัน: เวลามากกว่าหรือเท่ากับ 7:30 (450 วิ)
                elseif totalSeconds >= 450 then
                    if Config.WaterInterval == 99999 then
                        Config.WaterInterval = OriginalWaterInterval -- ปลดล็อกเวลารดน้ำกลับมาปกติ
                    end
                end
            end)
        end
    end)

    -- เริ่มต้นบินไปจุดฟาร์ม
    local currentSec = GetInGameTime()
    if currentSec >= 450 then
        flyToPosition(Config.StandPosition)
    end
    task.wait(0.5)
    
    local gardens = Workspace:FindFirstChild("Gardens")
    local plot = gardens and gardens:FindFirstChild("Plot" .. tostring(TARGET_PLOT_ID))
    
    -- ลูปเช็คสถานะตัวละครกันตาย/กระเด็นหลุดตำแหน่ง (เฉพาะช่วงกลางวัน)
    task.spawn(function()
        while true do
            local totalSeconds = GetInGameTime()
            if totalSeconds >= 450 then 
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
            end
            task.wait(0.1)
        end
    end)
    
    print("[Auto Farm] เริ่มทำงานดักระบบเวลาจากบนหน้าจอแล้ว!")
    local startTime = os.clock()
    
    -- 🔄 ลูปการทำงานหลัก (รดน้ำ + เช็คสปริงเกอร์)
    while (os.clock() - startTime) < Config.TotalDuration do
        local totalSeconds = GetInGameTime()
        
        if totalSeconds >= 450 and Config.WaterInterval ~= 99999 then
            
            -- 💡 1. เช็คและปักสปริงเกอร์
            if plot then
                if not hasSprinklerAt(plot, Config.ActionPosition) then
                    print("[Auto Farm] ตรวจพบว่าสปริงเกอร์หายไป! กำลังทำการวางใหม่...")
                    local sprinklerTool = equipToolByName("Super Sprinkler")
                    if sprinklerTool then
                        Networking.Place.PlaceSprinkler:Fire(Config.ActionPosition, "Super Sprinkler", sprinklerTool, TARGET_PLOT_ID)
                        task.wait(1)
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
        end
        
        task.wait(Config.WaterInterval == 99999 and 1 or Config.WaterInterval)
    end
    
    -- 🔄 [ระบบ Rejoin อัตโนมัติเมื่อหมดเวลา - บังคับเข้าห้องเดิมเซิร์ฟเดิมเป๊ะๆ]
    print("[Auto Farm] ครบเวลาแล้ว! กำลังทำการ Rejoin กลับเข้าเซิร์ฟเวอร์เดิม...")
    task.wait(1)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, CurrentJobId, LocalPlayer)
    end)
end)
