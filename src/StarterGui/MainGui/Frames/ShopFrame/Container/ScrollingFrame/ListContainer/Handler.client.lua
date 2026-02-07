local PolicyService = game:GetService("PolicyService")
local Players = game:GetService('Players')

if PolicyService:GetPolicyInfoForPlayerAsync(Players.LocalPlayer).ArePaidRandomItemsRestricted == true then
	script.Parent:Destroy()
end