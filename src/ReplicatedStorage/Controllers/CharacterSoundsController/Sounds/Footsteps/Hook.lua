return function(character: Model, humanoid: Humanoid)
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ACS_Engine = ReplicatedStorage:WaitForChild("ACS_MICTLAN")
	local GameConfig = ACS_Engine:FindFirstChild("GameRules")
	local PlayersService= game:GetService("Players")
	local gameRules = require(GameConfig:FindFirstChild("Config"))
	local plr 			= PlayersService.LocalPlayer
	local baseRunSpeed = gameRules.RunWalkSpeed
	local baseWalkSpeed = gameRules.NormalWalkSpeed 
	local char 			= plr.Character or plr.CharacterAdded:Wait()
	
	local saude = char:WaitForChild("ACS_Client")
	local StancesPasta = saude:WaitForChild("Stances")
	local isrunning = StancesPasta.Value
	
	if isrunning.Value == true then

		return "Sprint" 	
	

	end
	
	return "Default"
end