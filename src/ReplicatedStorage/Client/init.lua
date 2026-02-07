local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interface = require(ReplicatedStorage:WaitForChild("Interface"))

local Client = {
	Controllers = {},
}

function Client._Init()
	Interface:_Init()

	for _, controller in script.Controllers:GetChildren() do
		local mod = require(controller)

		Client.Controllers[controller.Name] = mod

		task.wait()

		if mod._Init then
			mod:_Init()
		end
	end

	for _, controller in Client.Controllers do
		if controller.Spawn then
			task.spawn(function()
				controller:Spawn()
			end)
		end
	end
end

return Client
