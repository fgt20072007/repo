local RS 			= game.ReplicatedStorage
local ACS_Workspace = workspace:WaitForChild("ACS_WorkSpace")
local Engine 		= RS:WaitForChild("ACS_MICTLAN")
local Evt 			= Engine:WaitForChild("Events")
local FX            = Engine:FindFirstChild("FX")
local Mods 			= Engine:WaitForChild("Modules")
local ArmModel 		= Engine:WaitForChild("ArmModel")
local GunModels 	= Engine:WaitForChild("GunModels")
local GunHolster	= Engine:WaitForChild("GunHolster")

local HUDs 			= Engine:WaitForChild("HUD")
local AttModels 	= Engine:WaitForChild("AttModels")
local AttModules  	= Engine:WaitForChild("AttModules")
local Rules			= Engine:WaitForChild("GameRules")
local SVGunModels 	= Engine:WaitForChild("GrenadeModels")
local gameRules		= require(Rules:WaitForChild("Config"))
local CombatLog		= require(Rules:WaitForChild("CombatLog"))
local SpringMod 	= require(Mods:WaitForChild("Spring"))
local HitMod 		= require(Mods:WaitForChild("Hitmarker"))
local Ultil			= require(Mods:WaitForChild("Utilities"))
local Ragdoll		= require(Mods:WaitForChild("Ragdoll"))

local HttpService 	= game:GetService("HttpService")
local TS 			= game:GetService('TweenService')
local Run 			= game:GetService("RunService")

local plr 			= game.Players

local ACS_0 		= HttpService:GenerateGUID(true)

_G.TempBannedPlayers = {} 

local luaw,llaw,lhw, ruaw,rlaw,RA,LA,RightS,LeftS
local AnimBase,AnimBaseW

local Explosion = {"187137543"; "169628396"; "926264402"; "169628396"; "926264402"; "169628396"; "187137543";}

game.StarterPlayer.CharacterWalkSpeed = gameRules.NormalWalkSpeed
local function AccessID(Attacker,SKP_1)
	if Attacker.UserId == SKP_1 then
		return ACS_0
	else
		Attacker:kick("Exploit Protocol")
		warn(Attacker.Name.." - Potential Exploiter! Case 0-A: Client Tried To Access Server Code")
		table.insert(_G.TempBannedPlayers, Attacker)
	end
end
function Weld(p0, p1, cf1, cf2)
	local m = Instance.new("Motor6D")
	m.Part0 = p0
	m.Part1 = p1
	m.Name = p0.Name
	m.C0 = cf1 or p0.CFrame:inverse() * p1.CFrame
	m.C1 = cf2 or CFrame.new()
	m.Parent = p0
	return m
end
Evt.AcessId.OnServerInvoke = AccessID

local function compareTables(arr1, arr2)
	if	arr1.gunName==arr2.gunName 				and 
		arr1.Type==arr2.Type 					and
		arr1.ShootRate==arr2.ShootRate 			and
		arr1.Bullets==arr2.Bullets				and
		arr1.LimbDamage[1]==arr2.LimbDamage[1]	and
		arr1.LimbDamage[2]==arr2.LimbDamage[2]	and
		arr1.TorsoDamage[1]==arr2.TorsoDamage[1]and
		arr1.TorsoDamage[2]==arr2.TorsoDamage[2]and
		arr1.HeadDamage[1]==arr2.HeadDamage[1]	and
		arr1.HeadDamage[2]==arr2.HeadDamage[2]
	then
		return true
	else
		return false
	end
end

local function secureSettings(Player,Gun,Module)
	local PreNewModule = Gun:FindFirstChild("GunSettings")
	if Gun and PreNewModule then
		local NewModule = require(PreNewModule)
		if (compareTables(Module, NewModule) == false) then
			Player:kick("Exploit Protocol")
			warn(Player.Name.." - Potential Exploiter! Case 4: Exploiting Gun Stats")	
			table.insert(_G.TempBannedPlayers, Player)
			return false
		else
			return true
		end
	else
		Player:kick("Exploit Protocol")
		warn(Player.Name.." - Potential Exploiter! Case 2: Missing Gun And Module")	
		return false
	end
end

local function getPlayerState(player: Player)
	if not player then
		return ""
	end

	local revision = player:GetAttribute("Revision")
	if type(revision) ~= "string" then
		return ""
	end

	return string.lower(string.gsub(revision, "^%s*(.-)%s*$", "%1"))
end

local function isCriminalRevision(player: Player): boolean
	local state = getPlayerState(player)
	return state == "wanted" or state == "hostile"
