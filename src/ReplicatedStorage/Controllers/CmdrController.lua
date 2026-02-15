local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Cmdr
local CmdrController = {}

function CmdrController.Init()
	task.spawn(function()
		local fetch = ReplicatedStorage:WaitForChild('CmdrClient')
		
		Cmdr = require(fetch)
		Cmdr:SetActivationKeys({Enum.KeyCode.F2})
	end)
end

return CmdrController
