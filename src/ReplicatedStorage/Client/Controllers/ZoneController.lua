local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Interface = require(ReplicatedStorage:WaitForChild("Interface"))
local Zone = require(Shared.Packages:WaitForChild("Zone"))
local Networker = require(Shared.Packages.networker)

local LobbyZones = workspace:WaitForChild("LobbyZones")

local ZoneController = {}

function ZoneController._Init(self: ZoneController)
	self.Networker = Networker.client.new("ZoneService", self)

	LobbyZones:WaitForChild("SellZone")
	LobbyZones:WaitForChild("ShopZone")
	LobbyZones:WaitForChild("StarterEgg")
	LobbyZones:WaitForChild("ReaperEgg")

	local sellZone = Zone.new(LobbyZones.SellZone)
	local shopZone = Zone.new(LobbyZones.ShopZone)
	local starterEggZone = Zone.new(LobbyZones.StarterEgg)
	local reaperEggZone = Zone.new(LobbyZones.ReaperEgg)

	sellZone.localPlayerEntered:Connect(function()
		self.Networker:fire("ConvertSkulls")
	end)

	shopZone.localPlayerEntered:Connect(function()
		Interface:_ToggleFrame("Shop")
	end)

	starterEggZone.localPlayerEntered:Connect(function()
		Interface.Frames.EggDisplays.StarterEgg.Visible = true
	end)

	starterEggZone.localPlayerExited:Connect(function()
		print("Exited Starter Egg Zone")
		Interface.Frames.EggDisplays.StarterEgg.Visible = false
	end)
end

type ZoneController = typeof(ZoneController) & {
	Networker: Networker.Client,
}

return ZoneController
