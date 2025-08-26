------Button References------
FlyCounter = buttons.FlyCounter
FlyCounterInner = buttons.FlyCounterInner
FlyCounterText = buttons.FlyCounterText
DownButton = buttons.DownButton
UpButton = buttons.UpButton
LongjumpButton = buttons.LongjumpButton
InfFlyButton = buttons.InfFlyButton
FlyButton = buttons.FlyButton
------Module Imports------
local bedwars = module.bedwars
local SwordAnimations = module.SwordAnimations
local SetCamera = module.SetCamera
local IsAlive = module.IsAlive
local GetClosest = module.GetClosest
local GetClosestTeamCheck = module.GetClosestTeamCheck
local GetBeds = module.GetBeds
local GetClosestBeds = module.GetClosestBeds
local getserverpos = module.getserverpos
local GetMatchState = module.GetMatchState
local GetQueueType = module.GetQueueType
local GetInventory = module.GetInventory
local BedwarsSwords = module.BedwarsSwords
local valuefunc = module.valuefunc
local getSword = module.getSword
local GetItemNear = module.GetItemNear
local cachedNormalSides = module.cachedNormalSides
local isBlockCovered = module.isBlockCovered
local switchItem = module.switchItem
local isNotHoveringOverGui = module.isNotHoveringOverGui
local getWool = module.getWool
local LoopManager = module.LoopManager
local ClosestEntity = module.ClosestEntity
local ClosetEntityPlayerCheck = module.ClosetEntityPlayerCheck
local rotateTo = module.rotateTo
local sendattackfire = module.sendattackfire
local blockRaycast = module.blockRaycast
local placeblock = module.placeblock
local getPlacedBlock = module.getPlacedBlock
local breakBlock = module.breakBlock
local endnuker = module.endnuker
local RavenEquippedKit = module.RavenEquippedKit
local getShopItem = module.getShopItem
local buyremote = module.buyremote

------Services------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera
local RunService = game:GetService("RunService")
local collectionService = game:GetService("CollectionService")

------Locals------
local viewmodel = workspace.CurrentCamera:WaitForChild("Viewmodel").RightHand.RightWrist
local viewmodelcopy = viewmodel.C0
local oldviewmodel = viewmodel.C0
local Anim = nil
local animcompleted = true
local KillauraViewAngle = 360
local KillauraWallCheck = false
local AnimationOptionsKillaura = "Remade"
local KillauraRange = 20
local AttackMobdsEnabled = true
local Boxes = {}
local TransperancyValue = 50
local AttackDelay = 0.5
local lastAttackTime = 0
local animationdelay = tick()
local swordAnimation = Instance.new("Animation")
swordAnimation.AnimationId = "rbxassetid://4947108314"
local loop = LoopManager.new()

------Killaura Module------
Killaura = Combat:CreateToggle({
	Name = "Killaura",
	Callback = function(Callback)
		if Callback then
			local selfroot = nil
			local sword = nil
			local target = nil
			local isMonster = false
			local root = nil
			loop:AddTask("KillauraTarget", function()
				if not IsAlive(LocalPlayer) or GetMatchState() == 0 then
					target = nil
					isMonster = false
					return
				end
				selfroot = LocalPlayer.Character.HumanoidRootPart
				sword = getSword()
				if not sword then
					target = nil
					isMonster = false
					return
				end
				local plr = GetClosestTeamCheck(KillauraRange)
				local monster = AttackMobdsEnabled and ClosestEntity(KillauraRange) or nil
				if plr and IsAlive(plr) and not plr.Character:FindFirstChildOfClass("ForceField") then
					target = plr
					isMonster = false
				elseif monster then
					target = monster
					isMonster = true
				else
					target = nil
					isMonster = false
				end
				if target then
					root = isMonster and target.PrimaryPart or target.Character.HumanoidRootPart
					if not ToolcheckKillaura then
						switchItem(sword.tool)
					end
				else
					root = nil
				end
			end, 0.01, 2)
			loop:AddTask("KillauraAttack", function(deltaTime)
				if not target or not selfroot or not sword or not root then
					return
				end
				if KillauraViewAngle < 360 then
					local localfacing = selfroot.CFrame.LookVector
					local vec = (root.Position - selfroot.Position).Unit
					local angle = math.acos(localfacing:Dot(vec))
					if angle >= math.rad(KillauraViewAngle) / 2 then
						return
					end
				end
				if KillauraWallCheck and not isMonster then
					if not bedwars["SwordController"]:canSee({
						player = target,
						getInstance = function()
							return target.Character
						end
					}) then
						return
					end
				end
				if AnimationOptionsKillaura == "Normal" and animationdelay <= tick() then
					animationdelay = tick() + 0.18
					bedwars["SwordController"]:playSwordEffect(sword.tool.Name, false)
				end
				local selfpos = selfroot.Position
				local rootpos = root.Position
				local mag = (rootpos - selfpos).Magnitude
				local cursdirection = CFrame.lookAt(selfpos, rootpos).LookVector
				local cameraposition = selfpos + cursdirection * math.max(mag - 14.4, 0)
				local chargedmeta = bedwars["ItemMeta"][sword.tool.Name]
				bedwars["SwordController"].lastAttack = workspace:GetServerTimeNow()
				bedwars["SwordController"].lastAttackTimeDelta = workspace:GetServerTimeNow() - lastAttackTime
				bedwars["SwordController"].lastAttackTime = workspace:GetServerTimeNow()
				--lastAttackTime = bedwars["SwordController"].lastAttackTime
				for i = 0, 5, 1 do 
					task.wait()
					sendattackfire(sword, isMonster, isMonster and target or nil, not isMonster and target or nil, selfpos, rootpos, cursdirection, cameraposition, chargedmeta)
				end
				if LockinKilaura then
					rotateTo(rootpos)
				end
				if animcompleted and AnimationOptionsKillaura ~= "None" and AnimationOptionsKillaura ~= "Normal" then
					for i, v in next, SwordAnimations[AnimationOptionsKillaura] do
						if workspace.CurrentCamera.Viewmodel and viewmodel then
							animcompleted = false
							Anim = game:GetService("TweenService"):Create(viewmodel, TweenInfo.new(v.Time), {
								C0 = viewmodelcopy * v.CFrame
							})
							Anim:Play()
							Anim.Completed:Wait()
							task.wait(v.Time)
							Anim = game:GetService("TweenService"):Create(viewmodel, TweenInfo.new(v.Time), {
								C0 = oldviewmodel
							})
							Anim:Play()
							animcompleted = true
						end
					end
				end
				if animationdelay <= tick() then
					animationdelay = tick() + 0.26 + KillauraTime / 100
					local loader = LocalPlayer.Character.Humanoid:FindFirstChild("Animator")
					if loader then
						loader:LoadAnimation(swordAnimation):Play()
					end
				end
			end, 0, 1)
			loop:AddTask("KillauraBox", function(deltaTime)
				if target and root and Boxes.Adornee ~= root then
					Boxes.Adornee = root
					Boxes.Color3 = Color3.fromRGB(204, 0, 204)
					Boxes.Transparency = TransperancyValue / 100
				elseif not target then
					Boxes.Adornee = nil
				end
			end, 0.2, 0)
		else
			loop:Destroy()
			Boxes.Adornee = nil
			loop = LoopManager.new()
		end
	end
})
Killaura:CreateInfo("Hits Players Around you")
Killaura:CreateDropDown({
	Name = "Mode",
	DefaultOption = "Health",
	SecondArrayitem = true,
	Options = {
		"Closest",
		"Health",
	},
	Callback = function(Callback)
		Targetoptions = Callback
	end
})
local killauraanimationarray = {"Normal"}
for i, v in next, SwordAnimations do
	table.insert(killauraanimationarray, i)
end
Killaura:CreateDropDown({
	Name = "Animation",
	DefaultOption = "Remade",
	Options = killauraanimationarray,
	Callback = function(Callback)
		AnimationOptionsKillaura = Callback
	end
})
Killaura:CreateToggle({
	Name = "Locked View",
	Callback = function(Callback)
		LockinKillaura = Callback
	end
})
Killaura:CreateToggle({
	Name = "WallCheck",
	Callback = function(Callback)
		KillauraWallCheck = Callback
	end
})
Killaura:CreateToggle({
	Name = "Attack Mobs",
	StartingState = true,
	Callback = function(Callback)
		AttackMobdsEnabled = Callback
	end
})
Killaura:CreateToggle({
	Name = "Show target",
	Callback = function(Callback)
		if Callback then
			local box = Instance.new("BoxHandleAdornment")
			box.Adornee = nil
			box.AlwaysOnTop = true
			box.Size = Vector3.new(3, 5, 3)
			box.CFrame = CFrame.new(0, -0.5, 0)
			box.ZIndex = 0
			box.Parent = workspace
			Boxes = box
		else
			Boxes:Destroy()
		end
	end
})
--[[Killaura:CreateSlider({
	Name = "Attack Delay",
	Default = 50,
	Min = 0,
	Max = 50,
	Callback = function(Callback)
		AttackDelay = Callback / 100
	end
})]]
Killaura:CreateSlider({
	Name = "Transperancy",
	Default = 50,
	Min = 1,
	Max = 100,
	Callback = function(Callback)
		TransperancyValue = Callback
	end
})
Killaura:CreateSlider({
	Name = "Range",
	Default = 16,
	Min = 0,
	Max = 17,
	Callback = function(Callback)
		KillauraRange = Callback
	end
})
Killaura:CreateSlider({
	Name = "Animation Time",
	Default = 15,
	Min = 10,
	Max = 100,
	Callback = function(Callback)
		KillauraTime = Callback
	end
})
Killaura:CreateSlider({
	Name = "ViewAngle",
	Default = 360,
	Min = 15,
	Max = 360,
	Callback = function(Callback)
		KillauraViewAngle = Callback
	end
})
Killaura:CreateToggle({
	Name = "Toolcheck",
	Callback = function(Callback)
		ToolcheckKillaura = Callback
	end
})

