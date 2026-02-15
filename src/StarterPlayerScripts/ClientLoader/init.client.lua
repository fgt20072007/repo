--> Esto para esperar a que cargue el cliente antes de cargar los módulos
if not game:IsLoaded() then game.Loaded:Wait() end
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
--

task.wait(1)

local LoaderModule = script:WaitForChild('Init') :: ModuleScript

local success, result = pcall(require, LoaderModule)
if success then
	result.Init()
else
	warn("Failed to require module:", result)
end

local DraggableModule = script.Draggable :: ModuleScript
if not DraggableModule then return end

local success, result = pcall(require, DraggableModule)

if not success then
	warn("Failed to require module:", result)
end


local UIStrokeAdjuster = script.UIStrokeAdjuster :: ModuleScript
if not UIStrokeAdjuster then return end

local success, result = pcall(require, UIStrokeAdjuster)

if not success then
	warn("Failed to require module:", result)
end

