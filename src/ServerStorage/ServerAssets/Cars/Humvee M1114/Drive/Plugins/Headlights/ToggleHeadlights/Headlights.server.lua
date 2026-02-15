local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))


local Car = script.Parent.Parent :: ObjectValue

local ToggleHeadlightsRE = script.Parent

local HeadlightsModel = Car.Body.Headlights :: Model


local function ToggleHeadlights(bool: boolean)

	for _, v in HeadlightsModel:GetChildren() do
		if not v:IsA("BasePart") then continue end

		local hasColor = v:GetAttribute("On")

		local offColor = v:GetAttribute("Off")

		if hasColor then
			if not offColor then
				offColor = v.Color
				v:SetAttribute("Off", offColor)
			end
			v.Color = hasColor
		end

		local beam = v:HasTag("Beam")

		local light = v:HasTag("Light")

		if bool then
			v.Material = Enum.Material.Neon
		else
			v.Material = Enum.Material.SmoothPlastic
		end

		if beam or light then
			for _, child in v:GetChildren() do
				if child:IsA("Beam") or child:IsA("Light") then
					child.Enabled = bool
				end

			end
		end

	end

end


	Observers.observeAttribute(Car, "Headlights", function(on: boolean)
		if on then
			ToggleHeadlights(true)
		else
			ToggleHeadlights(false)
		end
	end)

	ToggleHeadlightsRE.OnServerEvent:Connect(function()
		local on = not Car:GetAttribute("Headlights")
		Car:SetAttribute("Headlights", on)
	end)