------TargetHud Module------
TargetHudModule = Client:CreateToggle({
	Name = "Target Hud",
	Callback = function(Callback)
		if Callback then
			repeat
				task.wait()
				local shouldShowHud = false
				if GetMatchState() == 1 then
					local GetClosestPlayer = GetClosest()
					if GetClosestPlayer and GetClosestPlayer.Team ~= LocalPlayer.Team and IsAlive(GetClosestPlayer) and IsAlive(LocalPlayer) and not GetClosestPlayer.Character:FindFirstChildOfClass("ForceField") then
						local Magnitude = (GetClosestPlayer.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
						if Magnitude < TargetHudRange then
							shouldShowHud = true
							pcall(function()
								shared.TargetHud.Visible = true
								shared.TargetName.Text = GetClosestPlayer.Name
								shared.TargetName.TextColor3 = GetClosestPlayer.TeamColor.Color
								shared.TargetState.Text = GetClosestPlayer.Character.Humanoid.Health <= LocalPlayer.Character.Humanoid.Health and "W" or "L"
								shared.TargetState.TextColor3 = GetClosestPlayer.Character.Humanoid.Health <= LocalPlayer.Character.Humanoid.Health and Color3.fromRGB(34, 255, 0) or Color3.fromRGB(255, 5, 22)
								shared.TargetColor.TextColor3 = GetClosestPlayer.TeamColor.Color
								shared.TargetColor.Text = GetClosestPlayer.TeamColor and tostring(string.sub(tostring(GetClosestPlayer.TeamColor), 1, 1)) or ""
								shared.TargetHealth.Text = tostring(math.round(GetClosestPlayer.Character.Humanoid.Health))
								shared.TargetHealth.TextColor3 = GetClosestPlayer.Character.Humanoid.Health >= 90 and Color3.fromRGB(34, 255, 0) or GetclosestPlayer.Character.Humanoid.Health >= 50 and Color3.fromRGB(255, 125, 11) or Color3.fromRGB(255, 5, 22)
								game:GetService("TweenService"):Create(shared.SliderInner, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
									Size = UDim2.fromScale(GetClosestPlayer.Character.Humanoid.Health / GetClosestPlayer.Character.Humanoid.MaxHealth, 1)
								}):Play()
								shared.SliderInner2.Size = UDim2.fromScale(GetClosestPlayer.Character.Humanoid.Health / GetClosestPlayer.Character.Humanoid.MaxHealth, 1)
							end)
						end
					end
				end
				shared.TargetHud.Visible = shouldShowHud
			until not Callback
			shared.TargetHud.Visible = false
		end
	end
})
TargetHudModule:CreateInfo("Shows Infos about the Player!")
TargetHudModule:CreateSlider({
	Name = "Range",
	Default = 20,
	Min = 0,
	Max = 20,
	Callback = function(Callback)
		TargetHudRange = Callback
	end
})

------Aimbot Module------
local AimbotRange = 100
local AimbotFOV = 90
local AimbotWallCheck = false
local loop = LoopManager.new()
AimBot = Combat:CreateToggle({
	Name = "Aimbot",
	Callback = function(Callback)
		if Callback then
			local target = nil
			local targetHead = nil
			loop:AddTask("AimbotTarget", function(deltaTime)
				if not IsAlive(LocalPlayer) or GetMatchState() == 0 then
					return
				end
				local plr = GetClosestTeamCheck(AimbotRange)
				if plr and IsAlive(plr) and not plr.Character:FindFirstChildOfClass("ForceField") then
					local head = plr.Character:FindFirstChild("Head")
					if head then
						if plr and head then
							local headPos = head.Position
							Camera.CFrame = CFrame.new(Camera.CFrame.Position, headPos)
						end
						if AimbotFOV < 360 then
							local selfPos = LocalPlayer.Character.HumanoidRootPart.Position
							local vec = (head.Position - selfPos).Unit
							local localfacing = LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector
							local angle = math.acos(localfacing:Dot(vec))
							if angle >= math.rad(AimbotFOV) / 2 then
								plr = nil
							end
						end
						if AimbotWallCheck and plr then
							if not bedwars["SwordController"]:canSee({
								player = plr,
								getInstance = function()
									return plr.Character
								end
							}) then
								plr = nil
							end
						end
					else
						plr = nil
					end
				end
			end)
		else
			loop:Destroy()
			loop = LoopManager.new()
		end
	end
})
AimBot:CreateInfo("Aims at other Players")
AimBot:CreateToggle({
	Name = "ClickHold",
	StartingState = true,
	Callback = function(Callback)
		AimbotClickHold = Callback
	end
})
AimBot:CreateSlider({
	Name = "Range",
	Default = 16,
	Min = 0,
	Max = 18,
	Callback = function(Callback)
		AimbotRange = Callback
	end
})
AimBot:CreateSlider({
	Name = "Speed",
	Default = 5,
	Min = 0,
	Max = 50,
	Callback = function(Callback)
		AimbotSpeed = Callback
	end
})

------AutoClicker Module------
local autoclickermousedown = false
local AutoClickerCPS = 1
local firstClick = tick() + 0.1
Autoclicker = Combat:CreateToggle({
	Name = "AutoClicker",
	Callback = function(Callback)
		AutoClicker = Callback
		if AutoClicker then
			spawn(function()
				UIS.InputBegan:Connect(function(input, gameProcessed)
					if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UIS:GetFocusedTextBox() then
						autoclickermousedown = true
					end
				end)
				UIS.InputEnded:Connect(function(input)
					if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not UIS:GetFocusedTextBox() then
						autoclickermousedown = false
					end
				end)
			end)
			repeat
				task.wait(1 / AutoClickerCPS)
				if IsAlive(LocalPlayer) then
					if ((bedwars["KatanaController"] == nil and true) or bedwars["KatanaController"].chargingMaid == nil) and isNotHoveringOverGui() and AutoClicker and autoclickermousedown then
						if firstClick <= tick() then
							bedwars["SwordController"]:swingSwordAtMouse()
						else
							firstClick = tick() + 0.1
						end
					end
					if Autoclicker and AutoClickerBlocks and autoclickermousedown and bedwars["BlockPlacementController"].blockPlacer and firstClick <= tick() then
						if (workspace:GetServerTimeNow() - bedwars["BlockCpsController"].lastPlaceTimestamp) > (1 / 24) then
							local mouseinfo = bedwars["BlockPlacementController"].blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
							if mouseinfo then
								if mouseinfo.placementPosition == mouseinfo.placementPosition then
									bedwars["BlockPlacementController"].heterna:placeBlock(mouseinfo.placementPosition)
								end
							end
						end
					end
				end
			until not AutoClicker
		end
	end
})
Autoclicker:CreateInfo("Makes you click faster!")
Autoclicker:CreateSlider({
	Name = "CPS",
	Min = 1,
	Default = 16,
	Max = 40,
	Callback = function(Callback)
		AutoClickerCPS = Callback
	end
})
Autoclicker:CreateToggle({
	Name = "Blocks",
	StartingState = true,
	Callback = function(Callback)
		AutoClickerBlocks = Callback
	end
})

------AutoSprint Module------
local oldSprintFunction
Combat:CreateToggle({
	Name = "AutoSprint",
	Callback = function(Callback)
		EnabledSprint = Callback
		if EnabledSprint then
			oldSprintFunction = bedwars["SprintController"].stopSprinting
			bedwars["SprintController"].stopSprinting = function(...)
				local originalCall = oldSprintFunction(...)
				bedwars["SprintController"]:startSprinting()
				return originalCall
			end
			LocalPlayer.CharacterAdded:Connect(function(char)
				char:WaitForChild("Humanoid", 9e9)
				task.wait(0.5)
				bedwars.SprintController:stopSprinting()
			end)
			task.spawn(function()
				bedwars.SprintController:startSprinting()
			end)
		else
			bedwars["SprintController"].stopSprinting = oldSprintFunction
			bedwars["SprintController"]:stopSprinting()
		end
	end
})

------Velocity Module------
local applyKnockback
Velocity = Combat:CreateToggle({
	Name = "Velocity",
	Callback = function(Callback)
		if Callback then
			applyKnockback = bedwars["KnockbackUtil"].applyKnockback
			bedwars["KnockbackUtil"].applyKnockback = function(root, mass, dir, knockback, ...)
				knockback = knockback or {}
				if Hori == 0 and Verti == 0 then
					return
				end
				knockback.horizontal = (knockback.horizontal or 1) * (Hori / 100)
				knockback.vertical = (knockback.vertical or 1) * (Verti / 100)
				return applyKnockback(root, mass, dir, knockback, ...)
			end
		else
			bedwars["KnockbackUtil"].applyKnockback = applyKnockback
		end
	end
})
Velocity:CreateInfo("Gives you long arms")
Velocity:CreateSlider({
	Name = "Horizontal",
	Min = 0,
	Max = 100,
	Callback = function(Callback)
		Hori = Callback
	end
})
Velocity:CreateSlider({
	Name = "Vertical",
	Min = 0,
	Max = 100,
	Callback = function(Callback)
		Verti = Callback
	end
})

------AutoQueue Module------
Blatant:CreateToggle({
	Name = "AutoQueue",
	Callback = function(Callback)
		AutoQueue = Callback
		if AutoQueue then
			repeat
				task.wait(3)
			until GetMatchState() == 2 or not AutoQueue
			if not AutoQueue then
				return
			end
			game:GetService("ReplicatedStorage"):FindFirstChild("events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events").joinQueue:FireServer({
				["queueType"] = GetQueueType()
			})
		end
	end
})

