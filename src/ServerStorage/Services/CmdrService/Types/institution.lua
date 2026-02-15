local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local RanksData = require(ReplicatedStorage.Data.Ranks)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

return function(registry)
	registry:RegisterType(
		"institution",
		registry.Cmdr.Util.MakeEnumType(
			"Institution",
			TableUtil.Keys(RanksData)
		)
	)
end