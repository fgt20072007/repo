local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local ToolsData = require(ReplicatedStorage.Data.Tools)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

return function(registry)
	registry:RegisterType(
		"tool",
		registry.Cmdr.Util.MakeEnumType(
			"Tool",
			TableUtil.Keys(ToolsData)
		)
	)
end