------Utility Functions------
local function getclosetestnearshop()
    local newshopmag = 20
    local shop = nil
    for i, v in next, (collectionService:GetTagged("BedwarsItemShop")) do
        if not v or not v.Parent then continue end
        local newshopmag2 = (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).magnitude
        if newshopmag2 < newshopmag then
            newshopmag = newshopmag2
            shop = v
        end
    end
    return shop
end

local armors = {
    [1] = "leather_chestplate",
    [2] = "iron_chestplate", 
    [3] = "diamond_chestplate",
    [4] = "emerald_chestplate"
}

local swords = {
    [1] = "wood_sword",
    [2] = "stone_sword",
    [3] = "iron_sword", 
    [4] = "diamond_sword",
    [5] = "emerald_sword"
}

-- Kit-specific sword modifications
if RavenEquippedKit ~= nil then
    if RavenEquippedKit == "dasher" then
        swords = {
            [1] = "wood_dao",
            [2] = "stone_dao", 
            [3] = "iron_dao",
            [4] = "diamond_dao",
            [5] = "emerald_dao"
        }
    elseif RavenEquippedKit == "ice_queen" then
        swords[5] = "ice_sword"
    elseif RavenEquippedKit == "ember" then
        swords[5] = "infernal_saber"
    elseif RavenEquippedKit == "lumen" then
        swords[5] = "light_sword"
    end
end

local function canBuyItem(itemName, shopId)
    local item = getShopItem(itemName)
    if not item then
        return false
    end
    local currency = GetItemNear(item.currency)
    return currency and item.price <= currency.amount, item, shopId
end

local function hasItem(itemName)
    return GetItemNear(itemName) ~= nil
end

local function getCurrentArmorTier()
    for i = 4, 1, -1 do
        if hasItem(armors[i]) then
            return i
        end
    end
    return 0
end

local function getCurrentSwordTier()
    local currentSword = getSword()
    if not currentSword then return 0 end
    
    local currentSwordName = currentSword.tool.name
    for i = 5, 1, -1 do
        if currentSwordName == swords[i] then
            return i
        end
    end
    return 0
end

local autoBuyCoroutine = nil

------AutoBuy Module------
AutoBuy = Blatant:CreateToggle({
    Name = "Auto Buy",
    Callback = function(Callback)
        EnabledAutoBuy = Callback
        
        if autoBuyCoroutine then
            coroutine.close(autoBuyCoroutine)
            autoBuyCoroutine = nil
        end
        
        if EnabledAutoBuy then
            autoBuyCoroutine = coroutine.create(function()
                while EnabledAutoBuy do
                    local success, err = pcall(function()
                        if not IsAlive(LocalPlayer) then
                            return
                        end
                        
                        local shop = getclosetestnearshop()
                        if not shop then
                            return
                        end
                        
                        local purchaseMade = false
                        
                        if EnabledSwordsBuy then
                            local currentTier = getCurrentSwordTier()
                            
                            for tier = 5, currentTier + 1, -1 do
                                if swords[tier] then
                                    local canBuy, item, shopId = canBuyItem(swords[tier], shop.Name)
                                    if canBuy then
                                        buyremote(item.itemType, shopId)
                                        purchaseMade = true
                                        break
                                    end
                                end
                            end
                        end
                        
                        if EnabledArmorBuy and not purchaseMade then
                            local currentTier = getCurrentArmorTier()
                            
                            if currentTier == 0 then
                                local canBuy, item, shopId = canBuyItem(armors[1], shop.Name)
                                if canBuy then
                                    buyremote(item.itemType, shopId)
                                    purchaseMade = true
                                end
                            elseif currentTier < 4 then
                                local canBuy, item, shopId = canBuyItem(armors[currentTier + 1], shop.Name)
                                if canBuy then
                                    buyremote(item.itemType, shopId)
                                    purchaseMade = true
                                end
                            end
                        end
                        
                        if purchaseMade then
                            task.wait(0.5)
                        end
                    end)
                    
                    if not success and err then
                        warn("AutoBuy error:", err)
                    end
                    
                    task.wait(0.2)
                end
            end)
            
            coroutine.resume(autoBuyCoroutine)
        end
    end
})

AutoBuy:CreateInfo("Automatically buys stuff for you!")

AutoBuy:CreateToggle({
    Name = "Buy Armor",
    StartingState = true,
    Callback = function(Callback)
        EnabledArmorBuy = Callback
    end
})

AutoBuy:CreateToggle({
    Name = "Buy Swords", 
    StartingState = true,
    Callback = function(Callback)
        EnabledSwordsBuy = Callback
    end
})

------Fly Module------
local flyEnabled = false
local secondstimer = "2.5s"
local firsttime = tick() + 2.5
local flydown = false
local flyup = false
local EnabledFly = false
local EnabledFlyButton = false
local FlyButtonEnabled = false
local flyactived = false
local FlyDown = false
local FlyUp = false

spawn(function()
	repeat
		task.wait()
		if IsAlive(LocalPlayer) then
			local onground = getPlacedBlock(LocalPlayer.character.HumanoidRootPart.Position + Vector3.new(0, (LocalPlayer.character.Humanoid.HipHeight * -2) - 1, 0))
			if onground then
				firsttime = tick() + 2.5
				flyEnabled = true
			end
			secondstimer = tostring(math.round((firsttime - tick()) * 10) / 10)
			if (firsttime - 0.6) < tick() then
				flyEnabled = false
			end
			if tonumber(secondstimer) <= 0 then
				secondstimer = "0"
			end
			FlyCounterInner.Size = UDim2.fromScale((tonumber(secondstimer) / 2.5), 1)
			FlyCounterText.Text = (secondstimer .. "s")
		end
	until not loop
end)

function flyfunc()
	if (EnabledFly or (FlyButtonEnabled and EnabledFlyButton)) and IsAlive(LocalPlayer) and not flyactived then
		flyactived = true
		task.spawn(function()
			velo = Instance.new("BodyVelocity")
			velo.MaxForce = Vector3.new(0, 9e9, 0)
			velo.Parent = LocalPlayer.Character.HumanoidRootPart
			local inputBeganConnection, inputEndedConnection
			inputBeganConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end
				if input.KeyCode == Enum.KeyCode.Space then
					flyup = true
				elseif input.KeyCode == Enum.KeyCode.LeftShift then
					flydown = true
				end
			end)
			inputEndedConnection = UIS.InputEnded:Connect( function(input, gameProcessed)
				if gameProcessed then
					return
				end
				if input.KeyCode == Enum.KeyCode.Space then
					flyup = false
				elseif input.KeyCode == Enum.KeyCode.LeftShift then
					flydown = false
				end
			end)
			spawn(function()
				repeat
					task.wait()
					if FlyCounterEnabled then
						FlyCounter.Visible = true
					else
						FlyCounter.Visible = false
					end
					if not ((EnabledFly or (FlyButtonEnabled and EnabledFlyButton)) and IsAlive(LocalPlayer)) then
						flyactived = false
					end
					local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
					local root = character:WaitForChild("HumanoidRootPart", 5)
					if FlyongroundEnabled and not flyEnabled then
						local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), blockRaycast)
						if ray then
							Flytppos = root.Position.Y
							velo.Velocity = Vector3.new(0, -10, 0)
							task.wait(0.12)
							root.CFrame = CFrame.new(root.CFrame.Position.X, ray.Position.Y + (root.Size.Y / 2) + character.Humanoid.HipHeight, root.CFrame.Position.Z) * root.CFrame.Rotation
							task.wait(0.12)
							if not (EnabledFly or (FlyButtonEnabled and EnabledFlyButton) and IsAlive(LocalPlayer)) then
								break
							end
							if Flytppos ~= -99999 and IsAlive(LocalPlayer) then
								root.CFrame = CFrame.new(root.CFrame.Position.X, Flytppos, root.CFrame.Position.Z) * root.CFrame.Rotation
							end
						end
					end
					local positioncheck = (flyup or FlyUp) and Vector3.new(0, (root.Size.Y / 2) + character.Humanoid.HipHeight - 0.5, 0) or (flydown or FlyDown) and Vector3.new(0, ((root.Size.Y / 2) + character.Humanoid.HipHeight - 0.5) * -1, 0) or Vector3.new(0, 0, 0)
					local blockResult = workspace:Blockcast(CFrame.new(character.HumanoidRootPart.Position), Vector3.new(3, 3, 3), positioncheck, blockRaycast)
					if not blockResult then
						velo.Velocity = Vector3.new(0, ((flyup or FlyUp) and UpValue or 0) + ((flydown or FlyDown) and -DownValue or 0), 0)
					else
						velo.Velocity = Vector3.new(0, 0, 0)
					end
				until not ((EnabledFly or (FlyButtonEnabled and EnabledFlyButton)) and IsAlive(LocalPlayer))
				FlyCounter.Visible = false
				if velo then
					velo:Destroy()
				end
				flyup = false
				flydown = false
				flyactived = false
				if inputBeganConnection then
					inputBeganConnection:Disconnect()
				end
				if inputEndedConnection then
					inputEndedConnection:Disconnect()
				end
			end)
		end)
	end
end

Fly = Blatant:CreateToggle({
	Name = "Fly",
	Callback = function(Callback)
		EnabledFly = Callback
		if EnabledFly then
			flyfunc()
		else
			flyactived = false
			FlyCounter.Visible = false
			if LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") then
				LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity"):Destroy()
			end
			flyup = false
			flydown = false
		end
	end
})
Fly:CreateInfo("Makes you a raven ;)")
Fly:CreateSlider({
	Name = "Up",
	Default = 50,
	Min = 0,
	Max = 100,
	Callback = function(Callback)
		UpValue = Callback
	end
})
Fly:CreateSlider({
	Name = "Down",
	Default = 50,
	Min = 0,
	Max = 100,
	Callback = function(Callback)
		DownValue = Callback
	end
})
Fly:CreateToggle({
	Name = "Fly Counter",
	StartingState = true,
	Callback = function(Callback)
		FlyCounterEnabled = Callback
	end
})
Fly:CreateToggle({
	Name = "TPDown",
	StartingState = true,
	SecondArrayitem = true,
	Callback = function(Callback)
		FlyongroundEnabled = Callback
	end
})
Fly:CreateToggle({
	Name = "FlyButton",
	Callback = function(Callback)
		EnabledFlyButton = Callback
		if EnabledFlyButton then
			FlyButton.Visible = true
		else
			FlyButton.Visible = false
			FlyButtonEnabled = false
		end
	end
})

