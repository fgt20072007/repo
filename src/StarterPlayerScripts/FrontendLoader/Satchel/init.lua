local StarterGui = game:GetService("StarterGui")

require(script.Packages.topbarplus)

task.spawn(function()
	local timeoutAt = os.clock() + 10
	repeat
		local success = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if success then
			return
		end

		task.wait(0.1)
	until os.clock() >= timeoutAt
end)

return require(script.Packages["satchel"])