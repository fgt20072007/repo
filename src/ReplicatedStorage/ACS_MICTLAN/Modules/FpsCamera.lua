
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserGameSettings = UserSettings():GetService("UserGameSettings")
local player = Players.LocalPlayer


local PlayerScripts = player:WaitForChild("PlayerScripts")
local PlayerModule = PlayerScripts:WaitForChild("PlayerModule")
local TransparencyController = require(PlayerModule:FindFirstChild("TransparencyController", true))

local XZ_VECTOR3 = Vector3.new(1, 0, 1)

local FpsCamera = 
	{
		HeadMirrors = {};

		HeadAttachments = 
		{
			FaceCenterAttachment = true;
			FaceFrontAttachment = true;
			HairAttachment = true;
			HatAttachment = true;
		};

		InvalidRotationStates =
		{
			Swimming = true; 
			Climbing = true;
			Dead = true;
			Seated = true;
		};
	}



function FpsCamera:Warn(...)
	warn("[FpsCamera]", ...)
end


function FpsCamera:Connect(funcName, event)
	return event:Connect(function (...)
		self[funcName](self, ...)
	end)
end

function FpsCamera:IsInFirstPerson()
	local camera = workspace.CurrentCamera
	if camera then
		local cameraSubject = camera.CameraSubject
		if cameraSubject and cameraSubject:IsA("Humanoid") and cameraSubject.Parent and cameraSubject.Parent:FindFirstChild("Head") then
			local cameraPos = camera.CFrame.Position
			local headPos = cameraSubject.Parent.Head.CFrame.Position
			local magnitudeCheck = (cameraPos - headPos).Magnitude
			return magnitudeCheck <= 1
		end
	end
	return false
end

function FpsCamera:GetSubjectPosition()
	if self:IsInFirstPerson() then
		local camera = workspace.CurrentCamera
		local subject = camera.CameraSubject


		if subject and subject:IsA("Humanoid") then

			if subject.Health > 0 then
				local character = subject.Parent
				if character and character:IsA("Model") then
					local head = character:FindFirstChild("Head")
					if head and head:IsA("BasePart") then
						local cf = head.CFrame
						local offset = cf * CFrame.new(0, head.Size.Y / 2, 0)
						return offset.Position, cf.LookVector, cf
					end
				end
			end
		end
	end


	return self:GetBaseSubjectPosition()
end


function FpsCamera:IsValidPartToModify(part)
	if part:FindFirstAncestorOfClass("Tool") then
		return false
	end

	if part:IsA("Decal") then
		part = part.Parent
	end

	if part and part:IsA("BasePart") then
		local accessory = part:FindFirstAncestorWhichIsA("Accoutrement")
		if accessory then
			if part.Name ~= "Handle" then
				local handle = accessory:FindFirstChild("Handle", true)

				if handle and handle:IsA("BasePart") then
					part = handle
				end
			end

			for _,child in pairs(part:GetChildren()) do
				if child:IsA("Attachment") then
					if self.HeadAttachments[child.Name] then
						return true
					end
				end
			end
		elseif part:GetAttribute("FPInvis") then
			return true
		elseif part.Name == "Head" then
			local model = part.Parent
			local camera = workspace.CurrentCamera
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")

			if humanoid and camera.CameraSubject == humanoid then
				return true
			end
		end
	end

	return false
end

function FpsCamera:MountBaseCamera(BaseCamera)
	local base = BaseCamera.GetSubjectPosition
	self.GetBaseSubjectPosition = base

	if base then
		BaseCamera.GetBaseSubjectPosition = base
		BaseCamera.GetSubjectPosition = self.GetSubjectPosition
	else
		self:Warn("MountBaseCamera - Could not find BaseCamera:GetSubjectPosition()!")
	end
end

function FpsCamera:UpdateTransparency(...)
	assert(self ~= FpsCamera)
	self:BaseUpdate(...)
	if self.ForceRefresh then
		self.ForceRefresh = false

		if self.SetSubject then
			local camera = workspace.CurrentCamera
			self:SetSubject(camera.CameraSubject)
		end
	end
end


function FpsCamera:SetupTransparency(character, ...)
	assert(self ~= FpsCamera)
	self:BaseSetupTransparency(character, ...)

	if self.AttachmentListener then
		self.AttachmentListener:Disconnect()
	end

	self.AttachmentListener = character.DescendantAdded:Connect(function (obj)
		if obj:IsA("Attachment") and self.HeadAttachments[obj.Name] then
			if typeof(self.cachedParts) == "table" then
				self.cachedParts[obj.Parent] = true
			end

			if self.transparencyDirty ~= nil then
				self.transparencyDirty = true
			end
		end
	end)
end

function FpsCamera:MountTransparency(Transparency)
	local baseUpdate = Transparency.Update

	if baseUpdate then
		Transparency.BaseUpdate = baseUpdate
		Transparency.Update = self.UpdateTransparency
	else
		self:Warn("MountTransparency - Could not find Transparency:Update()!")
	end

	if Transparency.IsValidPartToModify then
		Transparency.IsValidPartToModify = self.IsValidPartToModify
		Transparency.HeadAttachments = self.HeadAttachments
		Transparency.ForceRefresh = true
	else
		self:Warn("MountTransparency - Could not find Transparency:IsValidPartToModify(part)!")
	end

	if Transparency.SetupTransparency then
		Transparency.BaseSetupTransparency = Transparency.SetupTransparency
		Transparency.SetupTransparency = self.SetupTransparency
	else
		self:Warn("MountTransparency - Could not find Transparency:SetupTransparency(character)!")
	end
