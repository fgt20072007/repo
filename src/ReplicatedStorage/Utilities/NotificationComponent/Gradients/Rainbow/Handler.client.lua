local grad = script.Parent
local t = 1 
local range = 6

while wait() do
	local loop = tick() % t / t
	local colors = {}
	for i = 1, range + 1, 1 do
		z = Color3.fromHSV(loop - ((i - 1)/range), 1, 1)
		if loop - ((i - 1) / range) < 0 then
			z = Color3.fromHSV((loop - ((i - 1) / range)) + 1, 1, 1)
		end
		local d = ColorSequenceKeypoint.new((i - 1) / range, z)
		table.insert(colors, d)
	end
	grad.Color = ColorSequence.new(colors)
end