local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")
local ObjectPool = require(RS.Packages.ObjectPool)
local player = game.Players.LocalPlayer
local ACS_Storage= workspace:WaitForChild("ACS_WorkSpace")
local BulletModel =  ACS_Storage.Server
local Glass = {"1565824613"; "1565825075";}
local Metal = {"6448196805"; "6448196009"; "6448197452"; "6448198224"; "6448199773";"6448196411"; "8721235938"; "8721235755"; "6448198511"; "8721236171";"6448199415";}
local Grass = {"1565830611"; "1565831129"; "1565831468"; "1565832329";}
local Wood = {"287772625"; "287772674"; "287772718"; "287772829"; "287772902";}
local Concrete = {"6448068505"; "6448070893"; "6448071729"; "6448067739"; "6448070105";"6448072035";"6448069683";"6448071130";"6448071418";"6448068067";}
local Explosion = {"287390459"; "287390954"; "287391087"; "287391197"; "287391361"; "287391499"; "287391567";}
local Cracks = {"342190504"; "342190495"; "342190488"; "342190510";} -- Bullet Cracks
local Hits = {"363818432"; "363818488"; "363818567"; "363818611"; "363818653";} -- Player
local Headshots = {"4459572527"; "4459573786";"3739364168";}
local Whizz = {"342190005"; "342190012"; "342190017"; "342190024";} -- Bullet Whizz

local Effects = RS.ACS_MICTLAN.HITFX

local Hitmarker = {"8797893157"}

local AttachmentPool = ObjectPool.new(
	function() 
		return Instance.new("Attachment") 
	end, 
	100,
	function(att) 
		att.Parent = workspace.Terrain
	end, 
	function(att) 
		att.Parent = nil 
		att:ClearAllChildren()
	end
)

function CheckColor(Color,Add)
	Color = Color + Add
	if Color > 1 then
		Color = 1
	elseif Color < 0 then
		Color = 0
	end
	return Color
end

