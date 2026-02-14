-- ShiftLockController.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Spring = require(script:WaitForChild("Spring"))
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ShiftLockController = {}

-- Configuration
local Settings = {
	MOBILE_SUPPORT = false,
	SMOOTH_CHARACTER_ROTATION = true,
	CHARACTER_ROTATION_SPEED = 10,
	CAMERA_TRANSITION_IN_SPEED = 10,
	CAMERA_TRANSITION_OUT_SPEED = 14,
	LOCKED_CAMERA_OFFSET = Vector3.new(1.75, 0.25, 0),
	LOCKED_MOUSE_ICON = "rbxasset://textures/MouseLockedCursor.png",
	SHIFT_LOCK_KEYBINDS = {
		Enum.KeyCode.LeftAlt,
		Enum.KeyCode.LeftControl,
	},
}

-- State
local connections = {}
local characterConnections = {}
local spring = Spring.new(Vector3.zero)
local character, humanoid, rootPart, head
local isShiftLocked = false
local isLocked = false
local canRotate = false
local transitionOutConnection = nil

local function cleanupTransitionConnection()
	if transitionOutConnection then
		transitionOutConnection:Disconnect()
		transitionOutConnection = nil
	end
end


local function disableShiftLock()
	if humanoid and canRotate then
		humanoid.AutoRotate = true
	end

	Mouse.Icon = ""
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	for _, conn in pairs(connections) do
		if conn then
			conn:Disconnect()
		end
	end
	table.clear(connections)

	cleanupTransitionConnection()

	if spring.Position.Magnitude > 0.01 then
		spring.Speed = Settings.CAMERA_TRANSITION_OUT_SPEED
		spring.Target = Vector3.zero

		transitionOutConnection = RunService.RenderStepped:Connect(function()
			if not (character and head and Camera) then
				spring.Position = Vector3.zero
				spring.Velocity = Vector3.zero
				cleanupTransitionConnection()
				return
			end

			if head.LocalTransparencyModifier <= 0.6 and (head.Position - Camera.CFrame.Position).Magnitude > 1 then
				Camera.CFrame = Camera.CFrame * CFrame.new(spring.Position)
			end

			if spring.Position.Magnitude < 0.01 then
				spring.Position = Vector3.zero
				spring.Velocity = Vector3.zero
				cleanupTransitionConnection()
			end
		end)
	else
		spring.Position = Vector3.zero
		spring.Target = Vector3.zero
		spring.Velocity = Vector3.zero
	end

	if character then
		for _, tool in ipairs(character:GetChildren()) do
			if tool:IsA("Tool") and tool:GetAttribute("Gun") then
				tool.Parent = LocalPlayer.Backpack
			end
		end
	end

	shared.InShiftLock = nil
end

-- Setup character and listeners
local function setupCharacter(char)
	character = char
	rootPart = char:WaitForChild("HumanoidRootPart")
	head = char:WaitForChild("Head")
	humanoid = char:WaitForChild("Humanoid")

	canRotate = not (char:FindFirstChild("RotateDisabled") or char:FindFirstChild("Dead"))

	spring = Spring.new(Vector3.zero)

	disableShiftLock()

	table.clear(characterConnections)

	table.insert(
		characterConnections,
		char.ChildAdded:Connect(function(child)
			if child.Name == "RotateDisabled" or child.Name == "Dead" then
				canRotate = false
				if child.Name == "Dead" then
					disableShiftLock()
				end
			end
		end)
	)

	table.insert(
		characterConnections,
		char.ChildRemoved:Connect(function(child)
			if child.Name == "RotateDisabled" or child.Name == "Dead" then
				task.wait()
				if not char:FindFirstChild("RotateDisabled") and not char:FindFirstChild("Dead") then
					canRotate = true
				end
			end
		end)
	)
end



-- Check if shift lock is disabled by boat or other systems
local function isShiftLockDisabled()
	if character and character:GetAttribute("ShiftLockDisabled") then
		return true
	end
	return false
end

