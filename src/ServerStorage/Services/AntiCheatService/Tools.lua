local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local Data = ReplicatedStorage.Data
local Tools_Data = require(Data.Tools)


local Tools = {}

local function GetToolInfo(toolName: string)
	if not toolName then return false end
	
	local tool = Tools_Data[toolName]
	if not tool then return false end

	return tool
end

local function ToolIsAllowed(toolName: string, team: Team)
	if not toolName or not team then return false end
	
	local toolInfo = GetToolInfo(toolName)
	if not toolInfo then return false end
	
	local IsFederal = team:HasTag("Federal")
	
	for _, teamInfo in ipairs(toolInfo.Teams) do
		
		if teamInfo == "All" then
			return true
		end
		
		if teamInfo == "Federal" and IsFederal then
			return true
		end
		
		if teamInfo == team.Name then
			return true
		end
	end
	
	return false
end

local function CheckTool(player: Player, tool: Tool)
	if not tool then return false end
	
	local IsAllowed = ToolIsAllowed(tool.Name, player.Team)
	if not IsAllowed then
		tool:Destroy()
		return false 
	end
end



function Tools.Init()
	Observers.observeCharacter(function(player: Player)
		if not player then return end
		
		
		for _, tool in player.Backpack:GetChildren() do
			if not tool then continue end
			if not tool:IsA("Tool") then continue end


			CheckTool(player, tool)
		end
		
		player.Backpack.ChildAdded:Connect(function(tool: Instance)
			if not tool then return end

			if not tool:IsA("Tool") then return end

			CheckTool(player, tool)
		end)	
	end)
end


return Tools