function CreateEffect(Type,Attachment,ColorAdjust,HitPart)
	local NewType
	if Effects:FindFirstChild(Type) then
		NewType = Effects:FindFirstChild(Type)
	else
		NewType = Effects.Stone
	end
	local NewEffect = NewType:GetChildren()[math.random(1,#NewType:GetChildren())]:Clone()
	local MaxTime = 3

	for _, Effect in pairs(NewEffect:GetChildren()) do
		Effect.Parent = Attachment
		Effect.Enabled = false

		if ColorAdjust and HitPart then
			local NewColor = HitPart.Color
			local Add = 0.3
			if HitPart.Material == Enum.Material.Fabric then
				Add = -0.2 -- Darker
			end

			NewColor = Color3.new(CheckColor(NewColor.R, Add),CheckColor(NewColor.G, Add),CheckColor(NewColor.B, Add)) -- Adjust new color

			Effect.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,NewColor),
				ColorSequenceKeypoint.new(1,NewColor)
			})
		end

		Effect:Emit(Effect.Rate / 5)
		if Effect.Lifetime.Max > MaxTime then
			MaxTime = Effect.Lifetime.Max
		end
	end

	local HitSound = Instance.new("Sound")
	local SoundType
	if Type == "Headshot" then
		SoundType = Headshots
	elseif Type == "Hit" then
		SoundType = Hits
	elseif Type == "Glass" then
		SoundType = Glass
	elseif Type == "Metal" then
		SoundType = Metal
	elseif Type == "Ground" then
		SoundType = Grass
	elseif Type == "Wood" then
		SoundType = Wood
	elseif Type == "Stone" then
		SoundType = Concrete
	else
		SoundType = Concrete 	
	end

	HitSound.Parent = Attachment
	HitSound.Volume = math.random(5,10)/10
	HitSound.MaxDistance = 500
	HitSound.EmitterSize = 10
	HitSound.PlaybackSpeed = math.random(34, 50)/40
	HitSound.SoundId = "rbxassetid://" .. SoundType[math.random(1, #SoundType)]
	HitSound:Play()

	if HitSound.TimeLength > MaxTime then MaxTime = HitSound.TimeLength end
	task.delay(MaxTime, function()
		AttachmentPool:free(Attachment)
	end)
end


function Hitmarker.HitEffect(Ray_Ignore,Position, HitPart, Normal, Material,Type)
	if not Type then
		Type = "Hit"
	end

	local Attachment = AttachmentPool:get()
	Attachment.CFrame = CFrame.new(Position, Position + Normal)


	if HitPart then
		if not HitPart.Parent then return end
		if HitPart:IsA("BasePart") and (HitPart.Parent:FindFirstChild("Humanoid") or HitPart.Parent.Parent:FindFirstChild("Humanoid") or (HitPart.Parent.Parent.Parent and HitPart.Parent.Parent.Parent:FindFirstChild("Humanoid"))) then

			CreateEffect("Hit",Attachment)

		elseif HitPart.Parent:IsA("Accessory") then 

			CreateEffect("Hit",Attachment)

		elseif Material == Enum.Material.Wood or Material == Enum.Material.WoodPlanks then

			CreateEffect("Wood",Attachment)

		elseif Material == Enum.Material.Slate

			or Material == Enum.Material.Pebble
			or Material == Enum.Material.Cobblestone
			or Material == Enum.Material.Marble


			or Material == Enum.Material.Basalt

			or Material == Enum.Material.Pavement
			or Material == Enum.Material.Rock
			or Material == Enum.Material.CrackedLava
			or Material == Enum.Material.Sandstone
			or Material == Enum.Material.Limestone
		then

			CreateEffect("Stone",Attachment)

		elseif Material == Enum.Material.Metal
			or Material == Enum.Material.CorrodedMetal
			or Material == Enum.Material.DiamondPlate
			or Material == Enum.Material.Neon
			or Material == Enum.Material.Fabric

			or Material == Enum.Material.Salt
		then

			CreateEffect("Metal",Attachment)

		elseif Material == Enum.Material.Ground


			or Material == Enum.Material.Mud
		then

			CreateEffect("Ground",Attachment)

		elseif Material == Enum.Material.Sand
			or Material == Enum.Material.Fabric

			or Material == Enum.Material.Snow
		then

			CreateEffect("Sand",Attachment,true,HitPart)

		elseif Material == Enum.Material.Foil
			or Material == Enum.Material.Ice
			or Material == Enum.Material.Glass
			or Material == Enum.Material.ForceField
		then

			CreateEffect("Glass",Attachment,true,HitPart)


		elseif Material == Enum.Material.Concrete or Material == Enum.Material.Brick
			or Material == Enum.Material.Plastic
			or Material == Enum.Material.SmoothPlastic
			or Material == Enum.Material.Asphalt
		then

			CreateEffect("Concrete",Attachment)

		elseif Material == Enum.Material.Grass  then

			CreateEffect("Grass",Attachment)
		end
	else
		task.delay(0.1, function()
			AttachmentPool:free(Attachment)
		end)
	end
end

function Hitmarker.Explosion(Position, HitPart, Normal, Settings, IsWater: boolean?)

	if Settings then
		local Hitmark = AttachmentPool:get()
		Hitmark.Position = Position

		local xpl = Settings.ExplosiveSettings.ExplosionEffect
		local effect = game.ReplicatedStorage.ACS_MICTLAN.Assets.Explosion:FindFirstChild(xpl)

		local IGNORE = {}
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				if not v.Anchored or not v.CanCollide then
					table.insert(IGNORE,v)
				end
			end
		end

		if effect then
			for _,v in pairs(effect:GetChildren()) do
				if v:IsA("ParticleEmitter") then
					local cl = v:Clone()
					cl.Parent = Hitmark
					if cl:FindFirstChild("Duration") then
						spawn(function()
							cl.Enabled = true
							wait(cl.Duration.Value)
							cl.Enabled = false
							Debris:AddItem(cl,cl.Lifetime.Max)
						end)
					else
						cl:Emit(cl.Rate)
						Debris:AddItem(cl,cl.Lifetime.Max)
					end
					--Debris:AddItem(cl,cl.Lifetime.Max)
				end
				if v:IsA("Script") and v.Name == "AdditionalFunctions" then
					local cl = v:Clone()
					cl.Parent = Hitmark
					cl.Disabled = false
				end
			end
		end

		local S = Instance.new("Sound")
		S.EmitterSize = 39
		S.MaxDistance = 3750

		S.SoundId = "rbxassetid://".. Explosion[math.random(1, #Explosion)]
		S.PlaybackSpeed = math.random(75,115)/100
		S.Volume = 5
		S.Parent = Hitmark
		S.PlayOnRemove = true
		S:Destroy()


		local Exp = Instance.new("Explosion")
		Exp.BlastPressure = 0
		Exp.BlastRadius = 0
		Exp.DestroyJointRadiusPercent = 0
		Exp.Position = Hitmark.Position
		Exp.Parent = Hitmark
		Exp.Visible = false

		task.delay(45, function()
			AttachmentPool:free(Hitmark)
		end)
	end

end

return Hitmarker