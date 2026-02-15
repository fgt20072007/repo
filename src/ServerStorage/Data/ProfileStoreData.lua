--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type ShareData = {
	Name: string,
	Path: {string},
	Priority: number?,
	Format: ((any) -> (string|number))?,
}

export type DataSettings<T> = {
	ReplicaToken: string,
	OverrideName: string?,
	DevEnvName: string?,
	KeyFormat: string?,

	Template: T,
	Share: {ShareData}|nil, -- Meaning sharing through leaderstats
}

export type PlayerData = {
	Cash: number,
	Vehicles: {string},
	XP: {[string]: number},
	
	Onboarded: {[string]: boolean},
	
	GiftedPasses: {string},
	Settings: {[string]: boolean},
}

export type PlayerSettings = {[string]: boolean}

local list: {
	PlayerData: DataSettings<PlayerData>,
} = TableUtil.Lock({
	PlayerData = {
		ReplicaToken = 'PlayerData', -- 
		KeyFormat = 'Player_%d',
		
		OverrideName = 'LiveOps',
		DevEnvName = 'NewTest1.1',

		Template = {
			Cash = 20_000,
			Vehicles = {},			
			XP = {},
			
			Onboarded = {},
			
			GiftedPasses = {},
			Settings = {},
			Loadouts = {},
		},
		Share = {
			{ Name = 'Cash', Path = {'Cash'} },
		},
	} :: DataSettings<PlayerData>,
})

return list
