local gui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton", gui)
btn.Size = UDim2.new(0, 50, 0, 50)
btn.Position = UDim2.new(0, 10, 0, 10) -- Góc trái, cách mép 10px
btn.BackgroundColor3 = Color3.fromRGB(10, 10, 50)
btn.BackgroundTransparency = 0.3
btn.BorderColor3 = Color3.fromRGB(0, 0, 0)
btn.BorderSizePixel = 1
btn.Text = "N"
btn.TextColor3 = Color3.fromRGB(88, 131, 202)
btn.TextScaled = true
btn.Font = Enum.Font.Garamond
btn.AutoButtonColor = false
btn.Active = true
btn.Draggable = true

Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

btn.MouseButton1Click:Connect(function()
	game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
	task.wait(0.1)
	game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
end)

local ContextActionService = game:GetService('ContextActionService')
local Phantom = false

local function BlockMovement(actionName, inputState, inputObject)
    return Enum.ContextActionResult.Sink
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local Players = game:GetService('Players')
local Player = Players.LocalPlayer


local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Tornado_Time = tick()

local UserInputService = game:GetService('UserInputService')
local Last_Input = UserInputService:GetLastInputType()

local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')

local Vector2_Mouse_Location = nil
local Grab_Parry = nil

local Remotes = {}
local Parry_Key = nil
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local firstParryFired = false
local ParryThreshold = 2.5
local firstParryType = 'F_Key'
local Previous_Positions = {}
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualInputService = game:GetService("VirtualInputManager")


local GuiService = game:GetService('GuiService')

local function updateNavigation(guiObject: GuiObject | nil)
    GuiService.SelectedObject = guiObject
end

local function performFirstPress(parryType)
    if parryType == 'F_Key' then
        VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
    elseif parryType == 'Left_Click' then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    elseif parryType == 'Navigation' then
        local button = Players.LocalPlayer.PlayerGui.Hotbar.Block
        updateNavigation(button)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.01)
        updateNavigation(nil)
    end
end

if not LPH_OBFUSCATED then
    function LPH_JIT(Function) return Function end
    function LPH_JIT_MAX(Function) return Function end
    function LPH_NO_VIRTUALIZE(Function) return Function end
end

local PropertyChangeOrder = {}

local HashOne
local HashTwo
local HashThree

LPH_NO_VIRTUALIZE(function()
    for Index, Value in next, getgc() do
        if rawequal(typeof(Value), "function") and islclosure(Value) and getrenv().debug.info(Value, "s"):find("SwordsController") then
            if rawequal(getrenv().debug.info(Value, "l"), 276) then
                HashOne = getconstant(Value, 62)
                HashTwo = getconstant(Value, 64)
                HashThree = getconstant(Value, 65)
            end
        end 
    end
end)()


LPH_NO_VIRTUALIZE(function()
    for Index, Object in next, game:GetDescendants() do
        if Object:IsA("RemoteEvent") and string.find(Object.Name, "\n") then
            Object.Changed:Once(function()
                table.insert(PropertyChangeOrder, Object)
            end)
        end
    end
end)()


repeat
    task.wait()
until #PropertyChangeOrder == 3


local ShouldPlayerJump = PropertyChangeOrder[1]
local MainRemote = PropertyChangeOrder[2]
local GetOpponentPosition = PropertyChangeOrder[3]

local Parry_Key

for Index, Value in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
    if Value and Value.Function and not iscclosure(Value.Function)  then
        for Index2,Value2 in pairs(getupvalues(Value.Function)) do
            if type(Value2) == "function" then
                Parry_Key = getupvalue(getupvalue(Value2, 2), 17);
            end;
        end;
    end;
end;

local function Parry(...)
    ShouldPlayerJump:FireServer(HashOne, Parry_Key, ...)
    MainRemote:FireServer(HashTwo, Parry_Key, ...)
    GetOpponentPosition:FireServer(HashThree, Parry_Key, ...)
end

local Parries = 0

function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)

    animation:Play()
    task.wait(info.Time)

    Debris:AddItem(animation, 0)

    animation:Destroy()
    animation = nil
end

local Animation = {}
Animation.storage = {}

Animation.current = nil
Animation.track = nil

for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end

local Emotes_Data = {}

for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end

table.sort(Emotes_Data)

local Auto_Parry = {}

function Auto_Parry.Parry_Animation()
    local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local Current_Sword = Player.Character:GetAttribute('CurrentlyEquippedSword')

    if not Current_Sword then
        return
    end

    if not Parry_Animation then
        return
    end

    local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)

    if not Sword_Data or not Sword_Data['AnimationType'] then
        return
    end

    for _, object in pairs(game:GetService('ReplicatedStorage').Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local sword_animation_type = 'GrabParry'

                if object:FindFirstChild('Grab') then
                    sword_animation_type = 'Grab'
                end

                Parry_Animation = object[sword_animation_type]
            end
        end
    end

    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]

    if not Animations then
        return false
    end

    local Animator = Player.Character.Humanoid.Animator

    if Animation.track then
        Animation.track:Stop()
    end

    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()

    Animation.current = v
end

function Auto_Parry.Get_Balls()
    local Balls = {}

    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            table.insert(Balls, Instance)
        end
    end
    return Balls
end

function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            return Instance
        end
    end
end

function Auto_Parry.Lobby_Balls()
    for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            return Instance
        end
    end
end


local Closest_Entity = nil

function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge
    local Found_Entity = nil
    
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) then
            if Entity.PrimaryPart then  -- Check if PrimaryPart exists
                local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
                if Distance < Max_Distance then
                    Max_Distance = Distance
                    Found_Entity = Entity
                end
            end
        end
    end
    
    Closest_Entity = Found_Entity
    return Found_Entity
end

function Auto_Parry:Get_Entity_Properties()
    Auto_Parry.Closest_Player()

    if not Closest_Entity then
        return false
    end

    local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
    local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude

    return {
        Velocity = Entity_Velocity,
        Direction = Entity_Direction,
        Distance = Entity_Distance
    }
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled


function Auto_Parry.Parry_Data(Parry_Type)
    Auto_Parry.Closest_Player()
    
    local Events = {}
    local Camera = workspace.CurrentCamera
    local Vector2_Mouse_Location
    
    if Last_Input == Enum.UserInputType.MouseButton1 or (Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard) then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    if isMobile then
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    local Players_Screen_Positions = {}
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character then
            local worldPos = v.PrimaryPart.Position
            local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
            
            if isOnScreen then
                Players_Screen_Positions[v] = Vector2.new(screenPos.X, screenPos.Y)
            end
            
            Events[tostring(v)] = screenPos
        end
    end
    
    if Parry_Type == 'Camera' then
        return {0, Camera.CFrame, Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Backwards' then
        local Backwards_Direction = Camera.CFrame.LookVector * -10000
        Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z)
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'Straight' then
        local Aimed_Player = nil
        local Closest_Distance = math.huge
        local Mouse_Vector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])
        
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character then
                local worldPos = v.PrimaryPart.Position
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (Mouse_Vector - playerScreenPos).Magnitude
                    
                    if distance < Closest_Distance then
                        Closest_Distance = distance
                        Aimed_Player = v
                    end
                end
            end
        end
        
        if Aimed_Player then
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Aimed_Player.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        else
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        end
    end
    
    if Parry_Type == 'Random' then
        return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'High' then
        local High_Direction = Camera.CFrame.UpVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Left' then
        local Left_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Right' then
        local Right_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'RandomTarget' then
        local candidates = {}
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                if isOnScreen then
                    table.insert(candidates, {
                        character = v,
                        screenXY  = { screenPos.X, screenPos.Y }
                    })
                end
            end
        end
        if #candidates > 0 then
            local pick = candidates[ math.random(1, #candidates) ]
            local lookCFrame = CFrame.new(Player.Character.PrimaryPart.Position, pick.character.PrimaryPart.Position)
            return {0, lookCFrame, Events, pick.screenXY}
        else
            return {0, Camera.CFrame, Events, { Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2 }}
        end
    end
    
    return Parry_Type
end

function Auto_Parry.Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)

    if not firstParryFired then
        performFirstPress(firstParryType)
        firstParryFired = true
    else
        Parry(Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4])
    end

    if Parries > 7 then
        return false
    end

    Parries += 1

    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end

local Lerp_Radians = 0
local Last_Warping = tick()

function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local Previous_Velocity = {}
local Curving = tick()

local Runtime = workspace.Runtime


function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return false
    end

    local Zoomies = Ball:FindFirstChild('zoomies')

    if not Zoomies then
        return false
    end

    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Speed = Velocity.Magnitude
    local Speed_Threshold = math.min(Speed / 100, 40)

    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)

    local Dot_Difference = Dot - Direction_Similarity
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude

    local Pings = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

    local Dot_Threshold = 0.5 - (Pings / 1000)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold

    local Clamped_Dot = math.clamp(Dot, -1, 1)
    local Radians = math.rad(math.asin(Clamped_Dot))

    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)

    if Speed > 100 and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    if Distance < Ball_Distance_Threshold then
        return false
    end

    if Dot_Difference < Dot_Threshold then
        return true
    end

    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end

    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end

    if (tick() - Curving) < (Reach_Time / 1.5) then
        return true
    end

    return Dot < Dot_Threshold
