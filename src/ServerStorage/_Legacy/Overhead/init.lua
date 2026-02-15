local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local Billboard = script.PlayerBillboard
local BillboardName = "PlayerBillboard"

local Images = {
	["Secondary"] = 134271761107706,
	["Approved"] = 135514205515614,
	["Wanted"] = 99952157127227,
	["Hostile"] = 9111498641,
}	

local Overhead = {}

function Overhead:SetupBillboard(player: Player, character: Model)
	if not (player and character)
		or character:FindFirstChild(BillboardName)
	then return end
	
	local hum = character:WaitForChild("Humanoid") :: Humanoid
	if not hum then return end

	hum.DisplayName = " "
	
	local playerOverhead = Billboard:Clone()
		playerOverhead.Name = BillboardName
		playerOverhead.Parent = character
		playerOverhead.Adornee = character:WaitForChild("Head")
		playerOverhead.PlayerName.Text = player.Name
		playerOverhead.PlayerTeam.Text = player.Team.Name
end

function Overhead.Init()
	Observers.observeCharacter(function(player: Player, character: Model)
		task.spawn(Overhead.SetupBillboard, Overhead, player, character)

		local obs = Observers.observeAttribute(player, "Revision", function(state: string)
			if not state then return end

			local billboardGui = character:FindFirstChild(BillboardName) :: BillboardGui
			if not billboardGui then return end

			local revisionImage = billboardGui:FindFirstChild("RevisionImage") :: ImageLabel

			if state == "Not Approved" then
				revisionImage.Visible = false
				return	
			end

			local image = Images[state]
			revisionImage.Image = image and `rbxassetid://{image}` or ''
			revisionImage.Visible = true
		end)

		return obs
	end)
end

return Overhead