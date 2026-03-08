--!strict

export type FieldRule = {
	Default: any,
	Replicate: boolean?,
	Min: number?,
	Max: number?,
}

export type FieldDefinition = any | FieldRule

export type FieldsMap = {
	[string]: FieldDefinition,
}

local ProfileSchemaUtil = {}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function cloneValue(value: any, seen: { [table]: table }?): any
	if type(value) ~= "table" then
		return value
	end

	local resolvedSeen = seen
	if resolvedSeen == nil then
		resolvedSeen = {}
	end

	local existingClone = resolvedSeen[value]
	if existingClone ~= nil then
		return existingClone
	end

	local clone = {}
	resolvedSeen[value] = clone

	for key, childValue in pairs(value) do
		local nextKey = if type(key) == "table" then cloneValue(key, resolvedSeen) else key
		clone[nextKey] = cloneValue(childValue, resolvedSeen)
	end

	return clone
end

local function resolveRule(fieldDefinition: FieldDefinition): FieldRule
	if type(fieldDefinition) == "table" and (fieldDefinition :: any).Default ~= nil then
		return fieldDefinition :: FieldRule
	end

	return {
		Default = fieldDefinition,
	}
end

function ProfileSchemaUtil.BuildTemplate(fields: FieldsMap): { [string]: any }
	local template = {}

	for key, fieldDefinition in pairs(fields) do
		local rule = resolveRule(fieldDefinition)
		template[key] = cloneValue(rule.Default)
	end

	return template
end

function ProfileSchemaUtil.NormalizeValue(fieldDefinition: FieldDefinition, value: any): (boolean, any)
	local rule = resolveRule(fieldDefinition)
	local defaultValue = rule.Default

	if type(defaultValue) == "number" then
		if isFiniteNumber(value) ~= true then
			return false, nil
		end

		local normalized = value
		if rule.Min ~= nil and normalized < rule.Min then
			normalized = rule.Min
		end
		if rule.Max ~= nil and normalized > rule.Max then
			normalized = rule.Max
		end

		return true, normalized
	end

	if value == nil then
		return false, nil
	end

	return true, value
end

function ProfileSchemaUtil.SanitizeData(fields: FieldsMap, data: { [string]: any })
	for key, fieldDefinition in pairs(fields) do
		local rule = resolveRule(fieldDefinition)
		local ok, normalized = ProfileSchemaUtil.NormalizeValue(fieldDefinition, data[key])
		if ok ~= true then
			data[key] = cloneValue(rule.Default)
		else
			data[key] = cloneValue(normalized)
		end
	end
end

function ProfileSchemaUtil.IsReplicatedField(fieldDefinition: FieldDefinition): boolean
	local rule = resolveRule(fieldDefinition)
	return rule.Replicate ~= false
end

function ProfileSchemaUtil.BuildReplicatedData(fields: FieldsMap, sourceData: { [string]: any }): { [string]: any }
	local snapshot = {}

	for key, fieldDefinition in pairs(fields) do
		if ProfileSchemaUtil.IsReplicatedField(fieldDefinition) == true then
			snapshot[key] = cloneValue(sourceData[key])
		end
	end

	return snapshot
end

function ProfileSchemaUtil.IsNumericRule(fieldDefinition: FieldDefinition): boolean
	local rule = resolveRule(fieldDefinition)
	return type(rule.Default) == "number"
end

function ProfileSchemaUtil.CloneValue(value: any): any
	return cloneValue(value)
end

return table.freeze(ProfileSchemaUtil)