end

function Auto_Parry:Get_Ball_Properties()
    local Ball = Auto_Parry.Get_Ball()

    local Ball_Velocity = Vector3.zero
    local Ball_Origin = Ball

    local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
    local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)

    return {
        Velocity = Ball_Velocity,
        Direction = Ball_Direction,
        Distance = Ball_Distance,
        Dot = Ball_Dot
    }
end

function Auto_Parry.Spam_Service(self)
    local Ball = Auto_Parry.Get_Ball()

    local Entity = Auto_Parry.Closest_Player()

    if not Ball then
        return false
    end

    if not Entity or not Entity.PrimaryPart then
        return false
    end

    local Spam_Accuracy = 0

    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)

    local Target_Position = Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6, 95)

    if self.Entity_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if self.Ball_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if Target_Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed

    Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot

    return Spam_Accuracy
end

local Connections_Manager = {}
local Selected_Parry_Type = "Camera"

local Infinity = false

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    if b then
        Infinity = true
    else
        Infinity = false
    end
end)

local Parried = false
local Last_Parry = 0


local AutoParry = true

local Balls = workspace:WaitForChild('Balls')
local CurrentBall = nil
local InputTask = nil
local Cooldown = 0.02
local RunTime = workspace:FindFirstChild("Runtime")



local function GetBall()
    for _, Ball in ipairs(Balls:GetChildren()) do
        if Ball:FindFirstChild("ff") then
            return Ball
        end
    end
    return nil
end

local function SpamInput(Label)
    if InputTask then return end
    InputTask = task.spawn(function()
        while AutoParry do
            Auto_Parry.Parry(Selected_Parry_Type)
            task.wait(Cooldown)
        end
        InputTask = nil
    end)
end

Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == 'ComboCounter' then
            local Sof_Label = Child:FindFirstChildOfClass('TextLabel')

            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)

                    if Slashes_Counter and Slashes_Counter < 32 then
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end

                    task.wait()

                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)

local player10239123 = Players.LocalPlayer

RunTime.ChildAdded:Connect(function(Object)
    local Name = Object.Name
    if getgenv().PhantomV2Detection then
        if Name == "maxTransmission" or Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = player10239123.Character or player10239123.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    CurrentBall = GetBall()
                    Weld:Destroy()
    
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
    
                            if Highlighted == true then
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
    
                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    local PlayerPosition = HumanoidRootPart.Position
                                    local BallPosition = CurrentBall.Position
                                    local PlayerToBall = (BallPosition - PlayerPosition).Unit
    
                                    game.Players.LocalPlayer.Character.Humanoid:Move(PlayerToBall, false)
                                end
    
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
    
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 10
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
    
                                task.delay(3, function()
                                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                end)
    
                                CurrentBall = nil
                            end
                        end)
    
                        task.delay(3, function()
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
    
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                CurrentBall = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end)

local player11 = game.Players.LocalPlayer
local PlayerGui = player11:WaitForChild("PlayerGui")
local playerGui = player11:WaitForChild("PlayerGui")
local Hotbar = PlayerGui:WaitForChild("Hotbar")


local ParryCD = playerGui.Hotbar.Block.UIGradient
local AbilityCD = playerGui.Hotbar.Ability.UIGradient

local function isCooldownInEffect1(uigradient)
    return uigradient.Offset.Y < 0.4
end

local function isCooldownInEffect2(uigradient)
    return uigradient.Offset.Y == 0.5
end

local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) then
        game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

local function AutoAbility()
    if isCooldownInEffect2(AbilityCD) then
        if Player.Character.Abilities["Raging Deflection"].Enabled or Player.Character.Abilities["Rapture"].Enabled or Player.Character.Abilities["Calming Deflection"].Enabled or Player.Character.Abilities["Aerodynamic Slash"].Enabled or Player.Character.Abilities["Fracture"].Enabled or Player.Character.Abilities["Death Slash"].Enabled then
            Parried = true
            game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
            task.wait(2.432)
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            return true
        end
    end
    return false
end

local Airflow = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/KingScript663/AirFlow/refs/heads/main/source.luau"))();

local Window = Airflow:Init({
	Name = "Nature",
	Keybind = "LeftControl",
	Logo = "",
});

-- Tab
local Blatant = Window:DrawTab({
	Name = "Blatant",
	Icon = "sword"
})

local Detection= Window:DrawTab({
	Name = "Detections",
	Icon = "layers"
})

local play = Window:DrawTab({
	Name = "Player",
	Icon = "user"
})

local visu = Window:DrawTab({
	Name = "Visuals",
	Icon = "eye"
})

local m = Window:DrawTab({
	Name = "Misc",
	Icon = "layers"
})

-- Toggle 
local mold = Blatant:AddSection({
	Name = "Auto Parry",
	Position = "left",
});

local parry = mold:AddToggle({
	Name = "Auto Parry",
	Callback = function(value)
        if value then
            Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()

                for _, Ball in pairs(Balls) do

                    if not Ball then
                        return
                    end

                    local Zoomies = Ball:FindFirstChild('zoomies')
                    if not Zoomies then
                        return
                    end

                    Ball:GetAttributeChangedSignal('target'):Once(function()
                        Parried = false
                    end)

                    if Parried then
                        return
                    end

                    local Ball_Target = Ball:GetAttribute('target')
                    local One_Target = One_Ball:GetAttribute('target')

                    local Velocity = Zoomies.VectorVelocity

                    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude

                    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

                    local Ping_Threshold = math.clamp(Ping / 10, 18.5, 70)

                    local Speed = Velocity.Magnitude

                    local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                    local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002

                    local effectiveMultiplier = Speed_Divisor_Multiplier
                    if getgenv().RandomParryAccuracyEnabled then
                        if Speed < 200 then
                            effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                        else
                            effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                        end
                    end

                    local speed_divisor = speed_divisor_base * effectiveMultiplier
                    local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5)

                    local Curved = Auto_Parry.Is_Curved()


                    if Phantom and Player.Character:FindFirstChild('ParryHighlight') and getgenv().PhantomV2Detection then
                    --Controls:Disable()

                ContextActionService:BindAction('BlockPlayerMovement', BlockMovement, false, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.UserInputType.Touch)

                    Player.Character.Humanoid.WalkSpeed = 36
                    Player.Character.Humanoid:MoveTo(Ball.Position)

                    task.spawn(function()
                        repeat
                            if Player.Character.Humanoid.WalkSpeed ~= 36 then
                                Player.Character.Humanoid.WalkSpeed = 36
                            end

                            task.wait()

                        until not Phantom
                    end)

                    Ball:GetAttributeChangedSignal('target'):Once(function()
                        --Controls:Enable()

                        ContextActionService:UnbindAction('BlockPlayerMovement')
                        Phantom = false

                        Player.Character.Humanoid:MoveTo(Player.Character.HumanoidRootPart.Position)
                        Player.Character.Humanoid.WalkSpeed = 10

                        task.delay(3, function()
                            Player.Character.Humanoid.WalkSpeed = 36
                        end)
                    end)
                end

                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy and Phantom then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)

                    Parried = true
                end

                    if Ball:FindFirstChild('AeroDynamicSlashVFX') then
                        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                        Tornado_Time = tick()
                    end

                    if Runtime:FindFirstChild('Tornado') then
                        if (tick() - Tornado_Time) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
                        return
                        end
                    end

                    if One_Target == tostring(Player) and Curved then
                        return
                    end

                    if Ball:FindFirstChild("ComboCounter") then
                        return
                    end

                    local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild('SingularityCape')
                    if Singularity_Cape then
                        return
                    end 

                    if getgenv().InfinityDetection and Infinity then
                        return
                    end

                    if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                        if getgenv().AutoAbility and AutoAbility() then
                            return
                        end
                    end

                    if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                        if getgenv().CooldownProtection and cooldownProtection() then
                            return
                        end

                        local Parry_Time = os.clock()
                        local Time_View = Parry_Time - (Last_Parry)
                        if Time_View > 0.5 then
                            Auto_Parry.Parry_Animation()
                        end

                        if getgenv().AutoParryKeypress then
                            VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
                        else
                            Auto_Parry.Parry(Selected_Parry_Type)
                        end

                        Last_Parry = Parry_Time
                        Parried = true
                    end
                    local Last_Parrys = tick()
                    repeat
                        RunService.PreSimulation:Wait()
                    until (tick() - Last_Parrys) >= 1 or not Parried
                    Parried = false
                end
            end)
        else
            if Connections_Manager['Auto Parry'] then
                Connections_Manager['Auto Parry']:Disconnect()
                Connections_Manager['Auto Parry'] = nil
            end
        end
    end
})

local parryTypeMap = {
    ["Camera"] = "Camera",
    ["Random"] = "Random",
    ["Backwards"] = "Backwards",
    ["Straight"] = "Straight",
    ["High"] = "High",
    ["Left"] = "Left",
    ["Right"] = "Right",
    ["Random Target"] = "RandomTarget"
}