end

local function canKill(target: Player, executor: Player)
	if not target or not executor then
		return true
	end

	local executorTeam = executor.Team
	local targetTeam = target.Team

	if executorTeam and executorTeam:HasTag("Federal") then
		-- Federal players can only damage criminal revisions.
		if isCriminalRevision(target) then
			return true
		end

		if targetTeam and targetTeam:HasTag("Federal") then
			return false
		end

		return false
	end

	return true
end

function CalculateDMG(Attacker, SKP_1, SKP_2, SKP_4, SKP_5, SKP_6)
	local Victim	= nil
	local skp_1 = 0
	local skp_2 = SKP_5.MinDamage * SKP_6.minDamageMod

	if game.Players:GetPlayerFromCharacter(SKP_1.Parent) ~= nil then
		Victim = game.Players:GetPlayerFromCharacter(SKP_1.Parent)
	end

	if SKP_4 == 1 then
		local skp_3 = math.random(SKP_5.HeadDamage[1], SKP_5.HeadDamage[2])
		skp_1 = math.max(skp_2 ,(skp_3 * SKP_6.DamageMod) - (SKP_2/25) * SKP_5.DamageFallOf)
	elseif SKP_4 == 2 then
		local skp_3 = math.random(SKP_5.TorsoDamage[1], SKP_5.TorsoDamage[2])
		skp_1 = math.max(skp_2 ,(skp_3 * SKP_6.DamageMod) - (SKP_2/25) * SKP_5.DamageFallOf)
	else
		local skp_3 = math.random(SKP_5.LimbDamage[1], SKP_5.LimbDamage[2])
		skp_1 = math.max(skp_2 ,(skp_3 * SKP_6.DamageMod) - (SKP_2/25) * SKP_5.DamageFallOf)
	end

	if SKP_1.Parent:FindFirstChild("ACS_Client") ~= nil and not SKP_5.IgnoreProtection then

		local skp_4 = SKP_1.Parent.ACS_Client.Protecao.VestProtect
		local skp_5 = SKP_1.Parent.ACS_Client.Protecao.HelmetProtect

		if SKP_4 == 1 then
			if SKP_5.BulletPenetration < skp_5.Value  then
				skp_1 = math.max(.5 ,skp_1 * (SKP_5.BulletPenetration/skp_5.Value))
			end
		else
			if SKP_5.BulletPenetration < skp_4.Value  then
				skp_1 = math.max(.5 ,skp_1 * (SKP_5.BulletPenetration/skp_4.Value))
			end
		end
	end		

	if Victim ~= nil then
		if not canKill(Victim, Attacker) then
			return
		end
		print("hit dectectado")
		if Victim.Team ~= Attacker.Team or Victim.Neutral == true then
			SKP_1:TakeDamage(skp_1)
		else
			if gameRules.TeamKill then
				SKP_1:TakeDamage(skp_1 * gameRules.TeamDmgMult)
			else
				return
			end
		end
	else
		SKP_1:TakeDamage(skp_1)
	end

	SKP_1:SetAttribute('LastHit', Attacker.UserId)
end

local function Damage(Attacker, SKP_1, SKP_2, SKP_3, SKP_4, SKP_5, SKP_6, SKP_7, SKP_8, SKP_9)
	if Attacker and Attacker.Character and Attacker.Character.Humanoid.Health > 0 then
		if SKP_9 == (ACS_0.."-"..Attacker.UserId) then
			if not SKP_7 then
				if SKP_1 then
					local Victim = secureSettings(Attacker,SKP_1, SKP_5)
					if Victim and SKP_2 then
						CalculateDMG(Attacker, SKP_2, SKP_3, SKP_4, SKP_5, SKP_6)
						local skp_1	= Instance.new("ObjectValue")
						skp_1.Name	= "creator"
						skp_1.Value	= Attacker
						skp_1.Parent= SKP_2
						game.Debris:AddItem(skp_1, 1)
					end
				else
					Attacker:kick("Exploit Protocol")
					warn(Attacker.Name.." - Potential Exploiter! Case 1: Tried To Access Damage Event")
					table.insert(_G.TempBannedPlayers, Attacker)
				end
			else
				Attacker.Character.Humanoid:TakeDamage(SKP_8)
			end
		else
			Attacker:kick("Exploit Protocol")
			warn(Attacker.Name.." - Potential Exploiter! Case 0-B: Wrong Permission Code")
			table.insert(_G.TempBannedPlayers, Attacker)
		end
	end