-- Activate shift lock camera
local function enableShiftLock()
	if not character or character:FindFirstChild("Dead") then
		return
	end

	-- Don't enable if disabled by boat system
	if isShiftLockDisabled() then
		return
	end

	cleanupTransitionConnection()
	spring.Position = Vector3.zero
	spring.Velocity = Vector3.zero

	isShiftLocked = true
	shared.InShiftLock = true
	Mouse.Icon = Settings.LOCKED_MOUSE_ICON

	local startTime = tick()
	local lastCheck = tick()

	table.insert(
		connections,
		RunService.RenderStepped:Connect(function(dt)
			if not (character and rootPart and head and humanoid) then
				disableShiftLock()
				return
			end

			-- Auto-disable if boat or other system requests it
			if isShiftLockDisabled() then
				isShiftLocked = false
				disableShiftLock()
				return
			end

			local isScriptable = Camera.CameraType == Enum.CameraType.Scriptable

			if head.LocalTransparencyModifier <= 0.6 and (head.Position - Camera.CFrame.Position).Magnitude > 1 then
				Camera.CFrame *= CFrame.new(spring.Position)

				if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter and not isScriptable then
					UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				end
			end

			if canRotate then
				humanoid.AutoRotate = false
			end

			if not isScriptable then
				spring.Speed = Settings.CAMERA_TRANSITION_IN_SPEED
				spring.Target = Settings.LOCKED_CAMERA_OFFSET
			else
				spring.Position = Vector3.zero
				spring.Target = Vector3.zero
				spring.Velocity = Vector3.zero
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end

			-- Rotate character with camera
			if canRotate and Camera.CameraType ~= Enum.CameraType.Scriptable then
				local _, yaw, _ = Camera.CFrame:ToOrientation()
				local speed = Settings.CHARACTER_ROTATION_SPEED

				if tick() - startTime <= 2 then
					speed = 0.5 + math.clamp(tick() - startTime, 0, 2) / 2 * (Settings.CHARACTER_ROTATION_SPEED - 2)
				end

				rootPart.CFrame = rootPart.CFrame:Lerp(
					CFrame.new(rootPart.Position) * CFrame.Angles(0, yaw, 0),
					1 - math.exp(-dt * speed * 5)
				)
			end

			-- Recheck rotate status every 0.35s
			if tick() - lastCheck >= 0.35 then
				lastCheck = tick()
				canRotate = not (character:FindFirstChild("RotateDisabled") or character:FindFirstChild("Dead"))
			end
		end)
	)
end

-- Shift lock toggle handler
local function onShiftLockToggle(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return
	end

	if isLocked then
		return
	end

	-- Don't toggle if disabled by boat system
	if isShiftLockDisabled() then
		return
	end

	if isShiftLocked then
		isShiftLocked = false
		disableShiftLock()
	else
		if character and not character:FindFirstChild("Dead") then
			enableShiftLock()
		end
	end
end

local function disableDefaultRobloxShiftLock()
	pcall(function()
		LocalPlayer.DevEnableMouseLock = false
	end)

	ContextActionService:UnbindAction("MouseLockSwitchAction")
end

-- Public API
function ShiftLockController.ToggleShiftLock(_, state)
	if state and not isShiftLocked and character and not character:FindFirstChild("Dead") then
		enableShiftLock()
	else
		isShiftLocked = false
		disableShiftLock()
	end
end

function ShiftLockController.CurrentlyShiftlocked()
	return isShiftLocked
end

function ShiftLockController.LockShiftLockState(_, locked)
	isLocked = locked
end

-- Initialization
if LocalPlayer.Character then
	task.spawn(function()
		setupCharacter(LocalPlayer.Character)
	end)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

disableDefaultRobloxShiftLock()
task.defer(disableDefaultRobloxShiftLock)

ContextActionService:BindActionAtPriority(
	"ShiftLockSwitchAction",
	onShiftLockToggle,
	Settings.MOBILE_SUPPORT,
	Enum.ContextActionPriority.Medium.Value,
	unpack(Settings.SHIFT_LOCK_KEYBINDS)
)

return ShiftLockController