FlyButton.MouseButton1Click:Connect(function()
	FlyButtonEnabled = not FlyButtonEnabled
	if FlyButtonEnabled and IsAlive(LocalPlayer) then
		task.spawn(function()
			local upButtonConnectionEnter, upButtonConnectionLeave, downButtonConnectionEnter, downButtonConnectionLeave
			local mouseInputBeganConnection, mouseInputEndedConnection
			upButtonConnectionEnter = UpButton.MouseEnter:Connect(function()
				hoveringUpButton2 = true
			end)
			upButtonConnectionLeave = UpButton.MouseLeave:Connect(function()
				hoveringUpButton2 = false
			end)
			downButtonConnectionEnter = DownButton.MouseEnter:Connect(function()
				hoveringDownButton2 = true
			end)
			downButtonConnectionLeave = DownButton.MouseLeave:Connect(function()
				hoveringDownButton2 = false
			end)
			mouseInputBeganConnection = UIS.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseButton1 and hoveringUpButton2 then
					FlyUp = true
				end
				if input.UserInputType == Enum.UserInputType.MouseButton1 and hoveringDownButton2 then
					FlyDown = true
				end
			end)
			mouseInputEndedConnection = UIS.InputEnded:Connect(function(input, gameProcessed)
				if gameProcessed then
					return
				end
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					FlyDown = false
					FlyUp = false
				end
			end)
			flyfunc()
			FlyButton:GetPropertyChangedSignal("Visible"):Connect(function()
				if not FlyButton.Visible then
					if upButtonConnectionEnter then
						upButtonConnectionEnter:Disconnect()
					end
					if upButtonConnectionLeave then
						upButtonConnectionLeave:Disconnect()
					end
					if downButtonConnectionEnter then
						downButtonConnectionEnter:Disconnect()
					end
					if downButtonConnectionLeave then
						downButtonConnectionLeave:Disconnect()
					end
					if mouseInputBeganConnection then
						mouseInputBeganConnection:Disconnect()
					end
					if mouseInputEndedConnection then
						mouseInputEndedConnection:Disconnect()
					end
				end
			end)
		end)
	end
end)

------HighJump Module------
HighJump = Blatant:CreateToggle({
	Name = "HighJump",
	Callback = function(Callback)
		HighJump = Callback
		if HighJump then
			JumpingConnect = LocalPlayer.Character.Humanoid.Jumping:Connect(function(IsJumping)
				if IsJumping then
					if IsAlive(LocalPlayer) then
						workspace.Gravity = 192.6
						LocalPlayer.Character.HumanoidRootPart.Velocity += Vector3.new(0, JumpHeight, 0)
						task.wait(0.2)
						workspace.Gravity = 10
						task.wait(0.6)
						workspace.Gravity = 192.6
					end
				end
			end)
		else
			JumpingConnect:Disconnect()
		end
	end
})
HighJump:CreateInfo("Makes you lebron James")
HighJump:CreateSlider({
	Name = "JumpHeight",
	Default = 50,
	Min = 0,
	Max = 500,
	Callback = function(Callback)
		JumpHeight = Callback
	end
})

------InfJump Module------
local CheckInfJump = false
Blatant:CreateToggle({
	Name = "INF Jump",
	Callback = function(Callback)
		EnabledINFJUMP = Callback
		if EnabledINFJUMP then
			CheckInfJump = true
			ConnectionINFJUMP = game:GetService("UserInputService").JumpRequest:Connect(function()
				game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
			end)
		else
			if CheckInfJump then
				ConnectionINFJUMP:Disconnect()
			end
		end
	end
})

------LongJump Module------
local LongJumpItem = false
LongJumpModule = Blatant:CreateToggle({
	Name = "LongJump",
	Callback = function(Callback)
		LongJump = Callback
		local JumpSpeed = 50
		local JumpDuration = 2 
		local JumpTick = 0 
		local Direction = Vector3.new(0, 0, 0)
		local connection 
		local ImmobilizeUntil = 0 
		if LongJump then
			local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end
			if not workspace:Raycast(root.Position, Vector3.new(0, -3, 0), blockRaycast) then 
				LongJumpModule:SetState(false)
				LongJumpItem = false
				return
			end

			local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
			local moveDir = humanoid and humanoid.MoveDirection or Vector3.new(0, 0, 0)
			Direction = moveDir.Magnitude > 0 and moveDir.Unit or root.CFrame.LookVector
			Direction = Vector3.new(Direction.X, 0, Direction.Z).Unit
			JumpTick = tick() + JumpDuration
			ImmobilizeUntil = tick() + 0.5

			local HRootPos = root.Position
			local Pos2 = HRootPos + Vector3.new(0, 2, 0)
			if GetItemNear("tnt") then
				game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@easy-games"):FindFirstChild("block-engine").node_modules:FindFirstChild("@rbxts").net.out._NetManaged.PlaceBlock:InvokeServer({
					["blockType"] = "tnt",
					["blockData"] = 0,
					["position"] = getserverpos(HRootPos)
				})
				LongJumpItem = true
			end
			if GetItemNear("fireball") then
				local inv = LocalPlayer.Character.InventoryFolder.Value
				game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.SetInvItem:InvokeServer({
					["hand"] = inv["fireball"]
				})
				game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.ProjectileFire:InvokeServer(
					inv["fireball"], "fireball", "fireball", Pos2, HRootPos, Vector3.new(0, -60, 0),
					game:GetService("HttpService"):GenerateGUID(true), {
					drawDurationSeconds = 1
				}, workspace:GetServerTimeNow() - 0.045
				)
				LongJumpItem = true
			end
			if LongJumpItem == false then 
				LongJumpModule:SetState(false)
				return
			end
			connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
				if not LongJump or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					if connection then
						connection:Disconnect()
					end
					return
				end
				root = LocalPlayer.Character.HumanoidRootPart
				if tick() < ImmobilizeUntil then
					root.Velocity = Vector3.new(0, 0, 0)
				elseif JumpTick > tick() and LongJumpItem then
					local rayOrigin = root.Position
					local rayDirection = Direction * 5
					local raycastParams = RaycastParams.new()
					raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
					raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
					local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
					if raycastResult then
						JumpTick = 0
						root.Velocity = Vector3.new(0, 0, 0)
					else
						root.Velocity = Vector3.new(Direction.X * JumpSpeed, 15, Direction.Z * JumpSpeed)
					end
				else
					root.Velocity = Vector3.new(0, 0, 0)
					if connection then
						connection:Disconnect()
					end
					LongJumpModule:SetState(false)
					LongJumpItem = false
				end
			end)
		else
			JumpTick = 0
			if connection then
				connection:Disconnect()
			end
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
			end
			LongJumpItem = false
		end
	end
})

------NoFall Module------
local NoFallEnabled = false
local FallMode = "FakeSend"
local firstfallpos = 0
local waitforflydown = false
local firsttime = 0

Nofall = Blatant:CreateToggle({
	Name = "NoFall",
	Callback = function(Callback)
		NoFallEnabled = Callback
		if Callback then
			if FallMode == "TimerTP" then
				local lplr = LocalPlayer
				local character = lplr.Character or lplr.CharacterAdded:Wait()
				local root = character:WaitForChild("HumanoidRootPart", 5)
				local humanoid = character:WaitForChild("Humanoid", 5)
				if not root or not humanoid then
					shared:createnotification("NoFall failed: Character not found", 5, "Error")
					return
				end

				local SAFE_FALL_VELOCITY = -77.5
				local raycastParams = RaycastParams.new()
				raycastParams.FilterDescendantsInstances = {character}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				local blockRaycast = RaycastParams.new()
				blockRaycast.FilterDescendantsInstances = {character}
				blockRaycast.FilterType = Enum.RaycastFilterType.Exclude

				local steppedConnection
				steppedConnection = RunService.PreSimulation:Connect(function(dt)
					if not NoFallEnabled or FallMode ~= "TimerTP" then
						steppedConnection:Disconnect()
						return
					end
					if not root.Parent or not humanoid.Parent then
						return
					end

					local rayOrigin = root.Position
					local rayDirection = Vector3.new(0, -1.5, 0)
					local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
					if not rayResult then
						local currentVelocity = root.AssemblyLinearVelocity
						if currentVelocity.Y <= 0 then
							if not waitforflydown then
								waitforflydown = true
								firstfallpos = root.Position.Y
								firsttime = tick()
							end
						else
							waitforflydown = false
						end
						local fallDistance = firstfallpos - root.Position.Y
						if fallDistance >= 10 then
							if (firsttime + 0.6) >= tick() then
								root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, SAFE_FALL_VELOCITY, currentVelocity.Z)
							else
								local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), blockRaycast)
								if ray then
									local getfirstfallposback = firstfallpos
									local beforegroundY = root.Position.Y
									local groundY = ray.Position.Y + humanoid.HipHeight + (root.Size.Y / 2)
									root.AssemblyLinearVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
									root.CFrame = CFrame.new(root.Position.X, groundY, root.Position.Z) * root.CFrame.Rotation
									waitforflydown = false
									firsttime = tick() + 2.5
									task.wait(0.12)
									root.CFrame = CFrame.new(root.Position.X, beforegroundY, root.Position.Z) * root.CFrame.Rotation
									firstfallpos = getfirstfallposback
								end
							end
						end
					else
						waitforflydown = false
					end
				end)

				local characterAddedConnection
				characterAddedConnection = lplr.CharacterAdded:Connect(function(newCharacter)
					if not NoFallEnabled or FallMode ~= "TimerTP" then
						characterAddedConnection:Disconnect()
						return
					end

					root = newCharacter:WaitForChild("HumanoidRootPart", 5)
					humanoid = newCharacter:WaitForChild("Humanoid", 5)
					raycastParams.FilterDescendantsInstances = {newCharacter}
					blockRaycast.FilterDescendantsInstances = {newCharacter}
				end)

				Nofall.Connections = Nofall.Connections or {}
				table.insert(Nofall.Connections, steppedConnection)
				table.insert(Nofall.Connections, characterAddedConnection)
			elseif FallMode == "FakeSend" then
				task.spawn(function()
					while NoFallEnabled and FallMode == "FakeSend" do
						if IsAlive(LocalPlayer) then
							local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
							if root and root.AssemblyLinearVelocity.Y < -70 then
								pcall(function()
									local netManaged = ReplicatedStorage:FindFirstChild("rbxts_include", true):FindFirstChild("node_modules", true):FindFirstChild("@rbxts", true):FindFirstChild("net", true):FindFirstChild("out", true):FindFirstChild("_NetManaged", true)
									if netManaged then
										netManaged:FindFirstChild("GroundHit"):FireServer(nil, Vector3.new(0, root.AssemblyLinearVelocity.Y, 0), workspace:GetServerTimeNow())
									end
									local ray = workspace:Raycast(root.Position, Vector3.new(0, root.AssemblyLinearVelocity.Y * 0.1, 0), blockRaycast)
									if ray then
										root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -80, root.AssemblyLinearVelocity.Z)
									end
								end)
							end
						end
						task.wait()
					end
				end)
			end
		else
			Nofall.Connections = Nofall.Connections or {}
			for _, connection in ipairs(Nofall.Connections) do
				pcall(function()
					connection:Disconnect()
				end)
			end
			Nofall.Connections = {}
		end
	end
})

