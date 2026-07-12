local Player = game:GetService("Players").LocalPlayer
local Remote = game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent")

-- รอจนกว่าผู้ใช้งานจะโหลดค่าคอนฟิกเสร็จ
repeat task.wait() until getgenv().AutoFarmConfig
local Config = getgenv().AutoFarmConfig

-- ตั้งค่าตัวแปรหลัก
local FarmPos = Config.StandPosition
local EscapePos = FarmPos + Vector3.new(20, 0, 20)
local OriginalWaterInterval = Config.WaterInterval

-- ⏰ [ระบบตรวจจับกลางวัน-กลางคืน + บังคับล็อกพิกัดหนีไปนอกสวน]
task.spawn(function()
    local Lighting = game:GetService("Lighting")
    while task.wait() do
        pcall(function()
            local currentTime = Lighting.ClockTime
            local Character = Player.Character
            local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
            
            if currentTime >= 18 or currentTime < 6 then
                Config.WaterInterval = 99999
                if RootPart then
                    RootPart.CFrame = CFrame.new(EscapePos)
                    RootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            else
                if Config.WaterInterval == 99999 then
                    Config.WaterInterval = OriginalWaterInterval
                end
            end
        end)
    end
end)

-- ⚙️ [ระบบวางสปริงเกอร์เฉพาะตอนกลางวันครั้งแรกที่ถึงสวน]
task.spawn(function()
    local deployed = false
    while task.wait(1) do
        if deployed then task.wait(5) continue end
        
        pcall(function()
            local Lighting = game:GetService("Lighting")
            if Lighting.ClockTime < 18 and Lighting.ClockTime >= 6 then
                local Character = Player.Character
                local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                
                if RootPart then
                    local distance = (RootPart.Position - FarmPos).Magnitude
                    if distance <= 5 then
                        local backpack = Player:WaitForChild("Backpack")
                        local humanoid = Character:WaitForChild("Humanoid")
                        local sprinkler = backpack:FindFirstChild("Super Sprinkler") or Character:FindFirstChild("Super Sprinkler")
                        
                        if sprinkler then
                            Config.WaterInterval = 99999
                            task.wait(0.5)
                            
                            if sprinkler.Parent == backpack then humanoid:EquipTool(sprinkler) end
                            task.wait(0.3)
                            
                            local args = {
                                buffer.fromstring("\020\000$u\206Cd\193\014C\137A\198\193\015Super Sprinkler\002"),
                                { sprinkler }
                            }
                            Remote:FireServer(unpack(args))
                            print("[SYSTEM] ถึงสวนแล้ว! ปักสปริงเกอร์เรียบร้อย")
                            
                            task.wait(0.5)
                            Config.WaterInterval = OriginalWaterInterval
                            deployed = true
                        end
                    end
                end
            end
        end)
    end
end)

-- 🔄 [ระบบ Rejoin ย้ายเซิร์ฟเวอร์อัตโนมัติตามเวลาที่กำหนดไว้ข้างหน้า]
task.spawn(function()
    task.wait(Config.TotalDuration)
    
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local req = game:HttpGet(url)
        local servers = HttpService:JSONDecode(req)
        
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
                break
            end
        end
    end)
end)

-- 🚀 [ระบบ Rollback ที่คุณสั่งเพิ่ม ให้รันเป็นตัวปิดท้าย]
loadstring(game:HttpGet("https://gist.githubusercontent.com/Snowtmm/c4f4f21ce725632ad1992e307f97b766/raw/d3f9af952b2167c5eab9bbbefcdd6234998ad443/RollBackgag2.lua"))()