end
Evt.Grenade.OnServerEvent:Connect(function(Attacker, SKP_1, SKP_2, SKP_3, SKP_4, SKP_5, SKP_6)
	if Attacker and Attacker.Character and Attacker.Character.Humanoid.Health > 0 then
		if SKP_6 == (ACS_0.."-"..Attacker.UserId) then
			if SKP_1 and SKP_2 then
				local Victim = secureSettings(Attacker, SKP_1, SKP_2)
				if Victim then

					if SKP_2.Type == "Grenade" then
						if SVGunModels:FindFirstChild(SKP_2.gunName) == nil then
							warn("ACS_Server Couldn't Find "..SKP_2.gunName.." In Grenade Model Folder")
							return
						end

						local Victim = SVGunModels[SKP_2.gunName]:Clone()

						for SKP_Arg0, SKP_Arg1 in pairs(Attacker.Character:GetChildren()) do
							if SKP_Arg1:IsA('BasePart')then
								local skp_1 = Instance.new("NoCollisionConstraint")
								skp_1.Parent= Victim
								skp_1.Part0 = Victim.PrimaryPart
								skp_1.Part1 = SKP_Arg1
							end
						end

						local skp_1	= Instance.new("ObjectValue")
						skp_1.Name	= "creator"
						skp_1.Value	= Attacker
						skp_1.Parent= Victim.PrimaryPart

						Victim.Parent 	= ACS_Workspace.Server
						Victim.PrimaryPart.CFrame = SKP_3
						Victim.PrimaryPart:ApplyImpulse(SKP_4 * SKP_5 * Victim.PrimaryPart:GetMass())
						--Victim.PrimaryPart:SetNetworkOwner(Attacker)
						Victim.PrimaryPart.Damage.Disabled = false

						SKP_1:Destroy()
					end
				end
			end
		end
	end
end)

local function getDamageTool(player)
	local t = player.Character:FindFirstChildOfClass("Tool")
	if t and t:FindFirstChild("GunSettings") then
		return t
	end
end
local AllMaterials = Enum.Material:GetEnumItems()

local AllMaterials = Enum.Material:GetEnumItems()
local MaterialToIndex = {}
for i, m in ipairs(AllMaterials) do MaterialToIndex[m] = i end

local function PackBatchHits(raycastResults)
	local count = #raycastResults

	local bufferSize = 1 + (count * 16)
	local b = buffer.create(bufferSize)
	local instanceList = table.create(count)

	buffer.writeu8(b, 0, count)

	for i, result in ipairs(raycastResults) do
		local offset = 1 + ((i - 1) * 16)

		local pos = result.Position
		local norm = result.Normal
		local mat = result.Material

		buffer.writef32(b, offset + 0, pos.X)
		buffer.writef32(b, offset + 4, pos.Y)
		buffer.writef32(b, offset + 8, pos.Z)

		buffer.writei8(b, offset + 12, math.round(norm.X * 127))
		buffer.writei8(b, offset + 13, math.round(norm.Y * 127))
		buffer.writei8(b, offset + 14, math.round(norm.Z * 127))

		local matIndex = MaterialToIndex[mat] or 1
		buffer.writeu8(b, offset + 15, matIndex)

		instanceList[i] = result.Instance
	end

	return b, instanceList
end


Evt.Damage.OnServerInvoke = Damage

Evt.HitEffect.OnServerEvent:Connect(function(Player, HitInstances, BufferData)	
	local tool = getDamageTool(Player)

	local weapon = tool
	if not weapon:FindFirstChild("GunSettings") then
		return
	end

	local cfg = require( weapon:FindFirstChild("GunSettings") )
	local Settings = cfg

	local isExplosiveCase =
		(Settings.ExplosiveSettings and Settings.ExplosiveSettings.Enabled)
		or Settings.ShootType == 6
	if Settings.gunName ~= cfg.gunName and not isExplosiveCase then
		return
	end
	for _, p in pairs(game:GetService("Players"):GetPlayers()) do
		if p ~= Player then
			Evt.HitEffect:FireClient(p, Player, HitInstances, BufferData)
		end
	end
end)