end

function FpsCamera:GetShadowAngle()
	local angle = Lighting:GetSunDirection()

	if angle.Y < -0.3 then

		angle = Lighting:GetMoonDirection()
	end

	return angle
end

function FpsCamera:MirrorProperty(base, copy, prop)
	base:GetPropertyChangedSignal(prop):Connect(function ()
		copy[prop] = base[prop]
	end)
end


function FpsCamera:AddHeadMirror(desc)
	if desc:IsA("BasePart") and self:IsValidPartToModify(desc) then
		local mirror = desc:Clone()
		mirror:ClearAllChildren()

		mirror.Locked = true
		mirror.Anchored = true
		mirror.CanCollide = false
		mirror.Parent = self.MirrorBin

		local function onChildAdded(child)
			local prop

			if child:IsA("DataModelMesh") then
				prop = "Scale"
			elseif child:IsA("Decal") then
				prop = "Transparency"
			end

			if prop then
				local copy = child:Clone()
				copy.Parent = mirror

				self:MirrorProperty(child, copy, prop)
			end
		end

		for _,child in pairs(desc:GetChildren()) do
			onChildAdded(child)
		end

		self.HeadMirrors[desc] = mirror
		self:MirrorProperty(desc, mirror, "Transparency")

		desc.ChildAdded:Connect(onChildAdded)
	end
end


function FpsCamera:RemoveHeadMirror(desc)
	local mirror = self.HeadMirrors[desc]
	if mirror then
		mirror:Destroy()
		self.HeadMirrors[desc] = nil
	end
end

function FpsCamera:OnRotationTypeChanged()
	local camera = workspace.CurrentCamera
	local subject = camera and camera.CameraSubject

	-- Verificar si el sujeto es un Humanoid
	if subject and subject:IsA("Humanoid") then
		local rotationType = UserGameSettings.RotationType

		if rotationType == Enum.RotationType.CameraRelative then
			RunService:BindToRenderStep("FpsCamera", 1000, function(delta)
				-- Validar si el Humanoid sigue existiendo en el juego
				if not subject then
					RunService:UnbindFromRenderStep("FpsCamera")
					return
				end
				
				if subject.Health == 0 then
					RunService:UnbindFromRenderStep("FpsCamera")
					return
				end
				
				if not subject:IsDescendantOf(game) then
					RunService:UnbindFromRenderStep("FpsCamera")
					return
				end

				-- Verificar si está sentado en un VehicleSeat
				if subject.SeatPart and subject.SeatPart:IsA("VehicleSeat") then
					RunService:UnbindFromRenderStep("FpsCamera")
					return
				end

				-- Validar si la cámara está en un estado scriptable
				if not camera or camera.CameraType ~= Enum.CameraType.Custom then
					return
				end

				if self:IsInFirstPerson() then
					local cf = camera.CFrame
					local headPos, headLook = self:GetSubjectPosition(subject)

					if headPos then
						local offset = headPos - cf.Position
						cf += offset

						camera.CFrame = cf
						camera.Focus += offset
					end

					local shadowAngle = self:GetShadowAngle()
					if shadowAngle then
						local inView = cf.LookVector:Dot(shadowAngle)

						if inView < 0 and self.HeadMirrors then
							for real, mirror in pairs(self.HeadMirrors) do
								if real and mirror then
									mirror.CFrame = real.CFrame + (shadowAngle * 9)
								end
							end
						end

						if self.MirrorBin then
							self.MirrorBin.Parent = (inView < 0 and camera or nil)
						end
					end
				else
					if self.MirrorBin then
						self.MirrorBin.Parent = nil
					end
				end
			end)
		else
			if self.MirrorBin then
				self.MirrorBin.Parent = nil
			end
		end
	end
end


-- Called when the player's character is added.
-- Sets up mirroring of the player's head for first person.

function FpsCamera:OnCharacterAdded(character)
	local mirrorBin = self.MirrorBin

	if mirrorBin then
		mirrorBin:ClearAllChildren()
		mirrorBin.Parent = nil
	end

	self.HeadMirrors = {}

	for _,desc in pairs(character:GetDescendants()) do
		self:AddHeadMirror(desc)
	end

	self:Connect("AddHeadMirror", character.DescendantAdded)
	self:Connect("RemoveHeadMirror", character.DescendantRemoving)
end

-- Called once to start the FpsCamera logic.
-- Binds and overloads everything necessary.

local started = false

function FpsCamera:Start()
	if started then
		return
	else
		started = true
	end

	local character = player.Character or player.CharacterAdded:Wait()


	local baseCamera = PlayerModule:FindFirstChild("BaseCamera", true)

	if baseCamera and baseCamera:IsA("ModuleScript") then
		local module = require(baseCamera)
		self:MountBaseCamera(module)
	else
		self:Warn("Start - Could not find BaseCamera module!")
	end

	if TransparencyController then
		self:MountTransparency(TransparencyController)
	else
		self:Warn("Start - Cound not find TransparencyController module!")
	end

	local rotListener = UserGameSettings:GetPropertyChangedSignal("RotationType")
	self:Connect("OnRotationTypeChanged", rotListener)

	self.MirrorBin = Instance.new("Folder")
	self.MirrorBin.Name = "HeadMirrors"

	if character then
		self:OnCharacterAdded(character)
	end

	self:Connect("OnCharacterAdded", player.CharacterAdded)
end

return FpsCamera
