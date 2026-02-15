--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type Waypoint = {
	DisplayName: string,
	Color: Color3,
	Icon: string,
	
	MaxDistance: number?,
}

local List: {[string]: Waypoint} = {
	-- Countries
	USA = {
		DisplayName = 'U.S.A.',
		Color = Color3.fromRGB(32, 33, 36),
		Icon = 'rbxassetid://12412674916',
		
		MaxDistance = 175,
	},
	Mexico = {
		DisplayName = 'México',
		Color = Color3.fromRGB(32, 33, 36),
		Icon = 'rbxassetid://12781020300',
		
		MaxDistance = 175,
	},
	
	-- Border
	Scan = {
		DisplayName = 'Scanners',
		Color = Color3.fromRGB(220, 185, 45),
		Icon = 'rbxassetid://15899788627',
		
		MaxDistance = 175,
	},
	
	-- Role
	FBI = {
		DisplayName = 'FBI',
		Color = Color3.fromRGB(50, 95, 220),
		Icon = 'rbxassetid://105590462160402',
		
		MaxDistance = 350,
	},
	Customs = {
		DisplayName = 'U.S. Customs and Border Protection',
		Color = Color3.fromRGB(50, 95, 220),
		Icon = 'rbxassetid://240301662',
		
		MaxDistance = 350,
	},
	Safety = {
		DisplayName = 'Texas Department of Public Safety',
		Color = Color3.fromRGB(50, 95, 220),
		Icon = 'rbxassetid://13901514363',
		
		MaxDistance = 350,
	},
	
	-- Illegal
	BlackMarket = {
		DisplayName = 'Black Market',
		Color = Color3.fromRGB(220, 41, 41),
		Icon = 'rbxassetid://13429538917',
		
		MaxDistance = 500,
	},
	Gymbro = {
		DisplayName = 'Gymbro',
		Color = Color3.fromRGB(220, 41, 41),
		Icon = 'rbxassetid://10385947642',
		
		MaxDistance = 500,
	},
	Explosion = {
		DisplayName = 'Explosive Fence',
		Color = Color3.fromRGB(220, 41, 41),
		Icon = 'rbxassetid://17747093460',
		MaxDistance = 400,
	},
	
	--Legal
	Job = {
		DisplayName = 'Job',
		Color = Color3.fromRGB(220, 164, 34),
		Icon = 'rbxassetid://5739423239',

		MaxDistance = 400,
	},
}

TableUtil.Lock(List)
return List