parry:AutomaticVisible({
	Target = true,
	Elements = {
		mold:AddDropdown({
	Name = "First Parry Type",
	Values = {
        'F_Key',
        'Left_Click',
        'Navigation'
    },
	Multi = false,
	Default = "F_Key",
	Callback = function(value)
	       FirstParryType = value
    end
    }),
    mold:AddDropdown({
	Name = "Curve Type",
	Values = {
        "Camera",
        "Random",
        "Backwards",
        'Straight',
        'High',
        'Left',
        'Right',
        'Random Target'
    },
	Multi = false,
	Default = "Camera",
	Callback = function(value)
        Selected_Parry_Type = parryTypeMap[value] or value
    end
}),
mold:AddSlider({
	Name = "Parry Accuracy",
	Min = 1,
	Max = 100,
	Default = 100, -- optional, defaults to Min if not set
	Callback = function(value)
		Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99)
	end
	}),
	mold:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
	mold:AddToggle({
	Name = "Randomized Parry Accuracy",
	Callback = function(value) 
        getgenv().RandomParryAccuracyEnabled = value      
    end
    }),
    mold:AddToggle({
	Name = "Auto Ability",
	Callback = function(value)       
    end
    }),
    mold:AddToggle({
	Name = "Keypress",
	Callback = function(value)
        getgenv().AutoParryKeypress = value
    end
    }),
    mold:AddToggle({
	Name = "Notify",
	Callback = function(value)       
    end
		})
	}
})

local Triggerbot = Blatant:AddSection({
	Name = "Triggerbot",
	Position = "left",
});

local Trigger = Triggerbot:AddToggle({
    Name = "Triggerbot",
    Callback = function(value)
        if value then
            Connections_Manager['Triggerbot'] = RunService.PreSimulation:Connect(function()
                local Balls = Auto_Parry.Get_Balls()
    
                for _, Ball in pairs(Balls) do
                    if not Ball then
                        return
                    end
                    
                    Ball:GetAttributeChangedSignal('target'):Once(function()
                        TriggerbotParried = false
                    end)

                    if TriggerbotParried then
                        return
                    end

                    local Ball_Target = Ball:GetAttribute('target')
                    local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild('SingularityCape')
        
                    if Singularity_Cape then 
                        return
                    end 
                
                    if getgenv().TriggerbotInfinityDetection and Infinity then
                        return
                    end
    
                    if Ball_Target == tostring(Player) then
                        if getgenv().TriggerbotKeypress then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                        else
                            Auto_Parry.Parry(Selected_Parry_Type)
                        end
                        TriggerbotParried = true
                    end
                    local Triggerbot_Last_Parrys = tick()
                    repeat
                        RunService.PreSimulation:Wait()
                    until (tick() - Triggerbot_Last_Parrys) >= 1 or not TriggerbotParried
                    TriggerbotParried = false
                end

            end)
        else
            if Connections_Manager['Triggerbot'] then
                Connections_Manager['Triggerbot']:Disconnect()
                Connections_Manager['Triggerbot'] = nil
            end
        end
    end
})

Trigger:AutomaticVisible({
	Target = true,
	Elements = {
	    Triggerbot:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
Triggerbot:AddToggle({
    Name = "Keypress",
    Callback = function(value)
        getgenv().TriggerbotKeypress = value
    end
}),
Triggerbot:AddToggle({
    Name = "Notify",
    Callback = function(value)
    end
		})
	}
})

local spam = Blatant:AddSection({
	Name = "Auto Spam Parry",
	Position = "right",
});

local spa = spam:AddToggle({
	Name = "Auto Spam Parry",
	Callback = function(value)
        if value then
            Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
                local Ball = Auto_Parry.Get_Ball()

                if not Ball then
                    return
                end

                local Zoomies = Ball:FindFirstChild('zoomies')

                if not Zoomies then
                    return
                end

                Auto_Parry.Closest_Player()

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

                local Ping_Threshold = math.clamp(Ping / 10, 18.5, 70)

                local Ball_Target = Ball:GetAttribute('target')

                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                local Entity_Properties = Auto_Parry:Get_Entity_Properties()

                local Spam_Accuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = Ball_Properties,
                    Entity_Properties = Entity_Properties,
                    Ping = Ping_Threshold
                })

                local Target_Position = Closest_Entity.PrimaryPart.Position
                local Target_Distance = Player:DistanceFromCharacter(Target_Position)

                local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                local Ball_Direction = Zoomies.VectorVelocity.Unit

                local Dot = Direction:Dot(Ball_Direction)

                local Distance = Player:DistanceFromCharacter(Ball.Position)

                if not Ball_Target then
                    return
                end

                if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                    return
                end
                
                local Pulsed = Player.Character:GetAttribute('Pulsed')

                if Pulsed then
                    return
                end

                if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                    return
                end

                local threshold = ParryThreshold

                if Distance <= Spam_Accuracy and Parries > threshold then
                    if getgenv().SpamParryKeypress then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                    else
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
                end
            end)
        else
            if Connections_Manager['Auto Spam'] then
                Connections_Manager['Auto Spam']:Disconnect()
                Connections_Manager['Auto Spam'] = nil
            end
        end
    end
})

spa:AutomaticVisible({
	Target = true,
	Elements = {
	    spam:AddDropdown({
	Name = "Parry Type",
	Values = {
        'Legit',
        'Blatant'
    },
	Multi = false,
	Default = "Legit",
	Callback = function(value)
    end
}),
spam:AddParagraph({
	Name = "Recommended:",
	Content = "Parry Type: Blatant"
}),
spam:AddSlider({
	Name = "Parry Threshold",
	Min = 1,
	Max = 3,
	Default = 1, -- optional, defaults to Min if not set
	Callback = function(value)
		ParryThreshold = value
	end
}),
spam:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
spam:AddToggle({
        Name = "Animation Fix",
        Callback = function(value)
            if value then
                Connections_Manager['Animation Fix'] = RunService.PreSimulation:Connect(function()
                    local Ball = Auto_Parry.Get_Ball()

                    if not Ball then
                        return
                    end

                    local Zoomies = Ball:FindFirstChild('zoomies')

                    if not Zoomies then
                        return
                    end

                    Auto_Parry.Closest_Player()

                    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

                    local Ping_Threshold = math.clamp(Ping / 10, 10, 16)

                    local Ball_Target = Ball:GetAttribute('target')

                    local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                    local Entity_Properties = Auto_Parry:Get_Entity_Properties()

                    local Spam_Accuracy = Auto_Parry.Spam_Service({
                        Ball_Properties = Ball_Properties,
                        Entity_Properties = Entity_Properties,
                        Ping = Ping_Threshold
                    })

                    local Target_Position = Closest_Entity.PrimaryPart.Position
                    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

                    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                    local Ball_Direction = Zoomies.VectorVelocity.Unit

                    local Dot = Direction:Dot(Ball_Direction)

                    local Distance = Player:DistanceFromCharacter(Ball.Position)

                    if not Ball_Target then
                        return
                    end

                    if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                        return
                    end
                    
                    local Pulsed = Player.Character:GetAttribute('Pulsed')

                    if Pulsed then
                        return
                    end

                    if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                        return
                    end

                    local threshold = ParryThreshold

                    if Distance <= Spam_Accuracy and Parries > threshold then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                    end
                end)
            else
                if Connections_Manager['Animation Fix'] then
                    Connections_Manager['Animation Fix']:Disconnect()
                    Connections_Manager['Animation Fix'] = nil
                end
            end
        end
    }),
spam:AddToggle({
    Name = "Keypress",
    Callback = function(value)
        getgenv().SpamParryKeypress = value
    end
}),
spam:AddToggle({
    Name = "Notify",
    Callback = function(value)
    end
		})
	}
})

local ManualSpam= Blatant:AddSection({
	Name = "Manual Spam Parry",
	Position = "right",
});

local mspa = ManualSpam:AddToggle({
	Name = "Manual Spam Parry",
	Callback = function(value)
        getgenv().spamui = value

        if value then
            local gui = Instance.new("ScreenGui")
            gui.Name = "ManualSpamUI"
            gui.ResetOnSpawn = false
            gui.Parent = game.CoreGui

            local frame = Instance.new("Frame")
            frame.Name = "MainFrame"
            frame.Position = UDim2.new(0, 20, 0, 20)
            frame.Size = UDim2.new(0, 200, 0, 100)
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 50)
            frame.BackgroundTransparency = 0.3
            frame.BorderSizePixel = 0
            frame.Active = true
            frame.Draggable = true
            frame.Parent = gui

            local uiCorner = Instance.new("UICorner")
            uiCorner.CornerRadius = UDim.new(0, 12)
            uiCorner.Parent = frame

            local uiStroke = Instance.new("UIStroke")
            uiStroke.Thickness = 2
            uiStroke.Color = Color3.new(0, 0, 0)
            uiStroke.Parent = frame

            local button = Instance.new("TextButton")
            button.Name = "ClashModeButton"
            button.Text = "🌿Nature Clash Mode"
            button.Size = UDim2.new(0, 160, 0, 40)
            button.Position = UDim2.new(0.5, -80, 0.5, -20)
            button.BackgroundTransparency = 1
            button.BorderSizePixel = 0
            button.Font = Enum.Font.GothamSemibold
            button.TextColor3 = Color3.new(1, 1, 1)
            button.TextSize = 22
            button.Parent = frame

            local activated = false

            local function toggle()
                activated = not activated
                button.Text = activated and "Stop" or "Clash Mode"
                if activated then
                    Connections_Manager['Manual Spam UI'] = game:GetService("RunService").RenderStepped:Connect(function()
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end)
                else
                    if Connections_Manager['Manual Spam UI'] then
                        Connections_Manager['Manual Spam UI']:Disconnect()
                        Connections_Manager['Manual Spam UI'] = nil
                    end
                end
            end

            button.MouseButton1Click:Connect(toggle)
        else
            if game.CoreGui:FindFirstChild("ManualSpamUI") then
                game.CoreGui:FindFirstChild("ManualSpamUI"):Destroy()
            end

            if Connections_Manager['Manual Spam UI'] then
                Connections_Manager['Manual Spam UI']:Disconnect()
                Connections_Manager['Manual Spam UI'] = nil
            end
        end
    end
    })
    
