--!strict

export type Handler = {
	OnTriggered: (player: Player, prompt: ProximityPrompt, context: any) -> (),
}

local HandlerResolver = {}

function HandlerResolver.Build(handlersFolder: Instance): { [string]: Handler }
	local handlersByTag: { [string]: Handler } = {}

	for _, child in handlersFolder:GetChildren() do
		if child:IsA("ModuleScript") ~= true then
			continue
		end

		local tag = child.Name
		if string.sub(tag, 1, 1) == "_" then
			continue
		end

		local handler = require(child :: ModuleScript) :: any
		if type(handler) ~= "table" or type(handler.OnTriggered) ~= "function" then
			error(`Handler "{tag}" must expose OnTriggered(player, prompt, context)`)
		end

		handlersByTag[tag] = handler
	end

	return handlersByTag
end

return table.freeze(HandlerResolver)