--!strict
export type Setting = {
	Description: string,
	Default: boolean,
	Order: number,
}

local List: {[string]: Setting} = {
	["Global Shadows"] = {
		Description = "TIP: Disable shadows for better performance.",
		Default = true,
		Order = 1,
	},
	["MiniMap"] = {
		Order = 2,
		Description = "Hide Minimap visibility.",
		Default = false,
	},
	["Sound Effects"] = {
		Order = 3,
		Description = "Toggle Sound Effects.",
		Default = true,
	}
}

return List