mspa:AutomaticVisible({
	Target = true,
	Elements = {
	    ManualSpam:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
ManualSpam:AddToggle({
    Name = "Keypress",
    Callback = function(value)
        getgenv().ManualSpamKeypress = value
    end
}),
ManualSpam:AddToggle({
    Name = "Notify",
    Callback = function(value)
    end
		})
	}
})

-- Ability Detection Position
local detect = Detection:AddSection({
	Name = "Ability Detection",
	Position = "left",
});

local detec = Detection:AddSection({
	Name = "Ability Detection",
	Position = "right",
});

local dete = Detection:AddSection({
	Name = "Personal Detector",
	Position = "left",
});
-- Ability Detection [left]
detect:AddToggle({
	Name = "Global Phantom Detection",
	Callback = function(value)   
           PhantomV2Detection = value 
    end
})

detect:AddToggle({
	Name = "Global Pulse Detection",
	Callback = function(value)     
    end
})

detect:AddToggle({
	Name = "Global Death Slash Detection",
	Callback = function(value)     
    end
})

detect:AddToggle({
	Name = "Global Slash Of Fury Detection",
	Callback = function(value)     
    end
})

detect:AddToggle({
	Name = "Global Aerodynamic Slash Detection",
	Callback = function(value)     
    end
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character, HumanoidRootPart

local MIN_DISTANCE = 20
local DetectorEnabled = false  -- Trạng thái toggle

-- Cập nhật nhân vật
local function updateCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end

updateCharacter()
LocalPlayer.CharacterAdded:Connect(updateCharacter)

-- Luồng phát hiện khoảng cách
RunService.RenderStepped:Connect(function()
    if not DetectorEnabled then return end
    if not HumanoidRootPart then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local otherHRP = player.Character.HumanoidRootPart
            local distance = (HumanoidRootPart.Position - otherHRP.Position).Magnitude

            if distance < MIN_DISTANCE then
                local pushDir = (HumanoidRootPart.Position - otherHRP.Position).Unit
                HumanoidRootPart.Velocity = pushDir * 50
            end
        end
    end
end)

-- Toggle GUI
dete:AddToggle({
	Name = "Personal Detector",
	Callback = function(value)
		DetectorEnabled = value
	end
})
-- Ability Detection [right]
detec:AddToggle({
	Name = "Global Hellhook Detection",
	Callback = function(value)     
    end
})

detec:AddToggle({
	Name = "Global Infinity Detection",
	Callback = function(value)     
	    getgenv().InfinityDetection = value
    end
})

detec:AddToggle({
	Name = "Global Time Hole Detection",
	Callback = function(value)     
    end
})

detec:AddToggle({
	Name = "Global Singularity Detection",
	Callback = function(value)     
    end
})

detec:AddToggle({
	Name = "Global Telekinesis Detection",
	Callback = function(value)     
    end
})

-- Lobby AP
local LobbyAP = Blatant:AddSection({
	Name = "Lobby AP",
	Position = "right",
});

local lobby = LobbyAP:AddToggle({
    Name = "Lobby AP",
    Callback = function(value)
        if value then
            Connections_Manager['Lobby AP'] = RunService.Heartbeat:Connect(function()
                local Ball = Auto_Parry.Lobby_Balls()
                if not Ball then
                    return
                end

                local Zoomies = Ball:FindFirstChild('zoomies')
                if not Zoomies then
                    return
                end

                Ball:GetAttributeChangedSignal('target'):Once(function()
                    Training_Parried = false
                end)

                if Training_Parried then
                    return
                end

                local Ball_Target = Ball:GetAttribute('target')
                local Velocity = Zoomies.VectorVelocity
                local Distance = Player:DistanceFromCharacter(Ball.Position)
                local Speed = Velocity.Magnitude

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
                local LobbyAPcappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                local LobbyAPspeed_divisor_base = 2.4 + LobbyAPcappedSpeedDiff * 0.002

                local LobbyAPeffectiveMultiplier = LobbyAP_Speed_Divisor_Multiplier
                if getgenv().LobbyAPRandomParryAccuracyEnabled then
                    LobbyAPeffectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                end

                local LobbyAPspeed_divisor = LobbyAPspeed_divisor_base * LobbyAPeffectiveMultiplier
                local LobbyAPParry_Accuracys = Ping + math.max(Speed / LobbyAPspeed_divisor, 9.5)

                if Ball_Target == tostring(Player) and Distance <= LobbyAPParry_Accuracys then
                    if getgenv().LobbyAPKeypress then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                    else
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end
                    Training_Parried = true
                end
                local Last_Parrys = tick()
                repeat 
                    RunService.PreSimulation:Wait() 
                until (tick() - Last_Parrys) >= 1 or not Training_Parried
                Training_Parried = false
            end)
        else
            if Connections_Manager['Lobby AP'] then
                Connections_Manager['Lobby AP']:Disconnect()
                Connections_Manager['Lobby AP'] = nil
            end
        end
    end
})

lobby:AutomaticVisible({
	Target = true,
	Elements = {
	    LobbyAP:AddSlider({
	Name = "Parry Accuracy",
	Min = 1,
	Max = 100,
	Default = 55,
	Callback = function(value)
		LobbyAP_Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99)
	end
}),
LobbyAP:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
LobbyAP:AddToggle({
    Name = "Keypress",
    Callback = function(value)
        getgenv().LobbyAPKeypress = value
    end
}),
LobbyAP:AddToggle({
    Name = "Notify",
    Callback = function(value)
    end
		})
	}
})

local tp = Blatant:AddSection({
	Name = "Ball Teleportation",
	Position = "left",
});

local lastTargetBall = nil
local tpConnection = nil

tp:AddToggle({
	Name = "Instant Ball TP",
	Callback = function(value)
		if value then
			tpConnection = RunService.RenderStepped:Connect(function()
				local function GetBall()
					for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
						if Ball:GetAttribute("realBall") then
							return Ball
						end
					end
				end

				local lp = Players.LocalPlayer
				local char = lp.Character or lp.CharacterAdded:Wait()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp then return end

				local ball = GetBall()
				if not ball then return end

				local target = ball:GetAttribute("target")
				if target == lp.Name and lastTargetBall ~= ball then
					-- TP một lần duy nhất mỗi khi bị target
					local dir = (ball.Position - hrp.Position).Unit
					local tpPos = ball.Position - dir * 15
					hrp.CFrame = CFrame.new(tpPos)
					lastTargetBall = ball
				elseif target ~= lp.Name then
					lastTargetBall = nil
				end
			end)
		else
			if tpConnection then
				tpConnection:Disconnect()
				tpConnection = nil
			end
			lastTargetBall = nil
		end
	end
})

local Strafe = play:AddSection({
	Name = "Speed", 
	Position = "left",
});

local speed = Strafe:AddToggle({
    Name = "Speed",
    Callback = function(value)
        if value then
            Connections_Manager['Strafe'] = game:GetService("RunService").PreSimulation:Connect(function()
                local character = game.Players.LocalPlayer.Character
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid.WalkSpeed = StrafeSpeed
                end
            end)
        else
            local character = game.Players.LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = 36
            end
            
            if Connections_Manager['Strafe'] then
                Connections_Manager['Strafe']:Disconnect()
                Connections_Manager['Strafe'] = nil
            end
        end
    end
})

speed:AutomaticVisible({
	Target = true,
	Elements = {
        Strafe:AddSlider({
	Name = "Strafe Speed",
    Min = 36,
	Max = 350,
	Default = 36,
	Callback = function(value)
        StrafeSpeed = value
    end
		})
	}
})

local Spinbot = play:AddSection({
	Name = "Spinbot",
	Position = "right",
});

local spin = Spinbot:AddToggle({
    Name = "Spinbot",
    Callback = function(value)
        getgenv().Spinbot = value
        if value then
            getgenv().spin = true
            getgenv().spinSpeed = getgenv().spinSpeed or 1 
            local Players = game:GetService("Players")
            local RunService = game:GetService("RunService")
            local Client = Players.LocalPlayer

            
            local function spinCharacter()
                while getgenv().spin do
                    RunService.Heartbeat:Wait()
                    local char = Client.Character
                    local funcHRP = char and char:FindFirstChild("HumanoidRootPart")
                    
                    if char and funcHRP then
                        funcHRP.CFrame *= CFrame.Angles(0, getgenv().spinSpeed, 0)
                    end
                end
            end

            
            if not getgenv().spinThread then
                getgenv().spinThread = coroutine.create(spinCharacter)
                coroutine.resume(getgenv().spinThread)
            end

        else
            getgenv().spin = false

            
            if getgenv().spinThread then
                getgenv().spinThread = nil
            end
        end
    end
})

spin:AutomaticVisible({
	Target = true,
	Elements = {
	    Spinbot:AddSlider({
	Name = "Spinbot Speed",
    Min = 1,
	Max = 100,
	Default = 1,
	Callback = function(value)
        getgenv().spinSpeed = math.rad(value)
    end
		})
	}
})

local FieldOfView = play:AddSection({
	Name = "Field of View",
	Position = "left",
});

local fov = FieldOfView:AddToggle({
    Name = "Field of View",
    Callback = function(value)
        getgenv().CameraEnabled = value
        local Camera = game:GetService("Workspace").CurrentCamera

        if value then
            getgenv().CameraFOV = getgenv().CameraFOV or 70
            Camera.FieldOfView = getgenv().CameraFOV
            
            if not getgenv().FOVLoop then
                getgenv().FOVLoop = game:GetService("RunService").RenderStepped:Connect(function()
                    if getgenv().CameraEnabled then
                        Camera.FieldOfView = getgenv().CameraFOV
                    end
                end)
            end
        else
            Camera.FieldOfView = 70
            
            if getgenv().FOVLoop then
                getgenv().FOVLoop:Disconnect()
                getgenv().FOVLoop = nil
            end
        end
    end
})

fov:AutomaticVisible({
	Target = true,
	Elements = {
	    FieldOfView:AddSlider({
	Name = "Camera FOV",
    Min = 50,
	Max = 150,
	Default = 70,
	Callback = function(value)
        getgenv().CameraFOV = value
        if getgenv().CameraEnabled then
            game:GetService("Workspace").CurrentCamera.FieldOfView = value
        end
    end
		})
	}
})

local fl = play:AddSection({
	Name = "Fly",
	Position = "right",
});

local player = game.Players.LocalPlayer
local flying = false
local arrowGui = nil

local ctrl = {f = 0, b = 0, l = 0, r = 0}
local lastCtrl = {f = 0, b = 0, l = 0, r = 0}
local speed = 0
local humanoidConnection

function notify(msg)
	game.StarterGui:SetCore("SendNotification", {
		Title = "Fly Status",
		Text = msg,
		Duration = 3
	})
end

function createArrowGui()
	if arrowGui then arrowGui:Destroy() end

	arrowGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
	arrowGui.Name = "FlyControlGui"
	arrowGui.ResetOnSpawn = false

	local function createButton(name, pos, txt)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 50, 0, 50)
		btn.Position = pos
		btn.Text = txt
		btn.TextScaled = true
		btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		btn.BackgroundTransparency = 0.3
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Parent = arrowGui
		return btn
	end

	local centerX = 0.1
	local centerY = 0.65

	local up = createButton("Up", UDim2.new(centerX, 0, centerY - 0.1, 0), "↑")
	local down = createButton("Down", UDim2.new(centerX, 0, centerY + 0.1, 0), "↓")
	local left = createButton("Left", UDim2.new(centerX - 0.1, 0, centerY, 0), "←")
	local right = createButton("Right", UDim2.new(centerX + 0.1, 0, centerY, 0), "→")

	up.MouseButton1Down:Connect(function() ctrl.f = 1 end)
	up.MouseButton1Up:Connect(function() ctrl.f = 0 end)

	down.MouseButton1Down:Connect(function() ctrl.b = -1 end)
	down.MouseButton1Up:Connect(function() ctrl.b = 0 end)

	left.MouseButton1Down:Connect(function() ctrl.l = -1 end)
	left.MouseButton1Up:Connect(function() ctrl.l = 0 end)

	right.MouseButton1Down:Connect(function() ctrl.r = 1 end)
	right.MouseButton1Up:Connect(function() ctrl.r = 0 end)
