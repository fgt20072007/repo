task.wait(5)

require(script.Packages.topbarplus)

local success
repeat
	success = pcall(function()
		game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	task.wait(1)
until success

return require(script.Packages["satchel"])