local RunService = game:GetService("RunService")

local grad = script.Parent
local cycleTime = 1
local range = 6
local elapsed = 0

local connection
connection = RunService.Heartbeat:Connect(function(deltaTime)
	if grad.Parent == nil then
		connection:Disconnect()
		return
	end

	elapsed += deltaTime
	if elapsed < 0.05 then
		return
	end
	elapsed = 0

	local loop = (os.clock() % cycleTime) / cycleTime
	local colors = table.create(range + 1)
	for i = 1, range + 1 do
		local hue = loop - ((i - 1) / range)
		if hue < 0 then
			hue += 1
		end
		colors[i] = ColorSequenceKeypoint.new((i - 1) / range, Color3.fromHSV(hue, 1, 1))
	end
	grad.Color = ColorSequence.new(colors)
end)