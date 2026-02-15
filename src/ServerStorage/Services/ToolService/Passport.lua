local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local Observers = require(Packages.Observers)

local ShowPassportRE = Net:RemoteEvent("ShowPassport")
local SetPassportOwnerRF = Net:RemoteFunction("SetPassportOwner")

return {
	Init = function()
		Observers.observeTag("Passport", function(prompt: ProximityPrompt)
			if not prompt or not prompt:IsA("ProximityPrompt") then return end
			
			prompt.Triggered:Connect(function(player: Player)
				if not player or not player:IsA("Player") then return end
				
				
				
				local ownerId = prompt:GetAttribute("Owner")
				if not ownerId then return end
				
				ShowPassportRE:FireClient(player, ownerId)
			end)
			
		end)
		
		SetPassportOwnerRF.OnServerInvoke = (function(player: Player)
			if not player or not player:IsA("Player") then return false end
			
			local tool = player.Backpack:FindFirstChild("Passport")
			if not tool then return false end
			
			local Handle = tool:FindFirstChild("Handle")
			if not Handle then return false end
			
			local Prompt = Handle:FindFirstChild("ProximityPrompt")
			if not Prompt then return false end
			
			Prompt:SetAttribute("Owner", player.UserId)
			
			return true
		end)
	end,
}