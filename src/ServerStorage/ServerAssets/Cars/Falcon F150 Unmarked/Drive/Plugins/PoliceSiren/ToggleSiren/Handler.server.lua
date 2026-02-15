local ToggleSirenRE = script.Parent :: RemoteEvent

local SirenTypes = require(script.Parent.SirenTypes)

local AttributeTypes = {
	"Siren", "SirenSound"
}

ToggleSirenRE.OnServerEvent:Connect(function(Player:Player, Siren, SirenType:string)
	if not SirenType then return end
	if not table.find(AttributeTypes, Siren) then return end
	
	if SirenType == "OFF" then
		SirenType = nil
	else
		if not table.find(SirenTypes, SirenType) then return end
	end
	
	
	
	local OtherAttribute = Siren == "Siren" and "SirenSound" or "Siren"
	
	local Car = ToggleSirenRE.Parent
	local CurrentSiren = Car:GetAttribute(Siren) 
	--> Same Button Press
	if CurrentSiren and CurrentSiren == SirenType then
		SirenType = nil
	end
	
	--[[
	if Car:GetAttribute(Siren) == Car:GetAttribute(OtherAttribute) and Siren == "Siren" then
		Car:SetAttribute(OtherAttribute, SirenType)
	end]]
	
	Car:SetAttribute(Siren, SirenType)
end)