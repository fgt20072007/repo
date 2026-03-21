--!strict

local General = {



	Container = {
		Cost = 0,
	},

	Garages = {
		Slots = {
			["Default"] = {
				Slots = 3,
				Cost = 0, -- Default garage is free (Lo obtienes por default)
			},
			["Medium"] = {
				Slots = 10,
				Cost = 5000,
			},
			["Large"] = {
				Slots = 20,
				Cost = 20000,
			},
			["Premium"] = {
				Slots = 64,
				isRobux = true,
			},
		}
	}



}

return table.freeze(General)