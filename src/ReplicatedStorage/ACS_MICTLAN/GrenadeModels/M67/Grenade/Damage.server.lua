local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Tool = script.Parent
local Handle = Tool.Parent.Grenade

local ToolInfo = {
	CurrentCharacter = nil; -- current character using the tool (dont touch)
	TargetPosition = nil; -- target position (dont touch)

	FriendlyFire = false; -- if set to true, you would be able to damage yourself with the grenade

	DestroyAfterUse = false; -- removes tool after usage

	Range = 60; -- damage range
	Damage = 120 -- damage
}

local function resolveAttacker(): Player?
	local creator = Handle:FindFirstChild("creator")
	if creator and creator:IsA("ObjectValue") and creator.Value and creator.Value:IsA("Player") then
		return creator.Value
	end

	local owner = Handle.Parent and Handle.Parent:FindFirstChild("creator", true)
	if owner and owner:IsA("ObjectValue") and owner.Value and owner.Value:IsA("Player") then
		return owner.Value
	end

	return nil
end

local function canDamageTarget(attacker: Player?, targetHumanoid: Humanoid): boolean
	if not attacker then return true end

	local targetCharacter = targetHumanoid and targetHumanoid.Parent
	if not targetCharacter then return true end

	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if not targetPlayer then return true end
	if targetPlayer == attacker then return true end

	local attackerTeam = attacker.Team
	if not attackerTeam then return true end

	if attackerTeam:HasTag("Federal") then
		local revision = targetPlayer:GetAttribute("Revision")
		local normalized = type(revision) == "string" and string.lower(string.gsub(revision, "^%s*(.-)%s*$", "%1")) or ""
		if normalized == "wanted" or normalized == "hostile" then
			return true
		end

		local targetTeam = targetPlayer.Team
		if targetTeam and targetTeam:HasTag("Federal") then
			return false
		end

		return false
	end

	return true
end

function getNearbyInstances(Position:Vector3, MaxDistance:number) -- get nearby instances via part touched
	assert(
		typeof(Position) == "Vector3",
		"'"..tostring(Position).."' Must Be A Vector3"
	)

	local PartSize = tonumber(MaxDistance) or 10
	local Part = Instance.new("Part",workspace)
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false

	Part.Transparency = 1
	Part.Shape = Enum.PartType.Ball

	Part.Position = Position
	Part.Size = Vector3.new(PartSize,PartSize,PartSize)

	local Connection = Part.Touched:Connect(function()
	end)

	local TouchedResults = Part:GetTouchingParts()
	Connection:Disconnect()
	Debris:AddItem(Part,0)

	return TouchedResults
end

function raycastNearbyHumanoids(Position:Vector3, MaxDistance:number) -- raycast to any nearby instances
	assert(
		typeof(Position) == "Vector3",
		"'"..tostring(Position).."' Must Be A Vector3"
	)

	local Instances = getNearbyInstances(Position, MaxDistance)
	local MaxDistance = tonumber(MaxDistance) or 10
	local Seen = {}

	for i,Object in pairs(Instances) do
		local Direction = (Object.Position-Position).Unit*MaxDistance
		local Raycast = workspace:Raycast(Position,Direction)

		local intersection = Raycast and Raycast.Position or Position + Direction
		local distance = math.floor((Position - intersection).Magnitude)

		if Raycast then
			local HitInstant = Raycast.Instance
			if HitInstant then
				local Humanoid = HitInstant.Parent:FindFirstChildOfClass("Humanoid") or HitInstant.Parent.Parent:FindFirstChildOfClass("Humanoid")
				if Humanoid then
					if not ToolInfo.FriendlyFire then
						if not table.find(Seen,Humanoid) then
							Seen[#Seen+1] = Humanoid
						end
					elseif ToolInfo.FriendlyFire and Humanoid.Parent ~= ToolInfo.CurrentCharacter then
						if not table.find(Seen,Humanoid) then
							Seen[#Seen+1] = Humanoid
						end
					end
				end
			end
		end
	end

	return Seen
end

function Activate(TargetPosition:Vector3)
	local attacker = resolveAttacker()
	local Explosion = Instance.new("Explosion")
	Explosion.BlastRadius = 60
	Explosion.BlastPressure = 0
	Explosion.Position = Handle.Position
	Explosion.Parent = Handle
	Explosion.Visible = false
	for i,v in pairs(game.Players:GetPlayers())do
		if v.Character then
			if v.Character:FindFirstChild("HumanoidRootPart") then
				local HM = v.Character:FindFirstChild("HumanoidRootPart")
				if (HM.Position - Handle.Position).magnitude <= ToolInfo.Range then
					if TargetPosition then
						local Humanoids = raycastNearbyHumanoids(TargetPosition,ToolInfo.Range)
						if Humanoids then
							for i,Humanoid in pairs(Humanoids) do
								if not canDamageTarget(attacker, Humanoid) then
									continue
								end
								local DistanceFactor = (HM.Position - Handle.Position).magnitude/ToolInfo.Range
								DistanceFactor = 1-DistanceFactor
								local HitDamage = DistanceFactor*ToolInfo.Damage
								Humanoid:TakeDamage(HitDamage)
							end
						end
					end
				end
				wait(5)	
				Debris:AddItem( script.Parent.Parent.Parent.M67)		
			end
		end
	end
end

function boom()
	wait(3)

	Handle.Explosion.Boom:Emit(math.random(30,50))
	Handle.Anchored = true
	Handle.CanCollide = false
	Handle.Transparency = 1
	Handle.Explode:Play()
	Handle.Distant1:Play()
	Handle.Distant2:Play()
	Activate(Handle.Position)
end

boom()