local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService 'Lighting'

local Data = ReplicatedStorage:WaitForChild('Data')
local SettingsData = require(Data.Settings)

local Util = ReplicatedStorage:WaitForChild('Util')
local Sounds = require(Util.Sounds)

local Controllers = ReplicatedStorage:WaitForChild('Controllers')
local UIController = require(Controllers.UIController)
local ReplicaController = require(Controllers.ReplicaController)

local HANDLERS = {
	["Global Shadows"] = function(value: boolean)
		Lighting.GlobalShadows = value
	end,
	["Sound Effects"] = function(value: boolean)
		Sounds.ToggleGroup('SFX', value)
	end,
	["MiniMap"] = function(value: boolean)
		task.spawn(function()
			local player = Players.LocalPlayer
			if not player then return end

			local playerGui = player:WaitForChild("PlayerGui", 5)
			if not (playerGui and playerGui:IsA("PlayerGui")) then return end

			local hud = playerGui:WaitForChild("HUD", 5)
			if not (hud and hud:IsA("ScreenGui")) then return end

			local minimap = hud:FindFirstChild("Minimap") or hud:WaitForChild("Minimap", 5)
			if minimap and minimap:IsA("GuiObject") then
				minimap.Visible = not value
			end
		end)
	end,
}

local SettingsController = {}

function SettingsController.UpdateSetting(id: number)
	local data = SettingsData[id]
	if not data then return end
	
	local replica = ReplicaController.GetReplica('PlayerData')
	local value = if (replica and replica.Data) then replica.Data.Settings[id] else nil
	local fixedValue = if value ~= nil then value else data.Default
	
	local uiClass = UIController:GetClass('Settings')
	if uiClass and uiClass.UpdateSetting then
		uiClass:UpdateSetting(id, fixedValue)
	end
	
	local handler = HANDLERS[id]
	if handler then
		handler(fixedValue)
	end
end

function SettingsController.UpdateAll()
	for id, _ in SettingsData do
		SettingsController.UpdateSetting(id)
	end
end

function SettingsController.Init()
	task.spawn(function()
		local succ, res: ReplicaController.Replica = ReplicaController.GetReplicaAsync('PlayerData'):await()
		if not succ then return end
		
		res:OnChange(function(_, path)
			if path[1]~= 'Settings' then return end
			
			local id = path[2]
			if typeof(id)~='string' then return end
			
			SettingsController.UpdateSetting(id)
		end)
		
		SettingsController.UpdateAll()
	end)
end

return SettingsController