Nofall:CreateDropDown({
	Name = "Mode",
	DefaultOption = "FakeSend",
	SecondArrayitem = true,
	Options = {"FakeSend"},
	Callback = function(Callback)
		FallMode = Callback
	end
})

------Speed Module------
local RavenzephyrOrb = 0
local DmgBoostTick = tick()
local DamageBoostEnabled = true
local PotionBoostEnabled = false
local NewSpeed = 23
local EnabledSpeed = false
local Jumpoptions = "Lowhop"
local raycastparameters = RaycastParams.new()

if game.PlaceId ~= 6872265039 then
	local oldZephyrUpdate = bedwars["ZephyrController"].updateJump
	bedwars["ZephyrController"].updateJump = function(self, orb, ...)
		RavenzephyrOrb = LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Health") > 0 and orb or 0
		return oldZephyrUpdate(self, orb, ...)
	end
end

task.spawn(function()
	bedwars["ClientHandler"]:WaitFor("EntityDamageEvent"):andThen(function(v)
		v:Connect(function(plr)
			if plr.entityInstance == LocalPlayer.Character and IsAlive(LocalPlayer) and DamageBoostEnabled then
				task.spawn(function()
					DmgBoostTick = tick() + 0.9
				end)
			end
		end)
	end)
end)

local function GetSpeed()
	local speed = 0
	if LocalPlayer.Character then
		local SpeedDamageBoost = LocalPlayer.Character:GetAttribute("SpeedBoost")
		if PotionBoostEnabled and SpeedDamageBoost and SpeedDamageBoost > 1 then
			speed = speed + (8 * (SpeedDamageBoost - 1))
			speed = speed - 4
		end
		if LocalPlayer.Character:GetAttribute("GrimReaperChannel") then
			speed = speed + 7
		end
		if RavenzephyrOrb ~= 0 then
			speed = speed + 10
		end
		if DmgBoostTick >= tick() then
			speed = speed + 22.5
		end
	end
	return speed - 1.5
end

local loop = LoopManager.new()
Speed = Blatant:CreateToggle({
	Name = "Speed",
	Callback = function(Callback)
		EnabledSpeed = Callback
		if EnabledSpeed then
			loop:AddTask("Speed", function(deltatime)
				if IsAlive(LocalPlayer) and EnabledSpeed then
					local FixedSpeed = GetSpeed() + NewSpeed
					local moveDirection = LocalPlayer.Character.Humanoid.MoveDirection
					local speedVector = moveDirection * ((FixedSpeed) - 20) * deltatime
					local root = LocalPlayer.Character.HumanoidRootPart
					local rayCheck = RaycastParams.new()
					rayCheck.FilterDescendantsInstances = {LocalPlayer.Character, workspace.CurrentCamera}
					rayCheck.CollisionGroup = root.CollisionGroup
					local ray = workspace:Raycast(root.Position, speedVector, rayCheck)

					if not ray then
						root.CFrame = root.CFrame + speedVector
						root.Velocity = (moveDirection * FixedSpeed) + Vector3.new(0, root.Velocity.Y, 0)
					end

					if LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum

.Material.Air and moveDirection ~= Vector3.zero and Jumpoptions ~= "" then
						if Jumpoptions == "Normal" then
						elseif Jumpoptions == "AutoJump" then
							LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						elseif Jumpoptions == "Lowhop" then
							local velocity = root.Velocity * Vector3.new(1, 0, 1)
							root.Velocity = Vector3.new(velocity.X, 10, velocity.Z)
						end
					end
				end
			end)
		else
			loop:Destroy()
		end
	end
})

Speed:CreateInfo("Makes you go zoooom")
Speed:CreateDropDown({
	Name = "Mode",
	DefaultOption = "Lowhop",
	SecondArrayitem = true,
	Options = {"Normal", "AutoJump", "Lowhop"},
	Callback = function(Callback)
		Jumpoptions = Callback
	end
})
Speed:CreateSlider({
	Name = "Speed",
	Default = 23,
	Min = 0,
	Max = 23,
	Callback = function(Callback)
		NewSpeed = Callback
	end
})
Speed:CreateToggle({
	Name = "PotionBoost",
	StartingState = true,
	Callback = function(Callback)
		PotionBoostEnabled = Callback
	end
})

------Spider Module------
local SpiderEnabled = false
local SpiderActive = false
local SpiderSpeed = 50
local loop = LoopManager.new()

Spider = Blatant:CreateToggle({
	Name = "Spider",
	Callback = function(Callback)
		SpiderEnabled = Callback
		if SpiderEnabled then
			loop:AddTask("Spider", function()
				if not IsAlive(LocalPlayer) then
					SpiderActive = false
					return
				end
				local vec = LocalPlayer.Character.Humanoid.MoveDirection * 2
				local newray = getPlacedBlock(LocalPlayer.Character.HumanoidRootPart.Position + (vec + Vector3.new(0, 0.1, 0)))
				local newray2 = getPlacedBlock(LocalPlayer.Character.HumanoidRootPart.Position + (vec - Vector3.new(0, LocalPlayer.Character.Humanoid.HipHeight, 0)))
				if newray and (not newray.CanCollide) then
					newray = nil
				end
				if newray2 and (not newray2.CanCollide) then
					newray2 = nil
				end
				if SpiderActive and (not newray) and (not newray2) then
					LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(LocalPlayer.Character.HumanoidRootPart.Velocity.X, 0, LocalPlayer.Character.HumanoidRootPart.Velocity.Z)
				end
				SpiderActive = ((newray or newray2) and true or false)
				if (newray or newray2) then
					LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(newray2 and newray == nil and LocalPlayer.Character.HumanoidRootPart.Velocity.X or 0, SpiderSpeed or 50, newray2 and newray == nil and LocalPlayer.Character.HumanoidRootPart.Velocity.Z or 0)
				end
			end)
		else
			loop:Destroy()
			SpiderActive = false
			loop = LoopManager.new()
		end
	end
})
Spider:CreateInfo("Spiderman!")
Spider:CreateSlider({
	Name = "Speed",
	Default = 50,
	Min = 0,
	Max = 150,
	Callback = function(Callback)
		SpiderSpeed = Callback
	end
})

------Render Modules------
local Sky
Render:CreateToggle({
	Name = "Galaxy Sky",
	Callback = function(Callback)
		SkyEnabled = Callback
		if SkyEnabled then
			Sky = Instance.new("Sky")
			ID = 8281961896
			Sky.SkyboxBk = "http://www.roblox.com/asset/?id=" .. ID
			Sky.SkyboxDn = "http://www.roblox.com/asset/?id=" .. ID
			Sky.SkyboxFt = "http://www.roblox.com/asset/?id=" .. ID
			Sky.SkyboxLf = "http://www.roblox.com/asset/?id=" .. ID
			Sky.SkyboxRt = "http://www.roblox.com/asset/?id=" .. ID
			Sky.SkyboxUp = "http://www.roblox.com/asset/?id=" .. ID
			Sky.Parent = Lighting
		else
			if Sky then
				Sky:Destroy()
			end
		end
	end
})

local Atmosphere
Render:CreateToggle({
	Name = "Atmosphere",
	Callback = function(Callback)
		AtmoEnabled = Callback
		if AtmoEnabled then
			Atmosphere = Instance.new("ColorCorrectionEffect")
			Atmosphere.TintColor = Color3.fromHSV(0.7, 0.05, 0.7)
			Atmosphere.Parent = Lighting
		else
			if Atmosphere then
				Atmosphere:Destroy()
			end
		end
	end
})

