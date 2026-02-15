repeat
	wait()
until game.Players.LocalPlayer.Character

local Engine = game.ReplicatedStorage:WaitForChild("ACS_MICTLAN")
local ACS_WS = workspace:WaitForChild("ACS_WorkSpace")
local Evt = Engine:WaitForChild("Events")
local ServerConfig = require(Engine.GameRules:WaitForChild("Config"))
local TS = game:GetService('TweenService')
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Char =player.Character or player.CharacterAdded:Wait()
local Human = Char.Humanoid
local interactionmouse = script.Parent.InteractionMouse
local TextoOmbro = script.Parent.OmbroTexto


local RS = game:GetService("ReplicatedStorage")
local DoorEvent = Evt:WaitForChild("DoorEvent")

local Target = nil
local TratarAtivo = false 
local TratarCheck = false

local InteragirAtivo = false 
local InteragirCheck = false

local EquipeAtivo = false 

local PortaAtivo = false 

local Arrastando = false

local Yeet = false
local GUI = script.Parent 


Sgui = script.Parent.Parent
player = Sgui.Parent
mouse = player:GetMouse()
mouse.TargetFilter = workspace.CurrentCamera
IgnoreList = {Camera,Char}

local ACS_Storage = workspace:WaitForChild("ACS_WorkSpace")
local DoorsFolder = ACS_Storage:FindFirstChild("Doors")
local BreachFolder = ACS_WS:FindFirstChild("Breach")
local mDistance = 5


function CheckForHumanoid(L_225_arg1)
	local L_226_ = false
	local L_227_ = nil
	if L_225_arg1 then
		if (L_225_arg1.Parent:FindFirstChild("Humanoid") or L_225_arg1.Parent.Parent:FindFirstChild("Humanoid")) then
			L_226_ = true
			if L_225_arg1.Parent:FindFirstChild('Humanoid') then
				L_227_ = L_225_arg1.Parent.Humanoid
			elseif L_225_arg1.Parent.Parent:FindFirstChild('Humanoid') then
				L_227_ = L_225_arg1.Parent.Parent.Humanoid
			end
		else
			L_226_ = false
		end	
	end
	return L_226_, L_227_
end

function ResetGui()
	TratarAtivo = false 
	TratarCheck = false

	InteragirAtivo = false 
	InteragirCheck = false

	EquipeAtivo = false
	PortaAtivo = false

	--Arrastando = false


end










game:GetService("RunService").RenderStepped:connect(function()
	local Jogadors = game.Players:GetChildren()
	if mouse.Target then
		if (player.Character:FindFirstChild("HumanoidRootPart")) and (player.Character.HumanoidRootPart.Position - mouse.Target.Position).magnitude <= 100 then
			if game.Players:FindFirstChild(mouse.Target.Parent.Name) or game.Players:FindFirstChild(mouse.Target.Parent.Parent.Name) then
				local playera = game.Players:FindFirstChild(mouse.Target.Parent.Name)
				if playera == nil then
					playera = game.Players:FindFirstChild(mouse.Target.Parent.Parent.Name)
				end
				if playera.Team == player.Team then
					interactionmouse.Fundo.Visible = true
					interactionmouse.Fundo.Username.Text = playera.Name
				else
					interactionmouse.Fundo.Visible = false
				end
			else
				interactionmouse.Fundo.Visible = false
			end
		else
			interactionmouse.Fundo.Visible = false
		end
	else
		interactionmouse.Fundo.Visible = false
	end

	if Yeet then

		local Raio = Ray.new(Camera.CFrame.Position, Camera.CFrame.LookVector * 6)
		local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(Raio, IgnoreList, false, true)

		

		if Hit then
			local FoundHuman,VitimaHuman = CheckForHumanoid(Hit)
			if FoundHuman == true and VitimaHuman.Health > 0 and game.Players:GetPlayerFromCharacter(VitimaHuman.Parent) then
				
				Target = game.Players:GetPlayerFromCharacter(VitimaHuman.Parent)
				
				
				
			else
				
				
				
				Target = nil
			end
		else
			
		
			
			Target = nil
		end
	end

	if Yeet and (Char.ACS_Client.Stances.Can_Rappel.Value == true or Char.ACS_Client.Stances.Rappeling.Value == true) then

		if not (Char.ACS_Client.Stances.Rappeling.Value == true) then
			local Raio = Ray.new(Camera.CFrame.Position, Camera.CFrame.LookVector * 12)
			local Hit, Pos = workspace:FindPartOnRayWithIgnoreList(Raio, IgnoreList, false, true)
		end
	end

end)

local function onMouseMove()
	local positionX = mouse.X
	local positionY = mouse.Y
	interactionmouse.Position =UDim2.new(0,positionX,0,positionY)
end
mouse.Move:Connect(onMouseMove)

Evt.Ombro.OnClientEvent:Connect(function(Nome)
	TextoOmbro.Text = Nome .." tapped your shoulder!"
	TextoOmbro.TextTransparency = 0
	TextoOmbro.TextStrokeTransparency = 0
	TS:Create(TextoOmbro, TweenInfo.new(5), {TextTransparency = 1,TextStrokeTransparency = 1} ):Play()
end)