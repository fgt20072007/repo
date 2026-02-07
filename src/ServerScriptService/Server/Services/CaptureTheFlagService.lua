local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Classes = ServerScriptService.Server.Classes

local Zone = require(ReplicatedStorage.Shared.Packages.Zone)
local Server = require(ServerScriptService.Server)
local Flag = require(Classes.Flag)

local FlagAreas = workspace.Code.Flags

local CaptureTheFlagService = {}

function CaptureTheFlagService._Init(self: CaptureTheFlagService)
	self.Flags = {}
	if not FlagAreas then return end

	for _, flagModel in FlagAreas:GetChildren() do
		local flag = Flag.new(flagModel)
		local zone = Zone.new(flag.Area)

		table.insert(self.Flags, flag)

		flag.FlagEmpty:Connect(function() end)

		flag.Contested:Connect(function()
			flag.Area.BillboardGui.Display.Text = "CONTESTED"
			flag.Area.BillboardGui.Display.TextColor3 = Color3.fromRGB(255, 0, 0)
		end)

		zone.playerEntered:Connect(function(player)
			flag:AddPlayer(player)
		end)

		zone.playerExited:Connect(function(player)
			flag:RemovePlayer(player)
		end)
	end

	task.spawn(function()
		while true do
			for _, flag in self.Flags do
				if flag.Owner and flag.Owner.Parent ~= game.Players then
					flag.Owner = nil
					flag.TimeSinceLastReward = 0
				end
				if not flag.Owner then
					continue
				end
				flag.TimeSinceLastReward += 1
				if flag.TimeSinceLastReward >= flag.RewardTime then
					if flag.Owner then
						Server.Services.DataService:Increment(flag.Owner, "Shards", 10)
					end
					flag.TimeSinceLastReward = 0
					continue
				end

				flag.Area.BillboardGui.Display.Text = `Reward in {flag.RewardTime - flag.TimeSinceLastReward}s`
			end
			task.wait(1)
		end
	end)
end

type CaptureTheFlagService = typeof(CaptureTheFlagService) & {
	Flags: {},
}

return CaptureTheFlagService