local oldfov
local oldfov2
FOV = Render:CreateToggle({
	Name = "FOV",
	Callback = function(Callback)
		FOVEnabled = Callback
		if FOVEnabled then
			task.wait(1)
			if not FOVEnabled then
				return
			end
			oldfov = bedwars["FovController"].setFOV
			oldfov2 = bedwars["FovController"].getFOV
			bedwars["FovController"].setFOV = function(self, fov)
				return oldfov(self, FOVValue)
			end
			bedwars["FovController"].getFOV = function(self, fov)
				return FOVValue
			end
		else
			bedwars["FovController"].setFOV = oldfov
			bedwars["FovController"].getFOV = oldfov2
		end
		bedwars["FovController"]:setFOV(bedwars["ClientHandlerStore"]:getState().Settings.fov)
	end
})
FOV:CreateInfo("Makes you see the end of time")
FOV:CreateSlider({
	Name = "FOV",
	Default = 120,
	Min = 0,
	Max = 120,
	Callback = function(Callback)
		FOVValue = Callback
	end
})

local ViewModelChangerEnabled = false
ViewModelChanger = Render:CreateToggle({
	Name = "ViewModelChanger",
	Callback = function(Callback)
		ViewModelChangerEnabled = Callback
		local viewmodel = Camera:FindFirstChild("Viewmodel")
		if viewmodel and ViewModelChangerEnabled == true then
			print("Viewmodel offset")
			bedwars.ViewmodelController:setHeldItem(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HandInvItem") and LocalPlayer.Character.HandInvItem.Value and LocalPlayer.Character.HandInvItem.Value:Clone())
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(8 / 10))
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (8 / 10))
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (0 / 10))
		else
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", 0)
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", 0)
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", 0)
		end
	end
})
ViewModelChanger:CreateInfo("Change the Sword Position!")
ViewModelChanger:CreateSlider({
	Name = "Foward",
	Default = 10,
	Min = 0,
	Max = 50,
	Callback = function(Callback)
		if ViewModelChangerEnabled then
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_DEPTH_OFFSET", -(Callback / 10))
		end
	end
})
ViewModelChanger:CreateSlider({
	Name = "Side",
	Default = 0,
	Min = 0,
	Max = 50,
	Callback = function(Callback)
		if ViewModelChangerEnabled then
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_HORIZONTAL_OFFSET", (Callback / 10))
		end
	end
})
ViewModelChanger:CreateSlider({
	Name = "Up",
	Default = 0,
	Min = 0,
	Max = 50,
	Callback = function(Callback)
		if ViewModelChangerEnabled then
			LocalPlayer.PlayerScripts.TS.controllers.global.viewmodel["viewmodel-controller"]:SetAttribute("ConstantManager_VERTICAL_OFFSET", (Callback / 10))
		end
	end
})

local round = function(...)
	local a = {}
	for i, v in next, table.pack(...) do
		a[i] = math.round(v)
	end
	return unpack(a)
end

local wtvp = function(...)
	local a, b = Camera.WorldToViewportPoint(Camera, ...)
	return Vector2.new(a.X, a.Y), b, a.Z
end

local Esptable = {}
local function createEsp(plr)
	local drawings = {}
	drawings.box = Drawing.new("Square")
	drawings.box.Thickness = 1
	drawings.box.Filled = false
	drawings.box.Color = Color3.new(255, 255, 255)
	drawings.box.Visible = false
	drawings.box.ZIndex = 2
	Esptable[plr] = drawings
end

local function removeEsp(plr)
	if rawget(Esptable, plr) then
		for _, drawing in next, Esptable[plr] do
			drawing:Remove()
		end
		Esptable[plr] = nil
	end
end