Evt.Explosion.OnServerEvent:Connect(function(Player, Position, HitPart, Normal) 
	local tool = getDamageTool(Player)


	local weapon = getDamageTool(Player)
	if not weapon or not weapon:FindFirstChild("GunSettings") then
		return
	end

	local cfg = require(weapon:FindFirstChild("GunSettings"))
	local Settings = cfg
	local expSettings = Settings.ExplosiveSettings or {}

	if not expSettings then
		warn("gun doesnt have gun settings")
	end
	local radius = expSettings.Radius or 14
	local baseDamage = expSettings.Damage or 50
	local fallOff = expSettings.DamageFallOff or 1 
	local isExplosiveCase =
		(Settings.ExplosiveSettings and Settings.ExplosiveSettings.Enabled)
		or Settings.ShootType == 6
	print(isExplosiveCase)
	if not isExplosiveCase then return end
	print(radius, baseDamage, fallOff)

	local x = Instance.new("Explosion")
	x.Position = Position
	x.BlastRadius = 0
	x.BlastPressure = 0
	x.Visible = true
	x.Parent = workspace


	local partsInRadius = workspace:GetPartBoundsInRadius(Position, radius)
	local hitHumanoids = {}

	for _, part in pairs(partsInRadius) do
		local character = part.Parent
		local humanoid = character:FindFirstChild("Humanoid")

		if humanoid and humanoid.Health > 0 and not hitHumanoids[humanoid] then
			hitHumanoids[humanoid] = true

			local victimPlayer = game.Players:GetPlayerFromCharacter(character)
			local isTeammate = false

			if victimPlayer and (Player.Team and victimPlayer.Team == Player.Team) then
				isTeammate = true

				-- if Player.Neutral then isTeammate = false end
			end

			local canDamageVictim = true
			if victimPlayer and victimPlayer ~= Player then
				canDamageVictim = canKill(victimPlayer, Player)
			end

			if canDamageVictim and (not isTeammate or victimPlayer == Player) then
				local distance = (part.Position - Position).Magnitude

				local finalDamage = baseDamage - (distance * fallOff)

				if finalDamage < 0 then finalDamage = 0 end

				humanoid:TakeDamage(finalDamage)
			end
		end

		if part.Name == "VMotor" and part:IsA("Part") then
			if math.random() > 0.5 then 
				local damageFactor = (math.random(-10,10) / 10)
				if part:FindFirstChild("MotorHealth") then
					part.MotorHealth.Value = part.MotorHealth.Value - (20 * damageFactor)
				end
				if part:FindFirstChild("Smoke") then part.Smoke.Enabled = true end
				if part:FindFirstChild("Smoke1") then part.Smoke1.Enabled = true end
			end
		end
	end

	task.delay(2, function()
		if x then x:Destroy() end
	end)
	HitMod.Explosion(Position,HitPart,Normal, Settings)
end)
Evt.GunStance.OnServerEvent:Connect(function(Player,stance,Data)
	Evt.GunStance:FireAllClients(Player,stance,Data)
end)