end

function Fly()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	local bg = Instance.new("BodyGyro")
	local bv = Instance.new("BodyVelocity")
	bg.P = 9e4
	bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.cframe = hrp.CFrame
	bg.Parent = hrp

	bv.velocity = Vector3.new(0, 0.1, 0)
	bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Parent = hrp

	flying = true
	notify("Fly Turned On✅")

	if humanoidConnection then humanoidConnection:Disconnect() end
	humanoidConnection = humanoid.Died:Connect(function()
		Unfly()
	end)

	coroutine.wrap(function()
		while flying and player.Character do
			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
				speed = speed + 0.5 + (speed / 15)
				if speed > 50 then speed = 50 end
			elseif speed ~= 0 then
				speed = speed - 1
				if speed < 0 then speed = 0 end
			end
			if speed ~= 0 then
				bv.velocity = ((workspace.CurrentCamera.CFrame.lookVector * (ctrl.f + ctrl.b)) +
					(workspace.CurrentCamera.CFrame.RightVector * (ctrl.r + ctrl.l))) * speed
				lastCtrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
			else
				bv.velocity = Vector3.new(0, 0.1, 0)
			end
			bg.cframe = workspace.CurrentCamera.CFrame
			task.wait()
		end
		ctrl = {f = 0, b = 0, l = 0, r = 0}
		lastCtrl = {f = 0, b = 0, l = 0, r = 0}
		speed = 0
		bg:Destroy()
		bv:Destroy()
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)()
end

function Unfly()
	flying = false
	if arrowGui then
		arrowGui:Destroy()
		arrowGui = nil
	end
	if humanoidConnection then
		humanoidConnection:Disconnect()
	end
	notify("Fly Turned Off❌")
end

-- ⏺ TOGGLE FLY
local fly = fl:AddToggle({
	Name = "Fly",
	Callback = function(value)
		if value then
			Fly()
		else
			Unfly()
		end
	end
})

fly:AutomaticVisible({
	Target = true,
	Elements = {
	    fl:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
fl:AddToggle({
	Name = "UI [For Mobile]",
	Callback = function(value)
		if value and flying then
			createArrowGui()
		elseif not value and arrowGui then
			arrowGui:Destroy()
			arrowGui = nil
		end
	end
}),
fl:AddParagraph({
	Name = "⚠️Warning:",
	Content = "Using Fly Can Get Banned"
		})
	}
})

local PlayerCosmetics = play:AddSection({
	Name = "Player Cosmetics",
	Position = "left",
});

_G.PlayerCosmeticsCleanup = {}