local function updateEsp(plr, esp)
	local character = plr and plr.Character
	if character then
		local cframe = character:GetModelCFrame()
		local position, visible, depth = wtvp(cframe.Position)
		esp.box.Visible = visible
		if cframe and visible then
			local scaleFactor = 1 / (depth * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
			local width, height = round(4 * scaleFactor, 5 * scaleFactor)
			local x, y = round(position.X, position.Y)
			esp.box.Size = Vector2.new(width, height)
			esp.box.Position = Vector2.new(round(x - width / 2, y - height / 2))
			esp.box.Color = ESPTeamCheck and plr.TeamColor.Color or Color3.fromRGB(255, 255, 255)
		end
	else
		esp.box.Visible = false
	end
end

Players.PlayerAdded:Connect(function(player)
	if EnabledESP then
		createEsp(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if EnabledESP then
		removeEsp(player)
	end
end)

ESP = Render:CreateToggle({
	Name = "ESP",
	Callback = function(Callback)
		EnabledESP = Callback
		if EnabledESP then
			for i, v in next, Players:GetPlayers() do
				if v ~= LocalPlayer then
					createEsp(v)
				end
			end
			repeat
				task.wait()
				for i, v in next, Esptable do
					if v and i ~= LocalPlayer then
						updateEsp(i, v)
					end
				end
			until not EnabledESP
		else
			for i, v in next, Players:GetPlayers() do
				if v ~= LocalPlayer then
					removeEsp(v)
				end
			end
		end
	end
})
ESP:CreateInfo("Makes you see people through walls O-O")
ESP:CreateToggle({
	Name = "TeamCheck",
	StartingState = true,
	Callback = function(Callback)
		ESPTeamCheck = Callback
	end
})

Render:CreateToggle({
	Name = "FPS Unlocker",
	Callback = function(Callback)
		EnabledFPS = Callback
		if EnabledFPS then
			setfpscap(120)
		end
	end
})

local old2
local old
basetextures = {}
local function fpsboosttextures()
	task.spawn(function()
		repeat
			task.wait()
		until GetMatchState() ~= 0
		for i, v in next, (collectionService:GetTagged("block")) do
			if v:GetAttribute("PlacedByUserId") == 0 then
				v.Material = FPSBoostEnabled and FPSBoostTextureEnabled and Enum.Material.SmoothPlastic
				basetextures[v] = basetextures[v] or v.MaterialVariant
				v.MaterialVariant = FPSBoostEnabled and FPSBoostTextureEnabled and "" or basetextures[v]
				for i2, v2 in next, (v:GetChildren()) do
					pcall(function()
						v2.Material = FPSBoostEnabled and FPSBoostTextureEnabled and Enum.Material.SmoothPlastic
						basetextures[v2] = basetextures[v2] or v2.MaterialVariant
						v2.MaterialVariant = FPSBoostEnabled and FPSBoostTextureEnabled and "" or basetextures[v2]
					end)
				end
			end
		end
	end)
end

FPSBoost = Render:CreateToggle({
	Name = "FPS Boost",
	Callback = function(Callback)
		FPSBoostEnabled = Callback
		if FPSBoostEnabled then
			fpsboosttextures()
			for i, v in next, (bedwars["KillEffectController"].killEffects) do
				basetextures[i] = v
				bedwars["KillEffectController"].killEffects[i] = {
					new = function(char)
						return {
							onKill = function()
							end,
							isPlayDefaultKillEffect = function()
								return char == LocalPlayer.Character
							end
						}
					end
				}
			end
			old = bedwars["HighlightController"].highlight
			old2 = getmetatable(bedwars["StopwatchController"]).tweenOutGhost
			getmetatable(bedwars["StopwatchController"]).tweenOutGhost = function(p17, p18)
				p18:Destroy()
			end
			bedwars["HighlightController"].highlight = function()
			end
		else
			for i, v in next, (basetextures) do
				bedwars["KillEffectController"].killEffects[i] = v
			end
			fpsboosttextures()
			debug.setupvalue(bedwars["KillEffectController"].KnitStart, 2, bedwars["ClientSyncEvents"])
			bedwars["HighlightController"].highlight = old
			getmetatable(bedwars["StopwatchController"]).tweenOutGhost = old2
			old = nil
			old2 = nil
		end
	end
})
FPSBoost:CreateToggle({
	Name = "Remove Textures",
	StartingState = true,
	Callback = function(Callback)
		FPSBoostTextureEnabled = Callback
	end
})

local Messages = {
	"RavenB4",
	"AC?",
	"What AC?",
	"Devs?",
	"P2w < Raven",
	"Inf Dmg",
	"Hide in my sock"
}

local old69
Render:CreateToggle({
	Name = "Raven Dmg Indicator",
	Callback = function(Callback)
		EnabledIndicator = Callback
		if EnabledIndicator then
			debug.getupvalue(bedwars["DamageIndicator"], 10, {Create = old69})
			debug.setupvalue(bedwars["DamageIndicator"], 10, {
				Create = function(self, obj, ...)
					spawn(function()
						pcall(function()
							obj.Parent.Text = Messages[math.random(1, #Messages)]
							obj.Parent.TextColor3 = Color3.fromRGB(154, 55, 212)
						end)
					end)
					return game:GetService("TweenService"):Create(obj, ...)
				end
			})
		else
			debug.setupvalue(bedwars["DamageIndicator"], 10, {Create = old69})
			old69 = nil
		end
	end
})

Render:CreateToggle({
	Name = "Custom Sounds",
	Callback = function(Callback)
		CustomSounds = Callback
		if CustomSounds then
			local oldbedwarssoundtable = {
				["QUEUE_JOIN"] = "rbxassetid://6691735519",
				["QUEUE_MATCH_FOUND"] = "rbxassetid://6768247187",
				["UI_CLICK"] = "rbxassetid://6732690176",
				["UI_OPEN"] = "rbxassetid://6732607930",
				["BEDWARS_UPGRADE_SUCCESS"] = "rbxassetid://6760677364",
				["BEDWARS_PURCHASE_ITEM"] = "rbxassetid://6760677364",
				["SWORD_SWING_1"] = "rbxassetid://6760544639",
				["SWORD_SWING_2"] = "rbxassetid://6760544595",
				["DAMAGE_1"] = "rbxassetid://6765457325",
				["DAMAGE_2"] = "rbxassetid://6765470975",
				["DAMAGE_3"] = "rbxassetid://6765470941",
				["PICKUP_ITEM_DROP"] = "rbxassetid://6768578304",
				["ARROW_HIT"] = "rbxassetid://6866062188",
				["ARROW_IMPACT"] = "rbxassetid://6866062148",
				["KILL"] = "rbxassetid://7013482008",
			}
			for i, v in next, (bedwars["CombatController"].killSounds) do
				bedwars["CombatController"].killSounds[i] = oldbedwarssoundtable.KILL
			end
			for i, v in next, (oldbedwarssoundtable) do
				local item = bedwars["SoundList"][i]
				if item then
					bedwars["SoundList"][i] = v
				end
			end
		end
	end
})

------Utility Modules------
local tiered = {}
local nexttier = {}
Utility:CreateToggle({
	Name = "ShoptierBypass",
	Callback = function(Callback)
		if Callback then
			for i, v in pairs(bedwars["ShopItems"]) do
				tiered[v] = v.tiered
				nexttier[v] = v.nextTier
				v.nextTier = nil
				v.tiered = nil
			end
		else
			for i, v in tiered do
				i.tiered = v
			end
			for i, v in nexttier do
				i.nextTier = v
			end
			table.clear(nexttier)
			table.clear(tiered)
		end
	end
})

local lowestypos = math.huge
AntiVoid = Utility:CreateToggle({
	Name = "AntiVoid",
	Callback = function(Callback)
		AntiVoidEnabled = Callback
		if AntiVoidEnabled then
			lowestypos = 99999
			for i, v in pairs(game:GetService("CollectionService"):GetTagged("block")) do
				local newray = workspace:Raycast(v.Position + Vector3.new(0, 800, 0), Vector3.new(0, -1000, 0), RaycastParams.new())
				if newray and newray.Position.Y <= lowestypos then
					lowestypos = newray.Position.Y
				end
			end
			AntiVoidPart = Instance.new("Part")
			AntiVoidPart.Size = Vector3.new(10000, 1, 10000)
			AntiVoidPart.Anchored = true
			AntiVoidPart.Material = Enum.Material.Neon
			AntiVoidPart.Parent = workspace
			AntiVoidPart.Position = Vector3.new(0, (lowestypos - 8), 0)
			AntiVoidPart.Color = Color3.fromHSV(0, 100, 50)
			AntiVoidPart.Transparency = 1 - (0 / 100)
			spawn(function()
				while task.wait() do
					AntiVoidPart.Color = Color3.fromHSV(AntiVoidColor, 100, 50)
					AntiVoidPart.Transparency = 1 - (AntiVoidTransparency / 100)
				end
			end)
			AntiVoidConnection = AntiVoidPart.Touched:Connect(function(touchedpart)
				if touchedpart.Parent == LocalPlayer.Character and IsAlive(LocalPlayer) and LocalPlayer.Character.Humanoid.Health > 0 then
					LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(LocalPlayer.Character.HumanoidRootPart.Velocity.X, AntiVoidHeight, LocalPlayer.Character.HumanoidRootPart.Velocity.Z)
				end
			end)
		else
			if AntiVoidConnection then
				AntiVoidConnection:Disconnect()
			end
			if AntiVoidPart then
				AntiVoidPart:Destroy()
			end
		end
	end
})
AntiVoid:CreateInfo("Makes the void useless!")
AntiVoid:CreateSlider({
	Name = "Height",
	Default = 100,
	Min = 50,
	Max = 250,
	Callback = function(Callback)
		AntiVoidHeight = Callback
	end
})
AntiVoid:CreateSlider({
	Name = "Color",
	Default = 89,
	Min = 0,
	Max = 100,
	Callback = function(Callback)
		AntiVoidColor = (Callback / 100)
	end
})
AntiVoid:CreateSlider({
	Name = "Transparency",
	Default = 50,
	Min = 0,
	Max = 100,
	Callback = function(Callback)
		AntiVoidTransparency = Callback
	end
})
------BedNuker Module------
local BedNukerEnabled = false
local BedDistance = 30
local BreakSpeed = 0.25
local BedNukerAnimation = false
local HighlightBlockEnabled = false

BedNuker = Utility:CreateToggle({
	Name = "BedNuker",
	Callback = function(Callback)
		BedNukerEnabled = Callback
		if BedNukerEnabled then
			repeat
				local success, loopResult = pcall(function()
					task.wait(BreakSpeed)
					if not BedNukerEnabled then
						return false
					end
					if IsAlive(LocalPlayer) then
						local localPosition = LocalPlayer.Character.HumanoidRootPart.Position
						local beds = GetBeds()
						for _, bed in pairs(beds) do
							local mag = (bed.Position - localPosition).Magnitude
							if mag < BedDistance and bedwars["BlockEngine"]:isBlockBreakable({
								blockPosition = getserverpos(bed.Position)
							}, LocalPlayer) and not ((bed:GetAttribute("BedShieldEndTime") or 0) > workspace:GetServerTimeNow()) then
								break
							end
						end
						for _, bed in pairs(beds) do
							local mag = (bed.Position - localPosition).Magnitude
							if mag < BedDistance and bedwars["BlockEngine"]:isBlockBreakable({
								blockPosition = getserverpos(bed.Position)
							}, LocalPlayer) and not ((bed:GetAttribute("BedShieldEndTime") or 0) > workspace:GetServerTimeNow()) then
								print("Breaking bed at: " .. tostring(bed.Position))
								local wasBroken = breakBlock(bed, BedDistance, HighlightBlockEnabled)
								if not wasBroken then
									endnuker()
									return true
								end
								if BedNukerAnimation then
									local animation = bedwars["AnimationUtil"]:playAnimation(LocalPlayer, bedwars["BlockEngine"]:getAnimationController():getAssetId(1))
									bedwars.ViewmodelController:playAnimation(15)
									task.wait(0.3)
									animation:Stop()
									animation:Destroy()
								end
							else
								endnuker()
							end
						end
					end
					return true
				end)
				if not success then
					print("Error in BedNuker loop: " .. tostring(loopResult))
				end
				if not loopResult then
					break
				end
			until not BedNukerEnabled
		else
			shared.parts[1].Position = Vector3.new(0, -1000, 0)
			endnuker()
		end
	end
})

BedNuker:CreateInfo("Automatically breaks enemy beds within range")
BedNuker:CreateToggle({
	Name = "Animation",
	Callback = function(Callback)
		BedNukerAnimation = Callback
	end
})
BedNuker:CreateToggle({
	Name = "Highlight",
	Callback = function(Callback)
		HighlightBlockEnabled = Callback
	end
})
BedNuker:CreateSlider({
	Name = "Range",
	Default = 30,
	Min = 1,
	Max = 30,
	Callback = function(Callback)
		BedDistance = Callback
	end
})
BedNuker:CreateSlider({
	Name = "Break Speed",
	Default = 25,
	Min = 0,
	Max = 30,
	Callback = function(Callback)
		BreakSpeed = Callback / 100
	end
})

------ChestStealer Module------
local EnabledChestStealer = false

ChestStealer = Utility:CreateToggle({
	Name = "ChestStealer",
	Callback = function(Callback)
		EnabledChestStealer = Callback
		if EnabledChestStealer then
			if GetQueueType():find("skywars") and GetQueueType() ~= "bedwars_test" then
				repeat
					task.wait()
					if IsAlive(LocalPlayer) then
						for _, v in pairs(game:GetService("CollectionService"):GetTagged("chest")) do
							if (LocalPlayer.Character.HumanoidRootPart.Position - v.Position).Magnitude < 18 and v:FindFirstChild("ChestFolderValue") then
								local chest = v:FindFirstChild("ChestFolderValue")
								chest = chest and chest.Value or nil
								local chestitems = chest and chest:GetChildren() or {}
								if #chestitems > 0 then
									game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged:FindFirstChild("Inventory/SetObservedChest"):FireServer(chest)
									for _, v3 in pairs(chestitems) do
										if v3:IsA("Accessory") then
											spawn(function()
												pcall(function()
													game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged:FindFirstChild("Inventory/ChestGetItem"):InvokeServer(v.ChestFolderValue.Value, v3)
												end)
											end)
										end
									end
									game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged:FindFirstChild("Inventory/SetObservedChest"):FireServer(nil)
								end
							end
						end
					end
				until not EnabledChestStealer
			end
		end
	end
})

ChestStealer:CreateInfo("Steals items from beds")

------AutoKit Module------
local AutoKitEnabled = false

Utility:CreateToggle({
	Name = "AutoKit",
	Callback = function(Callback)
		AutoKitEnabled = Callback
		if AutoKitEnabled then
			repeat
				task.wait(0.1)
				if IsAlive(LocalPlayer) then
					local infernal = GetItemNear("infernal_saber")
					if infernal then
						switchItem(infernal.tool)
						game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.HellBladeRelease:FireServer({
							["chargeTime"] = 0.5,
							["player"] = LocalPlayer,
							["weapon"] = infernal.tool
						})
					end
					if RavenEquippedKit == "hannah" then
						for _, v in pairs(game:GetService("Players"):GetChildren()) do
							if v.Team ~= LocalPlayer.Team and IsAlive(v) and IsAlive(LocalPlayer) and not v.Character:FindFirstChildOfClass("ForceField") then
								game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.HannahPromptTrigger:InvokeServer({
									["victimEntity"] = v.Character,
									["user"] = LocalPlayer
								})
							end
						end
					elseif RavenEquippedKit == "metal_detector" then
						local itemdrops = collectionService:GetTagged("hidden-metal")
						for _, v in pairs(itemdrops) do
							if IsAlive(LocalPlayer) and v.PrimaryPart and (LocalPlayer.Character.HumanoidRootPart.Position - v.PrimaryPart.Position).Magnitude <= 20 then
								game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.PickupMetalRemote:InvokeServer({
									id = v:GetAttribute("Id")
								})
							end
						end
					elseif RavenEquippedKit == "bigman" then
						local itemdrops = collectionService:GetTagged("treeOrb")
						for _, v in pairs(itemdrops) do
							if v:FindFirstChild("Spirit") and (LocalPlayer.Character.HumanoidRootPart.Position - v.Spirit.Position).Magnitude <= 20 then
								if game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.ConsumeTreeOrb:InvokeServer({
									treeOrbSecret = v:GetAttribute("TreeOrbSecret")
								}) then
									v:Destroy()
									collectionService:RemoveTag(v, "treeOrb")
								end
							end
						end
					elseif RavenEquippedKit == "grim_reaper" then
						local itemdrops = bedwars["GrimReaperController"].soulsByPosition
						for _, v in pairs(itemdrops) do
							if IsAlive(LocalPlayer) and LocalPlayer.Character:GetAttribute("Health") <= (LocalPlayer.Character:GetAttribute("MaxHealth") / 4) and v.PrimaryPart and (LocalPlayer.Character.HumanoidRootPart.Position - v.PrimaryPart.Position).Magnitude <= 120 and not LocalPlayer.Character:GetAttribute("GrimReaperChannel") then
								game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.ConsumeSoulRemote:InvokeServer({
									secret = v:GetAttribute("GrimReaperSoulSecret")
								})
								v:Destroy()
							end
						end
					elseif RavenEquippedKit == "miner" then
						if IsAlive(LocalPlayer) then
							for _, v in pairs(collectionService:GetTagged("petrified-player")) do
								game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.MinerRemote:InvokeServer({
									petrifyId = v:GetAttribute("PetrifyId")
								})
							end
						end
					end
				end
			until not AutoKitEnabled
		end
	end
})

------Scaffold Module------
local adjacent = {}
local ScaffoldEnabled = false
local ScaffoldButtonEnabled = false
local ScaffoldButtonEnabled2 = false
local BuildAnimation = true
local TowerEnabled = true
local isShowBlockCountActive = false
local WoolOnlyEnabled = false
local LimitItemEnabled = false
local BlockCountEnabled = false
local alreadyscaffolded = false
local DiagonalEnabled = true
local lastpos = nil
local blockCountLabel = Instance.new("TextLabel")
blockCountLabel.Parent = shared.ScreenGui2
blockCountLabel.BackgroundTransparency = 1
blockCountLabel.Position = UDim2.new(0.515, 0, 0.429, 0)
blockCountLabel.Size = UDim2.new(0, 122, 0, 30)
blockCountLabel.FontFace = Font.new(getcustomasset("RavenB4/MCReg.json"))
blockCountLabel.Text = "Blocks: 0"
blockCountLabel.TextColor3 = Color3.new(1, 1, 1)
blockCountLabel.TextSize = 20
blockCountLabel.Visible = false
blockCountLabel.RichText = true

for x = -3, 3, 3 do
	for y = -3, 3, 3 do
		for z = -3, 3, 3 do
			local vec = Vector3.new(x, y, z)
			if vec ~= Vector3.zero then
				table.insert(adjacent, vec)
			end
		end
	end
end


local function checkAdjacent(pos)
	for _, v in ipairs(adjacent) do
		if getPlacedBlock(pos + v) then
			return true
		end
	end
	return false
end

local function getScaffoldBlock()
	local currentHand = GetInventory(LocalPlayer).items[1]
	if currentHand and bedwars["ItemMeta"][currentHand.itemType].block then
		local isWool = currentHand.itemType:find("wool") ~= nil
		if not WoolOnlyEnabled or isWool then
			return currentHand.itemType, currentHand.amount or 0
		end
	elseif not LimitItemEnabled then
		local wool, amount = getWool()
		if wool then
			return wool, amount
		elseif not WoolOnlyEnabled then
			for _, item in ipairs(GetInventory(LocalPlayer).items) do
				if bedwars["ItemMeta"][item.itemType].block then
					return item.itemType, item.amount or 0
				end
			end
		end
	end
	return nil, 0
end

local loop = LoopManager.new()
local function runScaffold()
	if (ScaffoldEnabled or (ScaffoldButtonEnabled and ScaffoldButtonEnabled2)) and not alreadyscaffolded then
		alreadyscaffolded = true
		loop:AddTask("ScaffoldMain", function()
			if not IsAlive(LocalPlayer) then
				alreadyscaffolded = false
				loop:Destroy()
				loop = LoopManager.new()
				return
			end
			local wool, amount = getScaffoldBlock()
			if wool then
				if isShowBlockCountActive then
					RunService.RenderStepped:Wait()
					blockCountLabel.Text = '<stroke color="#000000" thickness="1" transparency="0.25">' .. "Blocks: " .. tostring((math.round(amount) or 0)) .. '</stroke>'
				end
				local root = LocalPlayer.Character.HumanoidRootPart
				if TowerEnabled and UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:GetFocusedTextBox() then
					root.Velocity = Vector3.new(root.Velocity.X, 23, root.Velocity.Z)
				end
				local currentpos = Vector3.new(
					math.round(root.Position.X),
					math.round(root.Position.Y - (LocalPlayer.Character.Humanoid.HipHeight + 1.5)),
					math.round(root.Position.Z)
				) + LocalPlayer.Character.Humanoid.MoveDirection * 3
				local block, blockpos = getPlacedBlock(currentpos)
				if not block then
					blockpos = checkAdjacent(blockpos * 3) and blockpos * 3
					if blockpos then
						if BuildAnimation then
							bedwars["ViewmodelController"]:playAnimation(bedwars["AnimationType"].FP_USE_ITEM)
						end
						local fakeBlock = Instance.new("Part")
						fakeBlock.Size = Vector3.new(3, 3, 3)
						fakeBlock.Position = blockpos
						fakeBlock.Transparency = 1
						fakeBlock.CanCollide = true
						fakeBlock.Anchored = true
						fakeBlock.Parent = workspace
						placeblock(wool, blockpos)
						fakeBlock:Destroy()
					end
				end
			end
			if not (ScaffoldEnabled or (ScaffoldButtonEnabled and ScaffoldButtonEnabled2)) then
				alreadyscaffolded = false
				loop:Destroy()
				loop = LoopManager.new()
			end
		end)
	end
end
Scaffold = Utility:CreateToggle({
	Name = "Scaffold",
	Callback = function(Callback)
		ScaffoldEnabled = Callback
		blockCountLabel.Visible = Callback and isShowBlockCountActive
		if ScaffoldEnabled then
			runScaffold()
		else
			alreadyscaffolded = false
			loop:Destroy()
			loop = LoopManager.new()
		end
	end
})
Scaffold:CreateInfo("Builds a bridge for you!")

Scaffold:CreateToggle({
	Name = "Tower",
	StartingState = true,
	Callback = function(Callback)
		TowerEnabled = Callback
	end
})

Scaffold:CreateToggle({
	Name = "Wool Only",
	Callback = function(Callback)
		WoolOnlyEnabled = Callback
	end
})

Scaffold:CreateToggle({
	Name = "Limit to items",
	Callback = function(Callback)
		LimitItemEnabled = Callback
	end
})

Scaffold:CreateToggle({
	Name = "Blockcount",
	StartingState = true,
	Callback = function(Callback)
		isShowBlockCountActive = Callback
		blockCountLabel.Visible = ScaffoldEnabled and isShowBlockCountActive
	end
})
Scaffold:CreateToggle({
	Name = "Animation",
	StartingState = true,
	Callback = function(Callback)
		BuildAnimation = Callback
	end
})

Scaffold:CreateToggle({
	Name = "Scaffold Button",
	Callback = function(Callback)
		ScaffoldButtonEnabled = Callback
		LongjumpButton.Visible = Callback
	end
})

LongjumpButton.MouseButton1Click:Connect(function()
	ScaffoldButtonEnabled2 = not ScaffoldButtonEnabled2
	LongjumpButton.BackgroundColor3 = ScaffoldButtonEnabled2 and Color3.new(0, 255, 0) or Color3.new(0, 0, 0)
	if ScaffoldButtonEnabled2 then
		runScaffold()
	else
		alreadyscaffolded = false
		loop:Destroy()
		loop = LoopManager.new()
	end
end)

------NoSlowdown Module------
local OldSetSpeedFunc

Utility:CreateToggle({
	Name = "NoSlowdown",
	Callback = function(Callback)
		if Callback then
			OldSetSpeedFunc = bedwars["SprintController"].setSpeed
			bedwars["SprintController"].setSpeed = function(v, i)
				if LocalPlayer.Character and LocalPlayer.Character.Humanoid then
					LocalPlayer.Character.Humanoid.WalkSpeed = math.max(20 * v.moveSpeedMultiplier, 20)
				end
			end
			bedwars["SprintController"]:setSpeed(20)
		else
			bedwars["SprintController"].setSpeed = OldSetSpeedFunc
			bedwars["SprintController"]:setSpeed(20)
			OldSetSpeedFunc = nil
		end
	end
})

------AutoReport Module------
local repotedplayer = {}

Utility:CreateToggle({
	Name = "AutoReport",
	Callback = function(Callback)
		AutoReport = Callback
		if AutoReport then
			for _, v in pairs(Players:GetPlayers()) do
				if v ~= LocalPlayer and repotedplayer[v] ~= true then
					task.wait(1)
					game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@easy-games"):FindFirstChild("block-engine").node_modules:FindFirstChild("@rbxts").net.out._NetManaged.ReportPlayer:InvokeServer(v.UserId)
					repotedplayer[v] = true
				end
			end
		end
	end
})

------AntiAFK Module------
local AntiAFKEnabled = false

Utility:CreateToggle({
	Name = "Anti AFK",
	Callback = function(Callback)
		AntiAFKEnabled = Callback
		if AntiAFKEnabled then
			repeat
				task.wait(10)
				bedwars["ClientHandler"]:Get("AfkInfo"):SendToServer({
					afk = false
				})
			until not AntiAFKEnabled
		end
	end
})

if shared.RavenB4Started == nil then
	shared.RavenB4Completed = true
end
