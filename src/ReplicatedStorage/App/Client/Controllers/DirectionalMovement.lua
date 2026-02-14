local module_upvr = {}

function module_upvr.Start()
	task.spawn(function()
		local LocalPlayer = game.Players.LocalPlayer
		local Character = LocalPlayer.CharacterAdded:Wait()
		if Character:GetAttribute("CustomRig") then
			return
		end

		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		local Torso = Character:WaitForChild("Torso")
		local RootJoint = HumanoidRootPart:WaitForChild("RootJoint")
		local Neck = Torso:WaitForChild("Neck")
		local RightShoulder = Torso:WaitForChild("Right Shoulder")
		local LeftShoulder = Torso:WaitForChild("Left Shoulder")
		local RightHip = Torso:WaitForChild("Right Hip")
		local LeftHip = Torso:WaitForChild("Left Hip")

		-- Store initial C0 values to reset later
		local initialRootJointC0 = RootJoint.C0
		local initialNeckC0 = Neck.C0
		local initialRightShoulderC0 = RightShoulder.C0
		local initialLeftShoulderC0 = LeftShoulder.C0
		local initialRightHipC0 = RightHip.C0
		local initialLeftHipC0 = LeftHip.C0

		-- Directional speed multipliers
		local speedMultipliers = {
			Forwards = 1,
			ForwardsRight = 0.975,
			Right = 0.925,
			BackwardsRight = 0.8,
			Backwards = 0.7,
			BackwardsLeft = 0.8,
			Left = 0.925,
			ForwardsLeft = 0.975,
		}

		local Humanoid = Character:WaitForChild("Humanoid")

		local lastUpdateTime = 0
		local isActive = false

		-- CFrame offsets used for smooth interpolation
		local rootJointOffset = CFrame.new()
		local neckOffset = CFrame.new()
		local rightShoulderOffset = CFrame.new()
		local leftShoulderOffset = CFrame.new()
		local rightHipOffset = CFrame.new()
		local leftHipOffset = CFrame.new()

		local function UpdateDirectionalMovement()
			if Humanoid.WalkSpeed <= 0.1 or HumanoidRootPart.Anchored or
				Character:GetAttribute("DirectionalMovementDisabled") or Character:GetAttribute("Ragdolling") then

				-- Reset joints if active
				if isActive then
					isActive = false
					RootJoint.C0 = initialRootJointC0
					Neck.C0 = initialNeckC0
					RightShoulder.C0 = initialRightShoulderC0
					LeftShoulder.C0 = initialLeftShoulderC0
					RightHip.C0 = initialRightHipC0
					LeftHip.C0 = initialLeftHipC0
				end
				return
			end

			isActive = true
			local currentTime = workspace:GetServerTimeNow()
			if currentTime - lastUpdateTime >= 1 / 60 then
				lastUpdateTime = currentTime

				-- Get the move direction relative to HumanoidRootPart orientation
				local moveDir = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)

				-- Helper function to smoothly interpolate joint rotations and apply speed multiplier
				local function ApplyMovement(rotationRoot, rotationShoulders, rotationHips, speedMult)
					rootJointOffset = rootJointOffset:Lerp(rotationRoot, 0.25)
					RootJoint.C0 = initialRootJointC0 * rootJointOffset

					neckOffset = neckOffset:Lerp(rotationShoulders, 0.25)

					rightShoulderOffset = rightShoulderOffset:Lerp(rotationShoulders, 0.25)
					RightShoulder.C0 = initialRightShoulderC0 * rightShoulderOffset

					leftShoulderOffset = leftShoulderOffset:Lerp(rotationShoulders, 0.25)
					LeftShoulder.C0 = initialLeftShoulderC0 * leftShoulderOffset

					rightHipOffset = rightHipOffset:Lerp(rotationHips, 0.25)
					RightHip.C0 = initialRightHipC0 * rightHipOffset

					leftHipOffset = leftHipOffset:Lerp(rotationHips, 0.25)
					LeftHip.C0 = initialLeftHipC0 * leftHipOffset

				end

				-- Check the direction with dot products and apply rotations accordingly
				local dir = moveDir.Unit
				if dir == Vector3.new(0,0,0) then
					-- No movement, reset rotations and speed
					ApplyMovement(CFrame.new(), CFrame.new(), CFrame.new(), 1)
					return
				end

				-- Direction checks in priority order (similar to original)
				if 0.95 < moveDir:Dot(Vector3.new(1, 0, -1).Unit) then
					ApplyMovement(
						CFrame.Angles(math.rad(-moveDir.Z) * 5, 0, math.rad(-moveDir.X) * 15),
						CFrame.Angles(0, math.rad(moveDir.X) * 10, 0),
						CFrame.Angles(0, math.rad(-moveDir.X) * 25, 0),
						speedMultipliers.ForwardsRight
					)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(1, 0, 1).Unit) then
					ApplyMovement(
						CFrame.Angles(math.rad(-moveDir.Z) * 5, 0, math.rad(moveDir.X) * 15),
						CFrame.Angles(0, math.rad(moveDir.X) * 10, 0),
						CFrame.Angles(0, math.rad(moveDir.X) * 25, 0),
						speedMultipliers.BackwardsRight
					)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(-1, 0, 1).Unit) then
					ApplyMovement(
						CFrame.Angles(math.rad(-moveDir.Z) * 5, 0, math.rad(moveDir.X) * 15),
						CFrame.Angles(0, math.rad(moveDir.X) * 10, 0),
						CFrame.Angles(0, math.rad(moveDir.X) * 25, 0),
						speedMultipliers.BackwardsLeft
					)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(-1, 0, -1).Unit) then
					ApplyMovement(
						CFrame.Angles(math.rad(-moveDir.Z) * 5, 0, math.rad(-moveDir.X) * 15),
						CFrame.Angles(0, math.rad(moveDir.X) * 10, 0),
						CFrame.Angles(0, math.rad(-moveDir.X) * 25, 0),
						speedMultipliers.ForwardsLeft
					)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(0, 0, -1).Unit) then
					ApplyMovement(CFrame.new(), CFrame.new(), CFrame.new(), speedMultipliers.Forwards)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(1, 0, 0).Unit) then
					ApplyMovement(
						CFrame.Angles(0, 0, math.rad(-moveDir.X) * 35),
						CFrame.Angles(0, math.rad(moveDir.X) * 15, 0),
						CFrame.Angles(0, math.rad(-moveDir.X) * 25, 0),
						speedMultipliers.Right
					)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(0, 0, 1).Unit) then
					ApplyMovement(
						CFrame.Angles(math.rad(-moveDir.Z) * 15, 0, 0),
						CFrame.new(),
						CFrame.new(),
						speedMultipliers.Backwards
					)
					return
				end
				if 0.95 < moveDir:Dot(Vector3.new(-1, 0, 0).Unit) then
					ApplyMovement(
						CFrame.Angles(0, 0, math.rad(-moveDir.X) * 35),
						CFrame.Angles(0, math.rad(moveDir.X) * 15, 0),
						CFrame.Angles(0, math.rad(-moveDir.X) * 30, 0),
						speedMultipliers.Left
					)
					return
				end

				-- Default fallback
				ApplyMovement(CFrame.new(), CFrame.new(), CFrame.new(), 1)
			end
		end

		local Head = Character:WaitForChild("Head", 10)
		local neckLookOffset = CFrame.new()

		local function UpdateNeckDirection()
			if isActive then
				local headPos = Head.CFrame.p
				local lookPos = headPos + workspace.CurrentCamera.CFrame.LookVector * 10
				-- Calculate rotation angles to smoothly rotate neck towards camera's look direction
				local pitch = math.atan((Head.CFrame.Y - lookPos.Y) / (headPos - lookPos).magnitude) * 0.5
				local yaw = -((headPos - lookPos).Unit:Cross(Torso.CFrame.lookVector).Y * -1)
				neckLookOffset = neckLookOffset:Lerp(CFrame.Angles(pitch, 0, yaw), 0.05)
				Neck.C0 = initialNeckC0 * neckLookOffset
			end
		end

		-- Connect to RenderStepped to update each frame
		module_upvr.Connection = game:GetService("RunService").RenderStepped:Connect(function()
			UpdateDirectionalMovement()
			UpdateNeckDirection()
		end)
	end)
end

function module_upvr.Destroy()
	if module_upvr.Connection then
		module_upvr.Connection:Disconnect()
		module_upvr.Connection = nil
	end
end

return module_upvr