local pc = PlayerCosmetics:AddToggle({
    Name = "Player Cosmetics",
    Callback = function(value)
        local players = game:GetService("Players")
        local lp = players.LocalPlayer

        local function applyKorblox(character)
            local rightLeg = character:FindFirstChild("RightLeg") or character:FindFirstChild("Right Leg")
            if not rightLeg then
                warn("Right leg not found on character")
                return
            end
            
            for _, child in pairs(rightLeg:GetChildren()) do
                if child:IsA("SpecialMesh") then
                    child:Destroy()
                end
            end
            local specialMesh = Instance.new("SpecialMesh")
            specialMesh.MeshId = "rbxassetid://101851696"
            specialMesh.TextureId = "rbxassetid://115727863"
            specialMesh.Scale = Vector3.new(1, 1, 1)
            specialMesh.Parent = rightLeg
        end

        local function saveRightLegProperties(char)
            if char then
                local rightLeg = char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg")
                if rightLeg then
                    local originalMesh = rightLeg:FindFirstChildOfClass("SpecialMesh")
                    if originalMesh then
                        _G.PlayerCosmeticsCleanup.originalMeshId = originalMesh.MeshId
                        _G.PlayerCosmeticsCleanup.originalTextureId = originalMesh.TextureId
                        _G.PlayerCosmeticsCleanup.originalScale = originalMesh.Scale
                    else
                        _G.PlayerCosmeticsCleanup.hadNoMesh = true
                    end
                    
                    _G.PlayerCosmeticsCleanup.rightLegChildren = {}
                    for _, child in pairs(rightLeg:GetChildren()) do
                        if child:IsA("SpecialMesh") then
                            table.insert(_G.PlayerCosmeticsCleanup.rightLegChildren, {
                                ClassName = child.ClassName,
                                Properties = {
                                    MeshId = child.MeshId,
                                    TextureId = child.TextureId,
                                    Scale = child.Scale
                                }
                            })
                        end
                    end
                end
            end
        end
        
        local function restoreRightLeg(char)
            if char then
                local rightLeg = char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg")
                if rightLeg and _G.PlayerCosmeticsCleanup.rightLegChildren then
                    for _, child in pairs(rightLeg:GetChildren()) do
                        if child:IsA("SpecialMesh") then
                            child:Destroy()
                        end
                    end
                    
                    if _G.PlayerCosmeticsCleanup.hadNoMesh then
                        return
                    end
                    
                    for _, childData in ipairs(_G.PlayerCosmeticsCleanup.rightLegChildren) do
                        if childData.ClassName == "SpecialMesh" then
                            local newMesh = Instance.new("SpecialMesh")
                            newMesh.MeshId = childData.Properties.MeshId
                            newMesh.TextureId = childData.Properties.TextureId
                            newMesh.Scale = childData.Properties.Scale
                            newMesh.Parent = rightLeg
                        end
                    end
                end
            end
        end

        if value then
            CosmeticsActive = true

            getgenv().Config = {
                Headless = true
            }
            
            if lp.Character then
                local head = lp.Character:FindFirstChild("Head")
                if head and getgenv().Config.Headless then
                    _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
                    
                    local decal = head:FindFirstChildOfClass("Decal")
                    if decal then
                        _G.PlayerCosmeticsCleanup.faceDecalId = decal.Texture
                        _G.PlayerCosmeticsCleanup.faceDecalName = decal.Name
                    end
                end
                
                saveRightLegProperties(lp.Character)
                applyKorblox(lp.Character)
            end
            
            _G.PlayerCosmeticsCleanup.characterAddedConn = lp.CharacterAdded:Connect(function(char)
                local head = char:FindFirstChild("Head")
                if head and getgenv().Config.Headless then
                    _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
                    
                    local decal = head:FindFirstChildOfClass("Decal")
                    if decal then
                        _G.PlayerCosmeticsCleanup.faceDecalId = decal.Texture
                        _G.PlayerCosmeticsCleanup.faceDecalName = decal.Name
                    end
                end
                
                saveRightLegProperties(char)
                applyKorblox(char)
            end)
            
            if getgenv().Config.Headless then
                headLoop = task.spawn(function()
                    while CosmeticsActive do
                        local char = lp.Character
                        if char then
                            local head = char:FindFirstChild("Head")
                            if head then
                                head.Transparency = 1
                                local decal = head:FindFirstChildOfClass("Decal")
                                if decal then
                                    decal:Destroy()
                                end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end

        else
            CosmeticsActive = false

            if _G.PlayerCosmeticsCleanup.characterAddedConn then
                _G.PlayerCosmeticsCleanup.characterAddedConn:Disconnect()
                _G.PlayerCosmeticsCleanup.characterAddedConn = nil
            end

            if headLoop then
                task.cancel(headLoop)
                headLoop = nil
            end

            local char = lp.Character
            if char then
                local head = char:FindFirstChild("Head")
                if head and _G.PlayerCosmeticsCleanup.headTransparency ~= nil then
                    head.Transparency = _G.PlayerCosmeticsCleanup.headTransparency
                    
                    if _G.PlayerCosmeticsCleanup.faceDecalId then
                        local newDecal = head:FindFirstChildOfClass("Decal") or Instance.new("Decal", head)
                        newDecal.Name = _G.PlayerCosmeticsCleanup.faceDecalName or "face"
                        newDecal.Texture = _G.PlayerCosmeticsCleanup.faceDecalId
                        newDecal.Face = Enum.NormalId.Front
                    end
                end
                
                restoreRightLeg(char)
            end

            _G.PlayerCosmeticsCleanup = {}
        end
    end
})

pc:AutomaticVisible({
	Target = true,
	Elements = {
	    PlayerCosmetics:AddParagraph({
	Name = "📋Note:",
	Content = "The Whole Server Can Not See"
		})
	}
})

local noslow = play:AddSection({
	Name = "No Slow",
	Position = "right",
});

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local noSlowConnection = nil
local stateDisablers = {}
local speedEnforcer = nil

local function enableNoSlow()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	-- Disable states that can cause slowdown
	local statesToDisable = {
		Enum.HumanoidStateType.Swimming,
		Enum.HumanoidStateType.Seated,
		Enum.HumanoidStateType.Climbing,
		Enum.HumanoidStateType.PlatformStanding
	}
	for _, state in ipairs(statesToDisable) do
		humanoid:SetStateEnabled(state, false)
		stateDisablers[state] = true
	end

	-- Remove potential interfering values
	for _, v in pairs(humanoid:GetDescendants()) do
		if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("ObjectValue") then
			v:Destroy()
		end
	end

	-- Set speed immediately
	humanoid.WalkSpeed = 36

	-- Re-enforce speed if changed
	noSlowConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed ~= 36 then
			humanoid.WalkSpeed = 36
		end
	end)

	-- Continuous check every frame
	speedEnforcer = RunService.RenderStepped:Connect(function()
		if humanoid and humanoid.WalkSpeed ~= 36 then
			humanoid.WalkSpeed = 36
		end
	end)
end

local function disableNoSlow()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Re-enable states
		for state, _ in pairs(stateDisablers) do
			humanoid:SetStateEnabled(state, true)
		end
	end

	if noSlowConnection then
		noSlowConnection:Disconnect()
		noSlowConnection = nil
	end

	if speedEnforcer then
		speedEnforcer:Disconnect()
		speedEnforcer = nil
	end
end

-- ⚙️ TÍCH HỢP VÀO TOGGLE
noslow:AddToggle({
	Name = "No Slow",
	Callback = function(value)
		if value then
			enableNoSlow()
		else
			disableNoSlow()
		end
	end
})

local vi = visu:AddSection({
	Name = "Ball Trail",
	Position = "left",
});

local trailConnection = nil

vi:AddToggle({
	Name = "Ball Trail",
	Callback = function(value)
		if value then
			trailConnection = RunService.RenderStepped:Connect(function()
				local function GetBall()
					for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
						if Ball:GetAttribute("realBall") then
							return Ball
						end
					end
				end

				local function CreateRainbowTrail(ball)
					if ball:FindFirstChild("TriasTrail") then return end

					local at1 = Instance.new("Attachment", ball)
					local at2 = Instance.new("Attachment", ball)
					at1.Position = Vector3.new(0, 0.5, 0)
					at2.Position = Vector3.new(0, -0.5, 0)

					local trail = Instance.new("Trail")
					trail.Name = "TriasTrail"
					trail.Attachment0 = at1
					trail.Attachment1 = at2
					trail.Lifetime = 0.3
					trail.MinLength = 0.1
					trail.WidthScale = NumberSequence.new(1)
					trail.FaceCamera = true
					trail.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
						ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
						ColorSequenceKeypoint.new(0.32, Color3.fromRGB(255, 255, 0)),
						ColorSequenceKeypoint.new(0.48, Color3.fromRGB(0, 255, 0)),
						ColorSequenceKeypoint.new(0.64, Color3.fromRGB(0, 0, 255)),
						ColorSequenceKeypoint.new(0.80, Color3.fromRGB(75, 0, 130)),
						ColorSequenceKeypoint.new(1.0, Color3.fromRGB(148, 0, 211))
					})

					trail.Parent = ball
				end

				local ball = GetBall()
				if ball and not ball:FindFirstChild("TriasTrail") then
					CreateRainbowTrail(ball)
				end
			end)
		else
			if trailConnection then
				trailConnection:Disconnect()
				trailConnection = nil
			end

			-- Xoá trail nếu đang tắt toggle
			for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
				local trail = Ball:FindFirstChild("TriasTrail")
				if trail then
					trail:Destroy()
				end
				for _, att in ipairs(Ball:GetChildren()) do
					if att:IsA("Attachment") then
						att:Destroy()
					end
				end
			end
		end
	end
})

local vii = visu:AddSection({
	Name = "Custom Sky",
	Position = "right",
});

local lighting = game:GetService("Lighting")

-- Hàm xóa Sky cũ
local function clearSky()
	for _, obj in pairs(lighting:GetChildren()) do
		if obj:IsA("Sky") then
			obj:Destroy()
		end
	end
end

-- Sky: Galaxy Anime
local function applyGalaxySky()
	clearSky()
	local animeSky = Instance.new("Sky")
	animeSky.Name = "AnimeSky"
	animeSky.SkyboxBk = "rbxassetid://159454299"
	animeSky.SkyboxDn = "rbxassetid://159454296"
	animeSky.SkyboxFt = "rbxassetid://159454293"
	animeSky.SkyboxLf = "rbxassetid://159454286"
	animeSky.SkyboxRt = "rbxassetid://159454300"
	animeSky.SkyboxUp = "rbxassetid://159454288"
	animeSky.StarCount = 0
	animeSky.MoonAngularSize = 0
	animeSky.SunAngularSize = 0
	animeSky.Parent = lighting
end

-- Sky: Anime hoàng hôn
local function applyAnimeSky()
	clearSky()
	local sunsetSky = Instance.new("Sky")
	sunsetSky.Name = "SunsetSky"
	sunsetSky.SkyboxBk = "rbxassetid://271042516"
	sunsetSky.SkyboxDn = "rbxassetid://271077243"
	sunsetSky.SkyboxFt = "rbxassetid://271042556"
	sunsetSky.SkyboxLf = "rbxassetid://271042310"
	sunsetSky.SkyboxRt = "rbxassetid://271042467"
	sunsetSky.SkyboxUp = "rbxassetid://271077958"
	sunsetSky.StarCount = 0
	sunsetSky.SunAngularSize = 14
	sunsetSky.MoonAngularSize = 0
	sunsetSky.Parent = lighting
end

