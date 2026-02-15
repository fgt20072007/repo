local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local Observers = require(Packages.Observers)

local _ShowPassportRE = Net:RemoteEvent("ShowPassport")
local _SetPassportOwnerRF = Net:RemoteFunction("SetPassportOwner")
local Notification = Net:RemoteEvent("Notification")

local function IsBlacklistedRevision(revision: any): boolean
	if type(revision) ~= "string" then
		return false
	end

	local normalized = string.lower(revision)
	return normalized == "wanted" or normalized == "hostile"
end

local function NotifyStampBlocked(executor: Player, revision: any)
	if not executor then return end
	local state = (type(revision) == "string" and revision) or "Wanted"
	Notification:FireClient(executor, "Stamp/StateBlocked", { state = state })
end


return {
	Init = function()

		Observers.observeTag("StampPrompt", function(prompt: ProximityPrompt)
			if not prompt or not prompt:IsA("ProximityPrompt") then return end


			local holder = prompt.Parent
			local characterPrompt = holder and holder.Parent or nil
			local playerPrompt = characterPrompt and game.Players:GetPlayerFromCharacter(characterPrompt) or nil

			prompt.Triggered:Connect(function(player: Player)

				if not player then return end
				if not playerPrompt then return end

				local revision = playerPrompt:GetAttribute("Revision")
				if IsBlacklistedRevision(revision) then
					NotifyStampBlocked(player, revision)
					return
				end



				if not player.Team:HasTag("Federal") then
					return
				end

				local toolInBackpack = player.Backpack:FindFirstChild("Stamp")
				local toolEquipped = player.Character and player.Character:FindFirstChild("Stamp")

				if not toolInBackpack and not toolEquipped then
					return
				end



				if prompt.Name == "ApprovePrompt" then
					revision = playerPrompt:GetAttribute("Revision")
					if IsBlacklistedRevision(revision) then
						NotifyStampBlocked(player, revision)
						return
					end
					playerPrompt:SetAttribute("Revision", "Approved")
					return
				end

				if prompt.Name == "SecondaryPrompt" then
					revision = playerPrompt:GetAttribute("Revision")
					if IsBlacklistedRevision(revision) then
						NotifyStampBlocked(player, revision)
						return
					end
					playerPrompt:SetAttribute("Revision", "Secondary")
					return
				end


			end)






		end)


	end,
}