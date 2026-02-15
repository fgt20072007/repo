--!strict
export type Data = {
	Teams: {string},
	
	Illegal: boolean?,
	Weapon: boolean?,
	DetectionRate: number?,
	
	SellPrice: number?,
	CarryMax: number?,
	Price: number?,
	GamepassOnly:string?,
	
	Config: {[any]: any}?,
}

local List: {[string]: Data} = {
	-- Civilians
	["Passport"] = {
		Teams = {"All"}
	},
	["Sign"] = {
		Teams = {"All"}
	},	
	
	["SpeedGun"] = {
		Teams = {"All"}
	},	
	
	["PepperSpray"] = {
		Teams = {"All"}
	},
	
	["Clipboard"] = {
		Teams = {"All"}
	},
	
	["StopSign"] = {
		Teams = {"All"}
	},
	
	["Flashlight"] = {
		Teams = {"All"}
	},
	
	-- Guns
	["Hi-Point"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 1250,
	},
	
	["Glock"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 3000,
	},

	["TEC-9"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 4750,
	},
	
	["AR-15"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 7400,
	},
	
	["AK-47"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 9500,
	},
	
	["M249"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,
		GamepassOnly = "Heavy Weapons",

		CarryMax = 1,
		Price = 3_500,
	},
	
	["M110"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,
		GamepassOnly = "Heavy Weapons",

		CarryMax = 1,
		Price = 3_500,
	},
	
	["M82"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,
		GamepassOnly = "Heavy Weapons",

		CarryMax = 1,
		Price = 4_500,
	},
	

	["Revolver"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 5_000,
	},
	
	["M1911"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 5_000,
	},
	
	["Benelli M4"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 500_000,
	},
	
	["Golden Deagle"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,
		GamepassOnly = "El Patron",

		CarryMax = 1,
		Price = 0,
	},
	
	["HK416"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 5_000,
	},
	
	["M4A1 Mod"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 5_000,
	},
	
	["SIG MCX-SPEAR"] = {
		Teams = {"All"},

		Weapon = true,
		Illegal = true,
		DetectionRate = 100,

		CarryMax = 1,
		Price = 500_000,
	},
	

	
	
	-- Feds
	["Cone"] = {
		Teams = {"Federal"},
		Config = {
			MaxPerPlayer = 5,
			MaxDistance = 70,

			MaxInclination = 45,
			TriggerInclination = 30,
		}
	},
	["Cuffs"] = {
		Teams = {"Federal"},
	},
	["Stamp"] = {
		Teams = {"Federal"},
	},
	["Taser"] = {
		Teams = {"Federal"},
	},
	
	-- Smuggling
	['C4'] = {
		Teams = {'Civilian'},
		
		Illegal = true,
		DetectionRate = 25,
		
		CarryMax = 1,
		Price = 1_250,
	},
	['Bloxy Cola'] = {
		Teams = {'Civilian'},

		Illegal = true,
		DetectionRate = 20,

		SellPrice = 220,
		CarryMax = 6,
		Price = 100,
	},
	['Sarsaparilla'] = {
		Teams = {'Civilian'},

		Illegal = true,
		DetectionRate = 30,

		SellPrice = 300,
		CarryMax = 5,
		Price = 140,
	},
	['Fake Watch'] = {
		Teams = {'Civilian'},

		Illegal = true,
		DetectionRate = 75,

		SellPrice = 2_200,
		CarryMax = 3,
		Price = 750,
	},
	['Fake Designer Bag'] = {
		Teams = {'Civilian'},

		Illegal = true,
		DetectionRate = 65,

		SellPrice = 1_200,
		CarryMax = 3,
		Price = 480,
	},
	['Taco'] = {
		Teams = {'Civilian'},

		Illegal = true,
		DetectionRate = 5,

		SellPrice = 130,
		CarryMax = 8,
		Price = 35,
	},
	['Briefcase'] = {
		Teams = {'Civilian'},
	}
}

return List