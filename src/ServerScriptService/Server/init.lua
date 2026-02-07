local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local ServerImmutable = require(script.Modules.ServerImmutable)

local Server = {
	Services = {},
}

function Server._Init()
	for _, service in script.Services:GetChildren() do
		local module = require(service)

		Server.Services[service.Name] = module

		if module._Init then
			module:_Init()
		end
	end

	local function OnPlayerAdded(Player: Player)
		Player:SetAttribute("JoinTime", os.time())
		for _, service in Server.Services do
			if not service.OnPlayerAdded then
				continue
			end
			task.spawn(function()
				service:OnPlayerAdded(Player)
			end)
		end
	end

	for _, player in Players:GetPlayers() do
		OnPlayerAdded(player)
	end

	game.Players.PlayerAdded:Connect(OnPlayerAdded)
end

function Server.GetImmutable()
	return ServerImmutable
end

return Server