-- Sky: Đêm sao lãng mạn
local function applyStarNightSky()
	clearSky()
	local sky = Instance.new("Sky")
	sky.Name = "RomanticStarryNight"
	sky.SkyboxBk = "rbxassetid://6568931476"
	sky.SkyboxDn = "rbxassetid://6568931025"
	sky.SkyboxFt = "rbxassetid://6568931476"
	sky.SkyboxLf = "rbxassetid://6568931476"
	sky.SkyboxRt = "rbxassetid://6568931476"
	sky.SkyboxUp = "rbxassetid://6568931731"
	sky.StarCount = 1500
	sky.MoonAngularSize = 12
	sky.SunAngularSize = 0
	sky.Parent = lighting
end

-- Sky: Lava đỏ cảnh báo
local function applyLavaSky()
	clearSky()
	local sky = Instance.new("Sky")
	sky.Name = "WarningRedSky"
	sky.SkyboxBk = "rbxassetid://1012890"
	sky.SkyboxDn = "rbxassetid://1012891"
	sky.SkyboxFt = "rbxassetid://1012887"
	sky.SkyboxLf = "rbxassetid://1012889"
	sky.SkyboxRt = "rbxassetid://1012888"
	sky.SkyboxUp = "rbxassetid://1014449"
	sky.StarCount = 0
	sky.SunAngularSize = 0
	sky.MoonAngularSize = 0
	sky.Parent = lighting
end

-- Toggle trạng thái
local skyEnabled = false

-- GUI
local sky = vii:AddToggle({
	Name = "Custom Sky",
	Callback = function(value)
		skyEnabled = value
		if not value then
			clearSky()
		end
	end
})

sky:AutomaticVisible({
	Target = true,
	Elements = {
vii:AddDropdown({
	Name = "Sky Type",
	Values = {
		"Galaxy",
		"Pink Sky",
		"Star Night",
		"Sunset",
		"Soon....."
	},
	Multi = false,
	Default = "",
	Callback = function(value)
		if not skyEnabled then return end
		if value == "Galaxy" then
			applyGalaxySky()
		elseif value == "Pink Sky" then
			applyAnimeSky()
		elseif value == "Star Night" then
			applyStarNightSky()
		elseif value == "Sunset" then
			applyLavaSky()
		end
	end
		})
	}
})

local viii = visu:AddSection({
	Name = "View Ball",
	Position = "left",
});

local cam = workspace.CurrentCamera
local originalSubject = cam.CameraSubject
local viewConnection = nil

viii:AddToggle({
	Name = "View Ball",
	Callback = function(value)
		if value then
			viewConnection = RunService.RenderStepped:Connect(function()
				local function GetBall()
					for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
						if Ball:GetAttribute("realBall") then
							return Ball
						end
					end
				end

				local ball = GetBall()
				if ball and cam.CameraSubject ~= ball then
					cam.CameraSubject = ball
				end
			end)
		else
			if viewConnection then
				viewConnection:Disconnect()
				viewConnection = nil
			end
			cam.CameraSubject = Players.LocalPlayer.Character or Players.LocalPlayer
		end
	end
})

local viiii = visu:AddSection({
	Name = "Visualize",
	Position = "right",
});

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local fieldPart = nil
local visualizeConnection = nil

viiii:AddToggle({
	Name = "Visualize",
	Callback = function(value)
		if value then
			-- Tạo forcefield visual nếu chưa có
			if not fieldPart then
				fieldPart = Instance.new("Part")
				fieldPart.Anchored = true
				fieldPart.CanCollide = false
				fieldPart.Transparency = 0.5
				fieldPart.Shape = Enum.PartType.Ball
				fieldPart.Material = Enum.Material.ForceField
				fieldPart.CastShadow = false
				fieldPart.Color = Color3.fromRGB(88, 131, 202)
				fieldPart.Name = "VisualField"
				fieldPart.Parent = workspace
			end

			visualizeConnection = RunService.RenderStepped:Connect(function()
				local function GetBall()
					for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
						if Ball:GetAttribute("realBall") then
							return Ball
						end
					end
				end

				local ball = GetBall()
				if not ball then return end

				local ballVel = ball.AssemblyLinearVelocity
				local speed = ballVel.Magnitude

				-- Tính khoảng cách co giãn (clamp từ 25 đến 400)
				local size = math.clamp(speed, 25, 250)

				-- Cập nhật field
				fieldPart.Position = root.Position
				fieldPart.Size = Vector3.new(size, size, size)
			end)
		else
			if visualizeConnection then
				visualizeConnection:Disconnect()
				visualizeConnection = nil
			end
			if fieldPart then
				fieldPart:Destroy()
				fieldPart = nil
			end
		end
	end
})

local lookat = visu:AddSection({
	Name = "Lookat Ball",
	Position = "left",
});

local RunService = game:GetService("RunService")  
local Players = game:GetService("Players")  
local Camera = workspace.CurrentCamera  
local Player = Players.LocalPlayer  
  
local lookAtBallToggle = false  
local parryLookType = "Camera"  
  
local playerConn, cameraConn = nil, nil  
  
-- Hàm lấy quả bóng thật  
local function GetBall()  
	for _, Ball in ipairs(workspace.Balls:GetChildren()) do  
		if Ball:GetAttribute("realBall") then  
			return Ball  
		end  
	end  
end  
  
-- Hàm bật chức năng xoay  
local function EnableLookAt()  
	if parryLookType == "Character" then  
		playerConn = RunService.Stepped:Connect(function()  
			local Ball = GetBall()  
			local Character = Player.Character  
			if not Ball or not Character then return end  
  
			local HRP = Character:FindFirstChild("HumanoidRootPart")  
			if not HRP then return end  
  
			local lookPos = Vector3.new(Ball.Position.X, HRP.Position.Y, Ball.Position.Z)  
			HRP.CFrame = CFrame.lookAt(HRP.Position, lookPos)  
		end)  
	elseif parryLookType == "Camera" then  
		cameraConn = RunService.RenderStepped:Connect(function()  
			local Ball = GetBall()  
			if not Ball then return end  
  
			local camPos = Camera.CFrame.Position  
			Camera.CFrame = CFrame.lookAt(camPos, Ball.Position)  
		end)  
	end  
end  
  
-- Hàm tắt chức năng xoay  
local function DisableLookAt()  
	if playerConn then playerConn:Disconnect() playerConn = nil end  
	if cameraConn then cameraConn:Disconnect() cameraConn = nil end  
end  
  
-- Toggle   
local look = lookat:AddToggle({  
	Name = "Lookat Ball",  
	Callback = function(value)  
		lookAtBallToggle = value  
		if value then  
			EnableLookAt()  
		else  
			DisableLookAt()  
		end  
	end  
})  
  
look:AutomaticVisible({  
	Target = true,  
	Elements = {  
	    lookat:AddParagraph({
	Name = "",
	Content = "_________________________________________"
}),
lookat:AddDropdown({  
	     Name = "Look Type",  
			Values = {  
				"Camera",  
				"Character"  
			},  
			Multi = false,  
			Default = "Camera",  
			Callback = function(value)  
				parryLookType = value  
				if lookAtBallToggle then  
					DisableLookAt()  
					EnableLookAt()  
				end  
			end  
		})  
	}  
})

local Visuals = visu:AddSection({
	Name = "Player Trail",
	Position = "right",
});

local speedTrail = nil
local speedConnection = nil

Visuals:AddToggle({
	Name = "Player Trail",
	Callback = function(value)
		if value then
			speedConnection = RunService.RenderStepped:Connect(function()
				local lp = Players.LocalPlayer
				local char = lp.Character or lp.CharacterAdded:Wait()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp then return end

				local speed = hrp.Velocity.Magnitude

				-- Nếu chạy đủ nhanh thì bật trail
				if speed > 20 then
					if not speedTrail then
						local at0 = Instance.new("Attachment", hrp)
						local at1 = Instance.new("Attachment", hrp)
						at0.Position = Vector3.new(0, 0.5, 0)
						at1.Position = Vector3.new(0, -0.5, 0)

						speedTrail = Instance.new("Trail")
						speedTrail.Attachment0 = at0
						speedTrail.Attachment1 = at1
						speedTrail.Lifetime = 0.2
						speedTrail.Transparency = NumberSequence.new(0.2)
						speedTrail.WidthScale = NumberSequence.new(1.5)
						speedTrail.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 255, 255))
						speedTrail.LightEmission = 1
						speedTrail.Name = "SpeedLineTrail"
						speedTrail.Parent = hrp
					end
				else
					-- Tắt trail nếu không đủ nhanh
					if speedTrail then
						for _, v in ipairs(hrp:GetChildren()) do
							if v:IsA("Attachment") then v:Destroy() end
						end
						speedTrail:Destroy()
						speedTrail = nil
					end
				end
			end)
		else
			if speedConnection then
				speedConnection:Disconnect()
				speedConnection = nil
			end
			if speedTrail then
				local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					for _, v in ipairs(hrp:GetChildren()) do
						if v:IsA("Attachment") then v:Destroy() end
					end
				end
				speedTrail:Destroy()
				speedTrail = nil
			end
		end
	end
})

local Visual = visu:AddSection({
	Name = "Clone",
	Position = "left",
});

local mirrorConnection = nil