Evt.ServerBullet.OnServerEvent:Connect(function(Player,Origin,Direction,WeaponData,ModTable)
	Evt.ServerBullet:FireAllClients(Player,Origin,Direction,WeaponData,ModTable)
end)
Evt.Stance.OnServerEvent:connect(function(Player, Stance, Virar)
	if Player.Character and Player.Character:FindFirstChild("Humanoid") ~= nil and Player.Character.Humanoid.Health > 0 then

		local char		= Player.Character
		local Human 	= char:WaitForChild("Humanoid")
		local ACS_Client= char:WaitForChild("ACS_Client")

		local LowerTorso= char:FindFirstChild("LowerTorso")
		local UpperTorso= char:FindFirstChild("UpperTorso")

		local RootJoint = char["LowerTorso"]:FindFirstChild("Root")
		local WaistJ 	= char["UpperTorso"]:FindFirstChild("Waist")
		local RS 		= char["RightUpperArm"]:FindFirstChild("RightShoulder")
		local LS 		= char["LeftUpperArm"]:FindFirstChild("LeftShoulder")
		local RH 		= char["RightUpperLeg"]:FindFirstChild("RightHip")
		local RK 		= char["RightLowerLeg"]:FindFirstChild("RightKnee")
		local LH 		= char["LeftUpperLeg"]:FindFirstChild("LeftHip")
		local LK 		= char["LeftLowerLeg"]:FindFirstChild("LeftKnee")

		local RightArm	= char["RightUpperArm"]
		local LeftArm 	= char["LeftUpperArm"]
		local LeftLeg 	= char["LeftUpperLeg"]
		local RightLeg 	= char["RightUpperLeg"]

		if Stance == 2 and RootJoint and WaistJ and RH and LH and RK and LK  then
			TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-Human.HipHeight - LowerTorso.Size.Y,Human.HipHeight/1.25)* CFrame.Angles(math.rad(-90),0,math.rad(0))} ):Play()
			TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0)* CFrame.Angles(math.rad(10),0,math.rad(0))} ):Play()

			TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(-30),math.rad(0))} ):Play()
			TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(30),math.rad(0))} ):Play()
			TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
			TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()

		end
		if Virar == 1 and RootJoint and WaistJ and RH and LH and RK and LK then
			if Stance == 0 then
				TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0) * CFrame.Angles(math.rad(0),0,math.rad(-30))} ):Play()
				TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-(Human.HipHeight/2),0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()

				TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()

			elseif Stance == 1 then
				TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0)* CFrame.Angles(math.rad(0),0,math.rad(-30))} ):Play()
				TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-Human.HipHeight/1.05,0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()

				TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(75),math.rad(0),math.rad(0))} ):Play()
				TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/2,0)* CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3.5,0)* CFrame.Angles(math.rad(-60),math.rad(0),math.rad(0))} ):Play()

			end
		elseif Virar == -1 and RootJoint and WaistJ and RH and LH and RK and LK  then
			if Stance == 0 then
				TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0) * CFrame.Angles(math.rad(0),0,math.rad(30))} ):Play()
				TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-(Human.HipHeight/2),0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()
				TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()

			elseif Stance == 1 then
				TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0)* CFrame.Angles(math.rad(0),0,math.rad(30))} ):Play()
				TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-Human.HipHeight/1.05,0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()
				TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(75),math.rad(0),math.rad(0))} ):Play()
				TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/2,0)* CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3.5,0)* CFrame.Angles(math.rad(-60),math.rad(0),math.rad(0))} ):Play()

			end
		elseif Virar == 0 and RootJoint and WaistJ and RH and LH and RK and LK  then
			if Stance == 0 then
				TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0)* CFrame.Angles(math.rad(-0),0,math.rad(0))} ):Play()
				TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-(Human.HipHeight/2),0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()
				TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()

			elseif Stance == 1 then

				TS:Create(WaistJ, TweenInfo.new(.3), {C0 = CFrame.new(0,LowerTorso.Size.Y/2.5,0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()
				TS:Create(RootJoint, TweenInfo.new(.3), {C0 = CFrame.new(0,-Human.HipHeight/1.05,0)* CFrame.Angles(math.rad(0),0,math.rad(0))} ):Play()
				TS:Create(RH, TweenInfo.new(.3), {C0 = CFrame.new(RightLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LH, TweenInfo.new(.3), {C0 = CFrame.new(-LeftLeg.Size.X/2, -LowerTorso.Size.Y/2,0)* CFrame.Angles(math.rad(75),math.rad(0),math.rad(0))} ):Play()
				TS:Create(RK, TweenInfo.new(.3), {C0 = CFrame.new(0, -RightLeg.Size.Y/2,0)* CFrame.Angles(math.rad(-90),math.rad(0),math.rad(0))} ):Play()
				TS:Create(LK, TweenInfo.new(.3), {C0 = CFrame.new(0, -LeftLeg.Size.Y/3.5,0)* CFrame.Angles(math.rad(-60),math.rad(0),math.rad(0))} ):Play()

			end
		end
		if ACS_Client:GetAttribute("Surrender") then
			TS:Create(RS, TweenInfo.new(.3), {C0 = CFrame.new(RightArm.Size.X/1.15, UpperTorso.Size.Y/2.8,0)* CFrame.Angles(math.rad(179),math.rad(0),math.rad(0))} ):Play()
			TS:Create(LS, TweenInfo.new(.3), {C0 = CFrame.new(-LeftArm.Size.X/1.15, UpperTorso.Size.Y/2.8,0)* CFrame.Angles(math.rad(179),math.rad(0),math.rad(0))} ):Play()
		elseif Stance == 2 then
			TS:Create(RS, TweenInfo.new(.3), {C0 = CFrame.new(RightArm.Size.X/1.15, UpperTorso.Size.Y/2.8,0)* CFrame.Angles(math.rad(170),math.rad(0),math.rad(0))} ):Play()
			TS:Create(LS, TweenInfo.new(.3), {C0 = CFrame.new(-LeftArm.Size.X/1.15, UpperTorso.Size.Y/2.8,0)* CFrame.Angles(math.rad(170),math.rad(0),math.rad(0))} ):Play()
		else
			TS:Create(RS, TweenInfo.new(.3), {C0 = CFrame.new(RightArm.Size.X/1.15, UpperTorso.Size.Y/2.8,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
			TS:Create(LS, TweenInfo.new(.3), {C0 = CFrame.new(-LeftArm.Size.X/1.15, UpperTorso.Size.Y/2.8,0)* CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))} ):Play()
		end
	end
end)

function CheckForHumanoid(L_225_arg1)
	local L_226_ = false
	local L_227_ = nil
	if L_225_arg1 then
		if (L_225_arg1.Parent:FindFirstChildOfClass("Humanoid") or L_225_arg1.Parent.Parent:FindFirstChildOfClass("Humanoid")) then
			L_226_ = true
			if L_225_arg1.Parent:FindFirstChildOfClass('Humanoid') then
				L_227_ = L_225_arg1.Parent:FindFirstChildOfClass('Humanoid')
			elseif L_225_arg1.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				L_227_ = L_225_arg1.Parent.Parent:FindFirstChildOfClass('Humanoid')
			end
		else
			L_226_ = false
		end	
	end
	return L_226_, L_227_
end

function loadAttachment(weapon,WeaponData)
	if weapon and WeaponData and weapon:FindFirstChild("Nodes") ~= nil then
		if weapon.Nodes:FindFirstChild("Sight") ~= nil and WeaponData.SightAtt ~= "" then

			local SightAtt = AttModels[WeaponData.SightAtt]:Clone()
			SightAtt.Parent = weapon
			SightAtt:SetPrimaryPartCFrame(weapon.Nodes.Sight.CFrame)

			for index, key in pairs(weapon:GetChildren()) do
				if key.Name == "IS" then
					key.Transparency = 1
				end
			end

			for index, key in pairs(SightAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
				if key.Name == "SightMark" or key.Name == "Main" then
					key:Destroy()
				end
			end

		end
		if weapon.Nodes:FindFirstChild("Barrel") ~= nil and WeaponData.BarrelAtt ~= "" then

			local BarrelAtt = AttModels[WeaponData.BarrelAtt]:Clone()
			BarrelAtt.Parent = weapon
			BarrelAtt:SetPrimaryPartCFrame(weapon.Nodes.Barrel.CFrame)

			if BarrelAtt:FindFirstChild("BarrelPos") ~= nil then
				weapon.Handle.Muzzle.WorldCFrame = BarrelAtt.BarrelPos.CFrame
			end

			for index, key in pairs(BarrelAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end
		end
		if weapon.Nodes:FindFirstChild("UnderBarrel") ~= nil and WeaponData.UnderBarrelAtt ~= "" then

			local UnderBarrelAtt = AttModels[WeaponData.UnderBarrelAtt]:Clone()
			UnderBarrelAtt.Parent = weapon
			UnderBarrelAtt:SetPrimaryPartCFrame(weapon.Nodes.UnderBarrel.CFrame)


			for index, key in pairs(UnderBarrelAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end
		end
		if weapon.Nodes:FindFirstChild("Other") ~= nil and WeaponData.OtherAtt ~= "" then

			local OtherAtt = AttModels[WeaponData.OtherAtt]:Clone()
			OtherAtt.Parent = weapon
			OtherAtt:SetPrimaryPartCFrame(weapon.Nodes.Other.CFrame)

			for index, key in pairs(OtherAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end
		end
	end
end

Evt.Equip.OnServerEvent:Connect(function(Player,Arma,Mode,Settings,Anim,Humanoid)
	if Player.Character then
		if Mode == 1 then
			local Head = Player.Character:FindFirstChild('Head')

			local ServerGun = GunModels:FindFirstChild(Arma.Name):Clone()
			ServerGun.Name = 'S' .. Arma.Name

			for _, part in pairs(ServerGun:GetChildren()) do
				if part.Name == "Warhead" and Settings.IsLauncher and Arma:FindFirstChild("RepValues") and Arma.RepValues.Mag.Value < 1 then
					part.Transparency = 1
				end
			end

			AnimBase = Instance.new("Part", Player.Character)
			AnimBase.CanCollide = false
			AnimBase.Transparency = 1
			AnimBase.Anchored = false
			AnimBase.Name = "AnimBase"
			AnimBase.Size = Vector3.new(0.1, 0.1, 0.1)

			AnimBaseW = Instance.new("Motor6D")
			AnimBaseW.Part0 = Head
			AnimBaseW.Part1 = AnimBase
			AnimBaseW.Parent = AnimBase
			AnimBaseW.Name = "AnimBaseW"
			--AnimBaseW.C0 = CFrame.new(0,-1.25,0)

			RA = Player.Character['RightUpperArm']
			LA = Player.Character['LeftUpperArm']
			RightS = RA:WaitForChild("RightShoulder")
			LeftS = LA:WaitForChild("LeftShoulder")

			ruaw = Instance.new("Motor6D")
			ruaw.Name = "RAW"
			ruaw.Part0 = RA
			ruaw.Part1 = AnimBase
			ruaw.Parent = AnimBase
			ruaw.C0 = Anim.SV_RightArmPos
			RightS.Enabled = false

			rlaw = Instance.new("Motor6D")
			rlaw.Name = "RLAW"
			rlaw.Part0 = Player.Character.RightLowerArm
			rlaw.Part1 = RA
			rlaw.Parent = AnimBase
			rlaw.C0 = CFrame.new(0,RA.Size.Y/2,0) * Anim.SV_RightElbowPos


			ruaw = Instance.new("Motor6D")
			ruaw.Name = "RHW"
			ruaw.Part0 = Player.Character.RightHand
			ruaw.Part1 = Player.Character.RightLowerArm
			ruaw.Parent = AnimBase
			ruaw.C0 = CFrame.new(0,Player.Character.RightLowerArm.Size.Y/2,0) * Anim.SV_RightWristPos

			luaw = Instance.new("Motor6D")
			luaw.Name = "LAW"
			luaw.Part0 = LA
			luaw.Part1 = AnimBase
			luaw.Parent = AnimBase
			luaw.C0 = Anim.SV_LeftArmPos
			LeftS.Enabled = false

			llaw = Instance.new("Motor6D")
			llaw.Name = "LLAW"
			llaw.Part0 = Player.Character.LeftLowerArm
			llaw.Part1 = LA
			llaw.Parent = AnimBase
			llaw.C0 = CFrame.new(0,LA.Size.Y/2,0) * Anim.SV_LeftElbowPos

			lhw = Instance.new("Motor6D")
			lhw.Name = "LHW"
			lhw.Part0 = Player.Character.LeftHand
			lhw.Part1 = Player.Character.LeftLowerArm
			lhw.Parent = AnimBase
			lhw.C0 = CFrame.new(0,Player.Character.LeftLowerArm.Size.Y/2,0) * Anim.SV_LeftWristPos

			ServerGun.Parent = Player.Character

			loadAttachment(ServerGun,Settings)

			if ServerGun:FindFirstChild("Nodes") ~= nil then
				ServerGun.Nodes:Destroy()
			end

			for SKP_001, SKP_002 in pairs(ServerGun:GetDescendants()) do
				if SKP_002.Name == "SightMark" then
					SKP_002:Destroy()
				end
			end

			for SKP_001, SKP_002 in pairs(ServerGun:GetDescendants()) do
				if SKP_002:IsA('BasePart') and SKP_002.Name ~= 'Handle' then
					Ultil.WeldComplex(ServerGun:WaitForChild("Handle"), SKP_002, SKP_002.Name)
				end;
			end

			local SKP_004 = Instance.new('Motor6D')
			SKP_004.Name = 'Handle'
			SKP_004.Parent = ServerGun.Handle
			SKP_004.Part0 = Player.Character['RightHand']
			SKP_004.Part1 = ServerGun.Handle
			SKP_004.C1 = Anim.SV_GunPos:inverse()

			for L_74_forvar1, L_75_forvar2 in pairs(ServerGun:GetDescendants()) do
				if L_75_forvar2:IsA('BasePart') then
					L_75_forvar2.Anchored = false
					L_75_forvar2.CanCollide = false
				end
			end
			for _, Part in pairs(ServerGun:GetDescendants()) do
				if Part:IsA('BasePart') then
					Part.Anchored = false
					Part.CanCollide = false
					Part:SetAttribute("FPInvis", true)
				end
			end;

		elseif Mode == 2 then
			if Arma then
				--Player.Character['S' .. Arma.Name]:Destroy()

				local gunBase = Player.Character:FindFirstChild('S'..Arma.Name)
				if gunBase then
					gunBase:Destroy()
				else
					warn('S'..Arma.Name.." not found")
				end

				local animBase = Player.Character:FindFirstChild("AnimBase")
				if animBase then
					animBase:Destroy()
				end
			end

			if Player.Character:FindFirstChild("RightUpperArm") and Player.Character.RightUpperArm:FindFirstChild("RightShoulder") then
				Player.Character.RightUpperArm:WaitForChild("RightShoulder").Enabled = true
			end

			if Player.Character:FindFirstChild("LeftUpperArm") and Player.Character.LeftUpperArm:FindFirstChild("LeftShoulder") then
				Player.Character.LeftUpperArm:WaitForChild("LeftShoulder").Enabled = true
			end
		end
	end
end)
Evt.Atirar.OnServerEvent:Connect(function(Player, Arma, Suppressor, FlashHider)
	Evt.Atirar:FireAllClients(Player, Arma, Suppressor, FlashHider)
end)
Evt.Melee.OnServerEvent:Connect(function(Player, Arma)
	Evt.Melee:FireAllClients(Player, Arma)
end)
Evt.Whizz.OnServerEvent:Connect(function(Player, Victim,bspeed,loud, TotalDistTraveled, maxdist)
	Evt.Whizz:FireClient(Victim,bspeed,loud, TotalDistTraveled, maxdist)
end)
Evt.HeadRot.OnServerEvent:connect(function(Player, CF)
	Evt.HeadRot:FireAllClients(Player, CF)
end)

Evt.Suppression.OnServerEvent:Connect(function(Player,Victim,Mode,Intensity,Time)
	Evt.Suppression:FireClient(Victim,Mode,Intensity,Time)
end)

Evt.SVFlash.OnServerEvent:Connect(function(plr,pr,val)
	if plr.Character and  plr.Character:FindFirstChild('S' .. pr) then
		local p = plr.Character['S' .. pr]
		for _,v in pairs(p:GetChildren()) do
			if v.Name == 'GFlash'  then
				v.Enabled.Value = val
			end
		end
	end
end)

local ServerStorage = game:GetService("ServerStorage")


plr.PlayerAdded:Connect(function(player)

	for i,v in ipairs(_G.TempBannedPlayers) do
		if v == player.Name then
			player:Kick('Blacklisted')
			warn(player.Name.." (Temporary Banned) tried to join to server")
			break
		end
	end

	for i,v in ipairs(gameRules.Blacklist) do
		if v == player.UserId then
			player:Kick('Blacklisted')
			warn(player.Name.." (Blacklisted) tried to join to server")
			break
		end
	end

	if gameRules.AgeRestrictEnabled and not Run:IsStudio() then
		if player.AccountAge < gameRules.AgeLimit then
			player:Kick('Age restricted server! Please wait: '..(gameRules.AgeLimit - player.AccountAge)..' Days')
		end
	end



	player.CharacterAdded:Connect(function(char)

		player.Backpack.ChildAdded:Connect(function(newChild)
			if newChild:IsA("Tool") and newChild:FindFirstChild("GunSettings") and require(newChild.GunSettings).Holster then
				CheckHolster(player,newChild.Name,require(newChild.GunSettings))
			end
		end)
		if gameRules.TeamTags then
			local L_17_ = HUDs:WaitForChild('TeamTagUI'):clone()
			L_17_.Parent = char
			L_17_.Adornee = char.Head
		end
		char.Humanoid.BreakJointsOnDeath = false
		char.Humanoid.Died:Connect(function()
			task.spawn(function() 
				task.wait(2)
				player:LoadCharacterAsync()
			end)
			if not gameRules.EnableRagdoll then return end
			pcall(function()
				Ragdoll(char)
			end)
		end)
		player.Backpack.ChildRemoved:Connect(function(newChild)
			if newChild:IsA("Tool") and newChild:FindFirstChild("GunSettings") and char:FindFirstChild("S_"..newChild.Name) then
				char:FindFirstChild("S_"..newChild.Name):Destroy()
			end
		end)
	end)
end)

function CheckHolster(player,weaponName,toolSettings)
	if player.Character and not player.Character:FindFirstChild("S_"..weaponName) and not player.Character:FindFirstChild(weaponName) then
		HolsterWeapon(player,weaponName,toolSettings)
	end
end

function HolsterWeapon(player,weaponName,toolSettings)
	local holsterPoint = toolSettings.HolsterPoint
	local holsterModel = GunHolster:FindFirstChild(weaponName):Clone()
	holsterModel.Name = "S_"..weaponName
	holsterModel.Parent = player.Character

	for _, part in pairs(holsterModel:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "Handle" then
			if part.Name == "SightMark" or (part.Name == "Warhead" and weaponName and toolSettings.Mag.Value < 1) then
				part:Destroy()
			else
				local newWeld = Ultil.WeldComplex(holsterModel.Handle,part,part.Name)
				newWeld.Parent = holsterModel.Handle
				part.Anchored = false
				part.CanCollide = false
			end
		end
	end
	local holsterWeld = Ultil.Weld(player.Character[holsterPoint],holsterModel.Handle,toolSettings.HolsterCFrame)
	holsterWeld.Parent = holsterModel
	holsterWeld.Name = "HolsterWeld"
	holsterModel.Handle.Anchored = false
end