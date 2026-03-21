--!strict

export type NotificationType = "Warning" | "Error" | "Info" | "Success"
export type Item = {
	Type: NotificationType,
	Messages: { string },
}

export type Catalog = {
	[string]: {
		[string]: Item,
	},
}

local function freezeCatalog(catalog: Catalog): Catalog
	for _, group in pairs(catalog) do
		for _, item in pairs(group) do
			table.freeze(item.Messages)
			table.freeze(item)
		end

		table.freeze(group)
	end

	return table.freeze(catalog)
end

local catalog: Catalog = {
	Vehicle = {
		OutOfFuel = {
			Type = "Warning",
			Messages = {
				"Your vehicle is out of fuel. It cannot move until you refuel it.",
			},
		},
	},
}

return freezeCatalog(catalog)
