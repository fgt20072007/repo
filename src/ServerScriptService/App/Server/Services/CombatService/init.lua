local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local netRoot = shared:WaitForChild("Net")
local Net = require(netRoot:WaitForChild("Server"))
local Maid = require(shared:WaitForChild("Util"):WaitForChild("Maid"))
local RateLimit = require(shared:WaitForChild("Util"):WaitForChild("RateLimit"))

local CombatConfig = require(shared.Data.CombatConfig)
local Knifes = require(shared.Data.Knifes)
local Swords = require(shared.Data.Swords)

local internal = script:WaitForChild("_Internal")
local CombatState = require(internal:WaitForChild("CombatState"))
local CombatHitbox = require(internal:WaitForChild("CombatHitbox"))

local CombatService = {}
CombatService.__index = CombatService

local function resolveNetEvent(container, pascalName)
	if type(container) ~= "table" then
		return nil
	end

	local eventObject = container[pascalName]
	if eventObject ~= nil then
		return eventObject
	end

	local camelName = string.lower(string.sub(pascalName, 1, 1)) .. string.sub(pascalName, 2)
	eventObject = container[camelName]
	if eventObject ~= nil then
		return eventObject
	end

	local eventsContainer = container.Events or container.events
	if type(eventsContainer) == "table" then
		eventObject = eventsContainer[pascalName]
		if eventObject ~= nil then
			return eventObject
		end

		return eventsContainer[camelName]
	end

	return nil
end

local function isCombatTool(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	return tool:GetAttribute("Knife") == true or tool:GetAttribute("Sword") == true
end

local function resolveWeaponType(tool)
	if tool:GetAttribute("Knife") == true then
		return "Knife"
	end

	if tool:GetAttribute("Sword") == true then
		return "Sword"
	end

	return nil
end

local function resolveWeaponData(tool, weaponType)
	if weaponType == "Knife" then
		return Knifes[tool.Name] or Knifes.Default
	end

	if weaponType == "Sword" then
		return Swords[tool.Name] or Swords.Default
	end

	return nil
end

local function resolveComboCount(weaponData)
	local animations = weaponData.Animations
	if animations and animations.Combo then
		return math.max(#animations.Combo, #weaponData.ComboDamage)
	end

	return math.max(1, #weaponData.ComboDamage)
end

function CombatService.new()
	local self = setmetatable({}, CombatService)

	self._initialized = false
	self._started = false
	self._maid = Maid.New()
	self._state = CombatState.new()
	self._attackRateLimit = RateLimit.New(CombatConfig.AttackRatePerSecond)
	self._parryRateLimit = RateLimit.New(CombatConfig.ParryRatePerSecond)

	self._netEvents = {
		CombatRequestAttack = resolveNetEvent(Net, "CombatRequestAttack"),
		CombatRequestParry = resolveNetEvent(Net, "CombatRequestParry"),
	}

	return self
end

function CombatService:_resolveEquippedCombatTool(player)
	local character = player.Character
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end

	for _, child in ipairs(character:GetChildren()) do
		if isCombatTool(child) then
			return child, character
		end
	end

	return nil, character
end

function CombatService:_computeDamage(weaponData, comboIndex)
	local comboDamage = weaponData.ComboDamage[comboIndex]
	if type(comboDamage) == "number" then
		return comboDamage
	end

	return weaponData.Damage
end

function CombatService:_applyAttack(player, requestedComboIndex)
	if not self._attackRateLimit:CheckRate(player) then
		return
	end

	local now = os.clock()
	if self._state:IsParrying(player, now) then
		return
	end

	local tool, character = self:_resolveEquippedCombatTool(player)
	if not tool or not character then
		return
	end

	local weaponType = resolveWeaponType(tool)
	if not weaponType then
		return
	end

	local weaponData = resolveWeaponData(tool, weaponType)
	if not weaponData then
		return
	end

	local comboCount = resolveComboCount(weaponData)
	local comboIndex = self._state:ConsumeComboIndex(
		player,
		now,
		comboCount,
		CombatConfig.ComboResetTime,
		requestedComboIndex
	)

	local baseDamage = self:_computeDamage(weaponData, comboIndex)
	if type(baseDamage) ~= "number" or baseDamage <= 0 then
		return
	end

	local hitboxConfig = weaponData.Hitbox or CombatConfig.Hitbox
	local victims = CombatHitbox.Cast(character, hitboxConfig)

	for _, humanoid in ipairs(victims) do
		local targetCharacter = humanoid.Parent
		if targetCharacter ~= character then
			local finalDamage = baseDamage
			local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
			if targetPlayer and self._state:IsParrying(targetPlayer, now) then
				finalDamage = finalDamage * CombatConfig.ParryDamageMultiplier
			end

			humanoid:TakeDamage(finalDamage)
		end
	end
end

function CombatService:_applyParry(player)
	if not self._parryRateLimit:CheckRate(player) then
		return
	end

	local now = os.clock()
	if not self._state:CanParry(player, now) then
		return
	end

	local tool = self:_resolveEquippedCombatTool(player)
	if not tool then
		return
	end

	self._state:BeginParry(player, now, CombatConfig.ParryDuration, CombatConfig.ParryCooldown)
end

function CombatService:Init()
	if self._initialized then
		return
	end
	self._initialized = true

	local attackEvent = self._netEvents.CombatRequestAttack
	if type(attackEvent) == "table" and type(attackEvent.On) == "function" then
		self._maid:Add(attackEvent.On(function(player, comboIndex)
			self:_applyAttack(player, comboIndex)
		end))
	end

	local parryEvent = self._netEvents.CombatRequestParry
	if type(parryEvent) == "table" and type(parryEvent.On) == "function" then
		self._maid:Add(parryEvent.On(function(player)
			self:_applyParry(player)
		end))
	end

	self._maid:Add(Players.PlayerRemoving:Connect(function(player)
		self._state:RemovePlayer(player)
		self._attackRateLimit:CleanSource(player)
		self._parryRateLimit:CleanSource(player)
	end))
end

function CombatService:Start()
	if self._started then
		return
	end
	self._started = true
end

local singleton = CombatService.new()

return table.freeze({
	Init = function()
		singleton:Init()
	end,
	Start = function()
		singleton:Start()
	end,
})
