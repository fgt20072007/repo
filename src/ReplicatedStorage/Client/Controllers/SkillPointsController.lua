local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local Math = require(Shared.CustomPackages.Math)
local Interface = require(ReplicatedStorage.Interface)
local Client = require(ReplicatedStorage.Client)
local Zone = require(Shared.Packages.Zone)
local AddKillPointsRemote = require(Shared.Remotes.AddSkillPoint):Client()

local SkillPointsController = {}

function SkillPointsController.Spawn(self: SkillPointsController)
	local DataController = Client.Controllers.DataController
	local Profile = DataController:GetProfile(true)
	local MainFrame = Interface:_GetComponent({ "Frames", "SkillPoints", "Main" })

	local Container = MainFrame:WaitForChild("Container")
	local Scroller = Container.Left:WaitForChild("Scroller")
	local SkillPointZone = Zone.new(workspace.LobbyZones.SkillPointZone)

	Container.Right.Amount.Text = `Skill Points: {Math.FormatCurrency(Profile.SkillPoints)}`

	DataController:OnChange("SkillPoints", function(new, old)
		Profile = DataController:GetProfile(false)
		Container.Right.Amount.Text = `Skill Points: {Math.FormatCurrency(new)}`
	end)

	SkillPointZone.localPlayerEntered:Connect(function()
		Interface:_ToggleFrame("SkillPoints")
	end)

	for key, value in Profile.AllocatedPoints do
		local StatFrame = Scroller[key]
		local PointsLabel = StatFrame.Important:WaitForChild("Progress")
		local tracker = value
		local canApply = true

		PointsLabel.Text = Math.FormatCurrency(value)

		StatFrame.Important.Buy.Button.MouseButton1Click:Connect(function()
			if not canApply then
				return
			end

			if Profile.SkillPoints > 0 then
				AddKillPointsRemote:Fire(key, 1)
				tracker += 1
				PointsLabel.Text = Math.FormatCurrency(tracker)
			else
				warn("No skill points to allocate")
			end

			task.wait(0.2)
			canApply = true
		end)
	end

	MainFrame.Closing.ImageButton.MouseButton1Click:Connect(function()
		Interface:_ToggleFrame("SkillPoints")
	end)
end

type SkillPointsController = typeof(SkillPointsController)

return SkillPointsController