local mi = Visual:AddToggle({
	Name = "Mirror Trail",
	Callback = function(value)
		if value then
			mirrorConnection = RunService.RenderStepped:Connect(function()
				local lp = Players.LocalPlayer
				local char = lp.Character or lp.CharacterAdded:Wait()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp then return end

				local speed = hrp.Velocity.Magnitude
				if speed > 20 then
					local clone = char:Clone()
					for _, v in pairs(clone:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Anchored = true
							v.CanCollide = false
							v.Transparency = 0.5
						elseif v:IsA("Humanoid") then
							v:Destroy()
						end
					end
					clone.Name = "MirrorClone"
					clone.Parent = workspace

					-- Đặt đúng vị trí hiện tại
					for _, part in pairs(clone:GetChildren()) do
						if part:IsA("BasePart") and char:FindFirstChild(part.Name) then
							part.CFrame = char[part.Name].CFrame
						end
					end

					-- Xoá clone sau 0.5s mờ dần
					task.delay(0.05, function()
						for _, part in pairs(clone:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 1
							end
						end
						clone:Destroy()
					end)
				end
			end)
		else
			if mirrorConnection then
				mirrorConnection:Disconnect()
				mirrorConnection = nil
			end
			-- Xoá mọi clone còn lại
			for _, v in ipairs(workspace:GetChildren()) do
				if v.Name == "MirrorClone" then
					v:Destroy()
				end
			end
		end
	end
})

mi:AutomaticVisible({
	Target = true,
	Elements = {
	    Visual:AddParagraph({
	Name = "🐞Bug:",
	Content = "there is a little bug, i will fix it later"
		})
	}
})

local Visua = visu:AddSection({
	Name = "Filter",
	Position = "right",
});

local rainbowConnection = nil
local colorCorrection = nil
local lighting = game:GetService("Lighting")

Visua:AddToggle({
	Name = "Rainbow Filter",
	Callback = function(value)
		if value then
			if not colorCorrection then
				colorCorrection = Instance.new("ColorCorrectionEffect")
				colorCorrection.Name = "RainbowFilter"
				colorCorrection.Saturation = 1
				colorCorrection.Contrast = 0.1
				colorCorrection.Brightness = 0
				colorCorrection.TintColor = Color3.fromRGB(255, 0, 0)
				colorCorrection.Parent = lighting
			end

			local hue = 0
			rainbowConnection = RunService.RenderStepped:Connect(function()
				hue = (hue + 1) % 360
				local color = Color3.fromHSV(hue / 360, 1, 1)
				colorCorrection.TintColor = color
			end)
		else
			if rainbowConnection then
				rainbowConnection:Disconnect()
				rainbowConnection = nil
			end
			if colorCorrection then
				colorCorrection:Destroy()
				colorCorrection = nil
			end
		end
	end
})

local jump = m:AddSection({
	Name = "Auto Jump",
	Position = "left",
});

local autoJumpConnection = nil

jump:AddToggle({
	Name = "Auto Jump",
	Callback = function(value)
		if value then
			autoJumpConnection = RunService.RenderStepped:Connect(function()
				local lp = Players.LocalPlayer
				local char = lp.Character or lp.CharacterAdded:Wait()
				local humanoid = char:FindFirstChildWhichIsA("Humanoid")

				if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Running or humanoid:GetState() == Enum.HumanoidStateType.Freefall then
					-- Chỉ nhảy nếu đang trên đất hoặc vừa tiếp đất
					if humanoid.FloorMaterial ~= Enum.Material.Air then
						humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
				end
			end)
		else
			if autoJumpConnection then
				autoJumpConnection:Disconnect()
				autoJumpConnection = nil
			end
		end
	end
})

local fps = m:AddSection({
	Name = "FPS Boost",
	Position = "right",
});

local originalSettings = {}

local fb = fps:AddToggle({
	Name = "FPS Boost",
	Callback = function(value)
		local lighting = game:GetService("Lighting")
		local terrain = workspace:FindFirstChildOfClass("Terrain")

		if value then
			-- Lưu lại cấu hình Lighting & Terrain
			originalSettings = {
				Ambient = lighting.Ambient,
				Brightness = lighting.Brightness,
				GlobalShadows = lighting.GlobalShadows,
				FogEnd = lighting.FogEnd,
				FogStart = lighting.FogStart,
				Technology = lighting.Technology,
				WaterWaveSize = terrain and terrain.WaterWaveSize or nil,
				WaterReflectance = terrain and terrain.WaterReflectance or nil,
			}

			-- Tối ưu Lighting
			lighting.Ambient = Color3.fromRGB(80, 80, 80)
			lighting.Brightness = 1
			lighting.GlobalShadows = false
			lighting.FogStart = 0
			lighting.FogEnd = 999999
			pcall(function() lighting.Technology = Enum.Technology.Compatibility end)

			-- Tối ưu Terrain
			if terrain then
				terrain.WaterWaveSize = 0
				terrain.WaterReflectance = 0
			end

			-- Xoá và tắt các đối tượng gây lag
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceAppearance") then
					pcall(function() obj:Destroy() end)
				elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
					obj.Enabled = false
				elseif obj:IsA("ShirtGraphic") or obj:IsA("Shirt") or obj:IsA("Pants") then
					pcall(function() obj:Destroy() end)
				elseif obj:IsA("SpecialMesh") or obj:IsA("FileMesh") or obj:IsA("MeshPart") then
					pcall(function() obj.TextureID = "" end)
				end
			end
		else
			-- Khôi phục lại Lighting & Terrain
			if originalSettings then
				lighting.Ambient = originalSettings.Ambient
				lighting.Brightness = originalSettings.Brightness
				lighting.GlobalShadows = originalSettings.GlobalShadows
				lighting.FogStart = originalSettings.FogStart
				lighting.FogEnd = originalSettings.FogEnd
				pcall(function() lighting.Technology = originalSettings.Technology end)

				if terrain then
					terrain.WaterWaveSize = originalSettings.WaterWaveSize
					terrain.WaterReflectance = originalSettings.WaterReflectance
				end
			end

			-- Bật lại particle (không thể khôi phục texture đã xoá)
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
					obj.Enabled = true
				end
			end
		end
	end
})

local noRenderCache = {}

fb:AutomaticVisible({
	Target = true,
	Elements = {
fps:AddToggle({
	Name = "No Render",
	Callback = function(value)
		if value then
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Texture") or
				   obj:IsA("Decal") or
				   obj:IsA("ParticleEmitter") or
				   obj:IsA("Trail") or
				   obj:IsA("Beam") or
				   obj:IsA("SurfaceGui") or
				   obj:IsA("BillboardGui") or
				   obj:IsA("Shirt") or
				   obj:IsA("Pants") or
				   obj:IsA("ShirtGraphic") or
				   obj:IsA("Accessory") then
					noRenderCache[obj] = true
					obj:Destroy()
				elseif obj:IsA("SpecialMesh") or obj:IsA("MeshPart") then
					noRenderCache[obj] = obj.TextureID
					obj.TextureID = ""
				end
			end
		else
			-- Không thể khôi phục mấy thứ đã xoá, nhưng có thể cảnh báo
			warn("⚠️ 'No Render' đã xoá texture và gui, không thể khôi phục hoàn toàn.")
		end
	end
		})
	}
})

local stat = m:AddSection({
	Name = "Ball Stats",
	Position = "left",
});

local statsGui = nil
local statsConnection = nil

stat:AddToggle({
	Name = "Ball Stats",
	Callback = function(value)
		if value then
			local player = Players.LocalPlayer

			-- Tạo GUI
			statsGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
			statsGui.Name = "BallStatsUI"
			statsGui.ResetOnSpawn = false

			local frame = Instance.new("Frame", statsGui)
			frame.Size = UDim2.new(0, 180, 0, 80)
			frame.Position = UDim2.new(1, -200, 0, 100)
			frame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
			frame.BackgroundTransparency = 0.2
			frame.BorderSizePixel = 0
			frame.Active = true
			frame.Draggable = true -- 🟢 Cho phép kéo

			local label = Instance.new("TextLabel", frame)
			label.Size = UDim2.new(1, -10, 1, -10)
			label.Position = UDim2.new(0, 5, 0, 5)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Top
			label.Text = "Loading..."

			statsConnection = RunService.RenderStepped:Connect(function()
				local function GetBall()
					for _, Ball in ipairs(workspace:WaitForChild("Balls"):GetChildren()) do
						if Ball:GetAttribute("realBall") then
							return Ball
						end
					end
				end

				local ball = GetBall()
				if not ball then
					label.Text = "No ball found"
					return
				end

				local char = player.Character or player.CharacterAdded:Wait()
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp then return end

				local speed = math.floor(ball.Velocity.Magnitude)
				local distance = math.floor((ball.Position - hrp.Position).Magnitude)
				local target = ball:GetAttribute("target") or "N/A"
				local status = speed < 3 and "Idle" or "Flying"

				label.Text = string.format(
					"⚽ Ball Stats\nSpeed: %s\nDistance: %s\nTarget: %s",
					speed, distance, target
				)
			end)
		else
			if statsConnection then
				statsConnection:Disconnect()
				statsConnection = nil
			end
			if statsGui then
				statsGui:Destroy()
				statsGui = nil
			end
		end
	end
})
