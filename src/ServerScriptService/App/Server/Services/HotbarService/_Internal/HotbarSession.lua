local HttpService = game:GetService("HttpService")

local Maid = require(game:GetService("ReplicatedStorage"):WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Maid"))

local HotbarSession = {}
HotbarSession.__index = HotbarSession

local MAX_SLOTS = 9

local ROD_BINDING = {
	Attachment = {
		AttachTo = "Right Arm",
		AttachPart = "Handle",
		C0 = CFrame.new(0.087, -0.954, 0.067),
	},
	Holster = {
		AttachTo = "Torso",
		AttachPart = "Handle",
		C0 = CFrame.new(
			0, 5, 0.85,
			-0.34200656, 0.9396976, -0.0000070035458,
			-0.0000070035458, -0.00001001358, -1,
			-0.9396976, -0.34200656, 0.00001001358
		),
		C1 = CFrame.new(
			0.013807335, -3.4370182, -4.8953605,
			0.95162845, 0.30725852, 0.000007734284,
			-0.22046198, 0.682774, 0.6965777,
			0.21401864, -0.6628841, 0.7174823
		),
	},
}

local KNIFE_BINDING = {
	Attachment = {
		AttachTo = "Right Arm",
		AttachPart = "Handle",
		C0 = CFrame.new(0.087, -0.954, 0.067),
	},
}

local function formatToolLabel(entry)
	if not entry then
		return "unknown"
	end

	return string.format("%s (slot %d)", entry.toolName, entry.slot)
end

function HotbarSession.new(player, net, toggleRateLimit)
	local self = setmetatable({}, HotbarSession)

	self._player = player
	self._net = net
	self._toggleRateLimit = toggleRateLimit
	self._maid = Maid.New()
	self._characterMaid = Maid.New()

	self._slots = table.create(MAX_SLOTS)
	self._uidToSlot = {}
	self._toolToUid = setmetatable({}, { __mode = "k" })
	self._sentSlotSignatures = {}
	self._equippedSlot = nil
	self._warnedMissingEvent = {}
	self._rodMotors = setmetatable({}, { __mode = "k" })
	self._knifeMotors = setmetatable({}, { __mode = "k" })

	return self
end

function HotbarSession:_resolveAttachToPart(character, attachTo)
	local direct = character:FindFirstChild(attachTo)
	if direct and direct:IsA("BasePart") then
		return direct
	end

	if attachTo == "Right Arm" then
		local rightHand = character:FindFirstChild("RightHand")
		if rightHand and rightHand:IsA("BasePart") then
			return rightHand
		end
	end

	return nil
end

function HotbarSession:_clearRodMotor(tool)
	local motor = self._rodMotors[tool]
	if motor then
		motor:Destroy()
		self._rodMotors[tool] = nil
	end
end

function HotbarSession:_bindRodMotor(tool, binding)
	local character = self._player.Character
	if not character or tool.Parent ~= character then
		self:_clearRodMotor(tool)
		return
	end

	local attachToPart = self:_resolveAttachToPart(character, binding.AttachTo)
	if not attachToPart then
		self:_clearRodMotor(tool)
		return
	end

	local attachPart = tool:FindFirstChild(binding.AttachPart, true)
	if not attachPart or not attachPart:IsA("BasePart") then
		self:_clearRodMotor(tool)
		return
	end

	local motor = self._rodMotors[tool]
	if motor and (not motor.Parent or not motor:IsDescendantOf(game)) then
		self._rodMotors[tool] = nil
		motor = nil
	end

	if not motor then
		motor = Instance.new("Motor6D")
		motor.Name = "RodMotor6D"
		self._rodMotors[tool] = motor
	end

	motor.Part0 = attachToPart
	motor.Part1 = attachPart
	motor.C0 = binding.C0
	motor.C1 = binding.C1 or CFrame.identity
	motor.Parent = attachToPart
end

function HotbarSession:_syncRodBindings()
	local equippedTool = nil
	local equippedEntry = self._equippedSlot and self._slots[self._equippedSlot] or nil
	if equippedEntry then
		equippedTool = equippedEntry.tool
	end

	for slot = 1, MAX_SLOTS do
		local entry = self._slots[slot]
		if entry then
			local tool = entry.tool
			if tool and tool:IsA("Tool") and tool:GetAttribute("Rod") == true then
				if tool == equippedTool then
					self:_bindRodMotor(tool, ROD_BINDING.Attachment)
				else
					self:_clearRodMotor(tool)
				end
			end
		end
	end
end

function HotbarSession:_clearKnifeMotor(tool)
	local motor = self._knifeMotors[tool]
	if motor then
		motor:Destroy()
		self._knifeMotors[tool] = nil
	end
end

function HotbarSession:_bindKnifeMotor(tool, binding)
	local character = self._player.Character
	if not character or tool.Parent ~= character then
		self:_clearKnifeMotor(tool)
		return
	end

	local attachToPart = self:_resolveAttachToPart(character, binding.AttachTo)
	if not attachToPart then
		self:_clearKnifeMotor(tool)
		return
	end

	local attachPart = tool:FindFirstChild(binding.AttachPart, true)
	if not attachPart or not attachPart:IsA("BasePart") then
		self:_clearKnifeMotor(tool)
		return
	end

	local motor = self._knifeMotors[tool]
	if motor and (not motor.Parent or not motor:IsDescendantOf(game)) then
		self._knifeMotors[tool] = nil
		motor = nil
	end

	if not motor then
		motor = Instance.new("Motor6D")
		motor.Name = "KnifeMotor6D"
		self._knifeMotors[tool] = motor
	end

	motor.Part0 = attachToPart
	motor.Part1 = attachPart
	motor.C0 = binding.C0
	motor.C1 = binding.C1 or CFrame.identity
	motor.Parent = attachToPart
end

function HotbarSession:_syncKnifeBindings()
	local equippedTool = nil
	local equippedEntry = self._equippedSlot and self._slots[self._equippedSlot] or nil
	if equippedEntry then
		equippedTool = equippedEntry.tool
	end

	for slot = 1, MAX_SLOTS do
		local entry = self._slots[slot]
		if entry then
			local tool = entry.tool
			local hasKnifeOrSwordBinding = tool and tool:IsA("Tool") and (tool:GetAttribute("Knife") == true or tool:GetAttribute("Sword") == true)
			if hasKnifeOrSwordBinding then
				if tool == equippedTool then
					self:_bindKnifeMotor(tool, KNIFE_BINDING.Attachment)
				else
					self:_clearKnifeMotor(tool)
				end
			end
		end
	end
end

function HotbarSession:_fireNet(eventName, ...)
	local eventObject = self._net[eventName]
	if type(eventObject) ~= "table" then
		if not self._warnedMissingEvent[eventName] then
			self._warnedMissingEvent[eventName] = true
		end
		return
	end

	local fire = eventObject.Fire
	if type(fire) ~= "function" then
		if not self._warnedMissingEvent[eventName] then
			self._warnedMissingEvent[eventName] = true
		end
		return
	end

	fire(self._player, ...)
end

function HotbarSession:_getHumanoid()
	local character = self._player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end

	return nil
end

function HotbarSession:_generateUid(tool)
	local existingUid = self._toolToUid[tool]
	if existingUid then
		return existingUid
	end

	local attributeUid = tool:GetAttribute("HUID")
	if type(attributeUid) == "string" and attributeUid ~= "" then
		self._toolToUid[tool] = attributeUid
		return attributeUid
	end

	local uid = HttpService:GenerateGUID(false)
	self._toolToUid[tool] = uid
	tool:SetAttribute("HUID", uid)

	return uid
end

function HotbarSession:_getToolTextureId(tool)
	local textureId = tool.TextureId
	if type(textureId) ~= "string" then
		return ""
	end

	return textureId
end

function HotbarSession:_enumeratePlayerTools()
	local seen = {}
	local tools = {}

	local function collectFrom(container: Instance?)
		if not container then
			return
		end

		for _, child in container:GetChildren() do
			if child:IsA("Tool") then
				if not seen[child] then
					seen[child] = true
					table.insert(tools, child)
				end
			end
		end
	end

	collectFrom(self._player:FindFirstChild("Backpack"))
	collectFrom(self._player.Character)

	table.sort(tools, function(a, b)
		local aUid = self:_generateUid(a)
		local bUid = self:_generateUid(b)
		if aUid == bUid then
			return a.Name < b.Name
		end
		return aUid < bUid
	end)

	return tools
end

function HotbarSession:_firstFreeSlot()
	for slot = 1, MAX_SLOTS do
		if self._slots[slot] == nil then
			return slot
		end
	end

	return nil
end

function HotbarSession:_buildSlotEntry(tool)
	return {
		uid = self:_generateUid(tool),
		tool = tool,
		toolName = tool.Name,
		textureId = self:_getToolTextureId(tool),
	}
end

function HotbarSession:_rebuildSlots()
	local tools = self:_enumeratePlayerTools()
	local presentByUid = {}

	for _, tool in tools do
		local uid = self:_generateUid(tool)
		presentByUid[uid] = tool
		local existingSlot = self._uidToSlot[uid]

		if existingSlot then
			self._slots[existingSlot] = self:_buildSlotEntry(tool)
		else
			local freeSlot = self:_firstFreeSlot()
			if freeSlot then
				self._uidToSlot[uid] = freeSlot
				self._slots[freeSlot] = self:_buildSlotEntry(tool)
			end
		end
	end

	for uid, slot in pairs(self._uidToSlot) do
		if presentByUid[uid] == nil then
			self._uidToSlot[uid] = nil
			self._slots[slot] = nil
		end
	end
end

function HotbarSession:_syncSlotPayloads()
	for slot = 1, MAX_SLOTS do
		local entry = self._slots[slot]
		if entry then
			local signature = `{entry.uid}|{entry.toolName}|{entry.textureId}`
			if self._sentSlotSignatures[slot] ~= signature then
				self._sentSlotSignatures[slot] = signature
				self:_fireNet("HotbarSetSlot", slot, entry.uid, entry.toolName, entry.textureId)
			end
		else
			if self._sentSlotSignatures[slot] ~= nil then
				self._sentSlotSignatures[slot] = nil
				self:_fireNet("HotbarClearSlot", slot)
			end
		end
	end
end

function HotbarSession:_findEquippedSlot()
	local character = self._player.Character
	if not character then
		return nil
	end

	local currentSlot = self._equippedSlot
	if currentSlot then
		local currentEntry = self._slots[currentSlot]
		if currentEntry and currentEntry.tool and currentEntry.tool.Parent == character then
			return currentSlot
		end
	end

	local candidateSlots = {}

	for _, child in character:GetChildren() do
		if child:IsA("Tool") then
			local uid = self:_generateUid(child)
			local slot = self._uidToSlot[uid]
			if slot and self._slots[slot] then
				table.insert(candidateSlots, slot)
			end
		end
	end

	if #candidateSlots == 0 then
		return nil
	end

	table.sort(candidateSlots)
	return candidateSlots[1]
end

function HotbarSession:_syncEquippedState(force)
	local previousEquippedSlot = self._equippedSlot
	local newEquippedSlot = self:_findEquippedSlot()
	if not force and self._equippedSlot == newEquippedSlot then
		return
	end

	if self._equippedSlot then
		self:_fireNet("HotbarSetEquipped", self._equippedSlot, false)
	end

	self._equippedSlot = newEquippedSlot

	if newEquippedSlot then
		self:_fireNet("HotbarSetEquipped", newEquippedSlot, true)
	end

	if previousEquippedSlot ~= newEquippedSlot then
		local previousEntry = previousEquippedSlot and self._slots[previousEquippedSlot] or nil
		local newEntry = newEquippedSlot and self._slots[newEquippedSlot] or nil

		if newEquippedSlot == nil then
			print(string.format("%s desequipo %s", self._player.Name, formatToolLabel(previousEntry and {
				toolName = previousEntry.toolName,
				slot = previousEquippedSlot,
			} or nil)))
		elseif previousEquippedSlot == nil then
			print(string.format("%s equipo %s", self._player.Name, formatToolLabel({
				toolName = newEntry and newEntry.toolName or "unknown",
				slot = newEquippedSlot,
			})))
		else
			print(string.format("%s cambio %s -> %s", self._player.Name, formatToolLabel({
				toolName = previousEntry and previousEntry.toolName or "unknown",
				slot = previousEquippedSlot,
			}), formatToolLabel({
				toolName = newEntry and newEntry.toolName or "unknown",
				slot = newEquippedSlot,
			})))
		end
	end

	self:_syncRodBindings()
	self:_syncKnifeBindings()
end

function HotbarSession:_syncAll()
	self:_rebuildSlots()
	self:_syncSlotPayloads()
	self:_syncEquippedState(false)
end

function HotbarSession:_bindCharacter(character)
	self._characterMaid:Cleanup()
	self._characterMaid = Maid.New()

	self._characterMaid:Add(character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			self:_syncAll()
		end
	end))

	self._characterMaid:Add(character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			self:_syncAll()
		end
	end))

	self:_syncAll()
