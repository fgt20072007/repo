--!strict

export type HandlerMap = { [number]: any }
export type KeyByIdMap = { [number]: string }

local HandlerResolver = {}

local function invertMap(keyToIdMap: { [string]: number }): KeyByIdMap
	local keyById: KeyByIdMap = {}

	for key, id in pairs(keyToIdMap) do
		if type(key) ~= "string" then
			error("Product key must be a string")
		end
		if type(id) ~= "number" then
			error(`Product id for key "{key}" must be a number`)
		end
		if keyById[id] ~= nil then
			error(`Duplicate id mapping detected: {id}`)
		end

		keyById[id] = key
	end

	return keyById
end

function HandlerResolver.BuildHandlers(keyToIdMap: { [string]: number }, handlersFolder: Instance): (KeyByIdMap, HandlerMap)
	local keyById = invertMap(keyToIdMap)
	local handlersById: HandlerMap = {}

	for id, key in pairs(keyById) do
		local moduleScript = handlersFolder:FindFirstChild(key)
		if moduleScript == nil then
			continue
		end
		if moduleScript:IsA("ModuleScript") ~= true then
			error(`Handler entry "{key}" must be a ModuleScript`)
		end
		local typedModule = moduleScript :: ModuleScript

		handlersById[id] = require(typedModule)
	end

	return keyById, handlersById
end

return table.freeze(HandlerResolver)
