--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type RankData = {
	Name: string,
	Requirement: number,
	Reward: number?,
}

export type InstitutionData = {
	Icon: string,
	DisplayName: string,
	DisplayOrder: number,

	Teams: {string},
	Ranks: {RankData}
}

local List: {[string]: InstitutionData} = {
	Homeland = {
		Icon = 'rbxassetid://83972790010960',
		DisplayName = 'Homeland Security',
		DisplayOrder = 1,

		Teams = {'Border Patrol', 'BORTAC', 'HSI', 'ICE'},
		Ranks = {
			{ Name = 'Cadet', Requirement = 0 }, -- Glock

			{ Name = 'Junior Officer', Requirement = 50, Reward = 100 }, -- M1911
			{ Name = 'Officer', Requirement = 125 },
			{ Name = 'Officer First Class', Requirement = 250, Reward = 200 }, -- Revolver

			{ Name = 'Senior Officer', Requirement = 450 },--ar15
			{ Name = 'Corporal', Requirement = 775, Reward = 400, },

			{ Name = 'Sergeant', Requirement = 1_300 },
			{ Name = 'Staff Sergeant', Requirement = 2_150, Reward = 700 },

			{ Name = 'Lieutenant', Requirement = 3_525 }, -- hk416
			{ Name = 'Captain', Requirement = 5_750, Reward = 1_200 },

			{ Name = 'Deputy Chief', Requirement = 9_350, Reward = 1_800 },
			{ Name = 'Chief', Requirement = 15_175, Reward = 2_500 },
		}
	},

	State = {
		Icon = 'rbxassetid://104013917682582',
		DisplayName = 'Texas Public Safety',
		DisplayOrder = 2,

		Teams = {'State Trooper'},
		Ranks = {
			{ Name = 'Cadet', Requirement = 0 },

			{ Name = 'Trooper', Requirement = 75, Reward = 100 },
			{ Name = 'Trooper First Class', Requirement = 225, Reward = 200 },

			{ Name = 'Senior Trooper', Requirement = 425 },
			{ Name = 'Corporal', Requirement = 700, Reward = 400 },

			{ Name = 'Sergeant', Requirement = 1_150 },
			{ Name = 'Staff Sergeant', Requirement = 1_900, Reward = 650 },

			{ Name = 'Lieutenant', Requirement = 3_100 },
			{ Name = 'Captain', Requirement = 5_000, Reward = 1_100 },

			{ Name = 'Major', Requirement = 8_000, Reward = 1_700 },
			{ Name = 'Colonel', Requirement = 13_000, Reward = 2_400 },
		}
	},
	Army = {
		Icon = 'rbxassetid://97454011385442',
		DisplayName = 'Department of War',
		DisplayOrder = 3,

		Teams = {'US Army'},
		Ranks = {
			{ Name = "Private", Requirement = 0 },

			{ Name = "Private Second Class", Requirement = 75, Reward = 100 },
			{ Name = "Private First Class", Requirement = 225, Reward = 200 },

			{ Name = "Specialist", Requirement = 425 },
			{ Name = "Corporal", Requirement = 700, Reward = 400 },

			{ Name = "Sergeant", Requirement = 1_150 },
			{ Name = "Staff Sergeant", Requirement = 1_900, Reward = 650 },

			{ Name = "Second Lieutenant", Requirement = 3_100 },
			{ Name = "Captain", Requirement = 5_000, Reward = 1_100 },

			{ Name = "Major", Requirement = 8_000, Reward = 1_700 },
			{ Name = "Colonel", Requirement = 13_000, Reward = 2_400 },
		}
	},
	DOJ = {
		Icon = 'rbxassetid://124316745779056',
		DisplayName = 'Department of Justice',
		DisplayOrder = 4,

		Teams = {'FBI'},
		Ranks = {
			{ Name = "Private", Requirement = 0 }, 

			{ Name = "Private Second Class", Requirement = 75, Reward = 100 },
			{ Name = "Private First Class", Requirement = 225, Reward = 200 },

			{ Name = "Specialist", Requirement = 425 },
			{ Name = "Corporal", Requirement = 700, Reward = 400 },

			{ Name = "Sergeant", Requirement = 1_150 },
			{ Name = "Staff Sergeant", Requirement = 1_900, Reward = 650 },

			{ Name = "Second Lieutenant", Requirement = 3_100 },
			{ Name = "Captain", Requirement = 5_000, Reward = 1_100 },

			{ Name = "Major", Requirement = 8_000, Reward = 1_700 },
			{ Name = "Colonel", Requirement = 13_000, Reward = 2_400 },
		}
	},
	Criminal = {
		Icon = 'rbxassetid://594651397', -- cambia el icono luego
		DisplayName = 'Criminal Network',
		DisplayOrder = 0,

		Teams = {'Civilian'},
		Ranks = {
			{ Name = 'Pickpocket', Requirement = 0 },

			{ Name = 'Street Thug', Requirement = 75, Reward = 100 },
			{ Name = 'Enforcer', Requirement = 225, Reward = 200 },

			{ Name = 'Crew Member', Requirement = 425 },
			{ Name = 'Crew Enforcer', Requirement = 700, Reward = 400 },

			{ Name = 'Lieutenant', Requirement = 1_150 },
			{ Name = 'Underboss', Requirement = 1_900, Reward = 650 },

			{ Name = 'Boss', Requirement = 3_100 },
			{ Name = 'Crime Lord', Requirement = 5_000, Reward = 1_100 },

			{ Name = 'Kingpin', Requirement = 8_000, Reward = 1_700 },
			{ Name = 'Legendary Kingpin', Requirement = 13_000, Reward = 2_400 },
		}
	},
}

for _, data in pairs(List) do
	table.sort(data.Ranks, function(a: RankData, b: RankData): boolean
		return a.Requirement < b.Requirement
	end)
end

TableUtil.Lock(List)
return List
