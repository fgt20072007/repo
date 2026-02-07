local Players = game:GetService('Players')
local ServerScriptService = game:GetService('ServerScriptService')

local EntityComponent = require(ServerScriptService.Components.EntityComponent)
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteBank = require(ReplicatedStorage.RemoteBank)


return function(tool: Tool, informations)
	local Animation = informations.Animation
	local Force = informations.Force
	local DebounceTime = informations.DebounceTime

	local debounce = false
	local loadedTrack

	local function GetPlayersInfront(playerThatOwns, cframe: CFrame)
		local foundPlayers = {}
		local parts = workspace:GetPartBoundsInBox(cframe, Vector3.new(10, 10, 10))
		for _, v in parts do
			local char = v:FindFirstAncestorOfClass("Model")
			if char then
				local player = Players:GetPlayerFromCharacter(char)
				if player then
					if player ~= playerThatOwns and not table.find(foundPlayers, player) then
						table.insert(foundPlayers, player)
					end
				end
			end
		end
		return foundPlayers
	end

	tool.Equipped:Connect(function()
		local char = tool.Parent
		if not char then return end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end

		if loadedTrack then
			loadedTrack:Stop()
			loadedTrack:Destroy()
		end

		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = "rbxassetid://" .. Animation
		loadedTrack = animator:LoadAnimation(animInstance)
	end)

	tool.Unequipped:Connect(function()
		if loadedTrack then
			loadedTrack:Stop()
			loadedTrack:Destroy()
			loadedTrack = nil
		end
	end)

	tool.Activated:Connect(function()
		if debounce then return end
		debounce = true
		task.delay(DebounceTime, function()
			debounce = false
		end)

		local char = tool.Parent
		if not char then return end

		local player = Players:GetPlayerFromCharacter(char)
		if not player then return end

		local rootPart = char:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		if loadedTrack then
			loadedTrack:Play()
		end

		local playersInfront = GetPlayersInfront(player, rootPart.CFrame)
		RemoteBank.PlaySound:FireClient(player, "Swing")
		
		for _, v in playersInfront do
			EntityComponent.DropAll(v, true, rootPart.CFrame, Force)
			
			RemoteBank.PlaySound:FireClient(player, "Slap"); RemoteBank.PlaySound:FireClient(playersInfront, "Slap")
		end
	end)
end