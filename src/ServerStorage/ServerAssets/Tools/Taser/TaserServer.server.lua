
local Tool = script.Parent
local remote = Tool:WaitForChild("RemoteEvent")

local last = nil
local sendrate = Tool:GetAttribute("FireRate")

local Character = nil

local function CanSend()
	if not last then
		last = tick()
		return last
	end

	return tick() - last >= sendrate and tick() or nil
end

local TaserCastLength = 30


local CastParams
local function UpdateCastParams()
	CastParams = RaycastParams.new()
	CastParams.FilterType = Enum.RaycastFilterType.Exclude
	CastParams.RespectCanCollide = false
	CastParams.FilterDescendantsInstances = {Character}
end

Tool.Equipped:Connect(function()
	Character = Tool.Parent
	UpdateCastParams()
end)

remote.OnServerEvent:Connect(function(player, mousePosition)
	if not Character then return end
	--> Rate Limiter
	local now = CanSend()
	if not now then return end
	last = now
	
	Tool:SetAttribute("FiredAt", workspace:GetServerTimeNow())
	
	script.Parent.Handle.Shoot:Play()
	
	local OriginPosition = script.Parent.Handle.Position
	local Direction = (mousePosition - OriginPosition).Unit
	
	local Raycast = workspace:Raycast(OriginPosition, Direction * TaserCastLength, CastParams)
	
	task.spawn(function()
		if Raycast then
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.Parent = workspace
			
			part.Transparency = .5
			part.Color = Color3.new(1, 1, 0.239216)
			
			local EndPosition = Raycast and Raycast.Position or OriginPosition + Direction * TaserCastLength
			
			part.Size = Vector3.new(.2, .2, (OriginPosition - EndPosition).Magnitude)
			part:PivotTo(CFrame.lookAlong(Vector3.zero, Direction, Vector3.yAxis) + ((OriginPosition + EndPosition) * .5))
			
			task.wait(.5)
			part:Destroy()
		end
	end)
	
	if not Raycast then return end
	
	local TargetPlayer = game.Players:GetPlayerFromCharacter(Raycast.Instance.Parent)
	
	if TargetPlayer and TargetPlayer.Team.Name ~= "Civilian" then return end
	
	if TargetPlayer and not TargetPlayer:GetAttribute("Electrocuted") then
		TargetPlayer:SetAttribute("Electrocuted", true)
		if not TargetPlayer:GetAttribute("Ragdoll") then TargetPlayer:SetAttribute("Ragdoll", true) end
	end
	
	
	
end)