end

function HotbarSession:Start()
	local backpack = self._player:WaitForChild("Backpack")

	self._maid:Add(backpack.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			self:_syncAll()
		end
	end))

	self._maid:Add(backpack.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			self:_syncAll()
		end
	end))

	self._maid:Add(self._player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(character)
	end))

	self._maid:Add(self._player.CharacterRemoving:Connect(function()
		self._characterMaid:Cleanup()
		self._characterMaid = Maid.New()
		self:_syncAll()
	end))

	if self._player.Character then
		self:_bindCharacter(self._player.Character)
	else
		self:_syncAll()
	end
end

function HotbarSession:HandleToggleRequest(slot)
	if type(slot) ~= "number" then
		return
	end

	slot = math.floor(slot)
	if slot < 1 or slot > MAX_SLOTS then
		return
	end

	if not self._toggleRateLimit:CheckRate(self._player) then
		return
	end

	local entry = self._slots[slot]
	if not entry then
		return
	end

	local tool = entry.tool
	if tool.Parent ~= self._player.Character and tool.Parent ~= self._player:FindFirstChild("Backpack") then
		self:_syncAll()
		return
	end

	local humanoid = self:_getHumanoid()
	if not humanoid then
		return
	end

	if self._equippedSlot == slot then
		humanoid:UnequipTools()
		self:_syncEquippedState(true)
		return
	end

	humanoid:EquipTool(tool)
	self:_syncAll()
	self:_syncEquippedState(true)
end

function HotbarSession:Destroy()
	for tool, _ in pairs(self._rodMotors) do
		self:_clearRodMotor(tool)
	end

	for tool, _ in pairs(self._knifeMotors) do
		self:_clearKnifeMotor(tool)
	end

	self._characterMaid:Cleanup()
	self._maid:Cleanup()
end

return table.freeze({
	new = HotbarSession.new,
})