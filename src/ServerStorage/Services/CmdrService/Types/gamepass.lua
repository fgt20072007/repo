local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local ToolsData = require(ReplicatedStorage.Data.Passes)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

return function(registry)
	registry:RegisterType(
		"gamepass",
		registry.Cmdr.Util.MakeEnumType(
			"Gamepass",
			TableUtil.Keys(ToolsData)
		)
	)
end