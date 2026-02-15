--!strict

export type VehicleType = 'SUV'|'Utility'|'Military'|'Cargo'|'Sedan'|'Luxury'

export type Data = {
	Teams: {string},

	Name:	string?,
	Price: number?,
	TopSpeed: number?,
	HorsePower: number?,
	CarYear:number?,
	GamepassOnly:string?,
	GamepassProvidesVehicle:boolean?,
	ImageRbxAssetId:string?,
	VehicleType:VehicleType?,
	
	Config: {[any]: any}?,
}


local List: {[number]: Data} = {
	--Civilian
	{
		Name = "Hunda Civic",
		Teams = {"Civilian"},
		Price  =  0,
		TopSpeed = 130,
		HorsePower = 250,
		CarYear = 1998,
		ImageRbxAssetId = "rbxassetid://100084149467616",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Tontoya Comry",
		Teams = {"Civilian"},
		Price  =  12500,
		TopSpeed = 120,
		HorsePower = 270,
		CarYear = 2012,
		ImageRbxAssetId = "rbxassetid://117242771261129",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Madza 3",
		Teams = {"Civilian"},
		Price  =  20000,
		TopSpeed = 120,
		HorsePower = 285,
		GamepassOnly = "Starterpack",
		GamepassProvidesVehicle = true,
		CarYear = 2016,
		ImageRbxAssetId = "rbxassetid://137010939527130",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Chevlon Express",
		Teams = {"Civilian"},
		Price  =  26500,
		TopSpeed = 125,
		HorsePower = 290,
		CarYear = 2015,
		ImageRbxAssetId = "rbxassetid://105819548381855",
		VehicleType = "Utility"
	},
	
	{
		Name = "Falcon F150",
		Teams = {"Civilian"},
		Price  =  32500,
		TopSpeed = 125,
		HorsePower = 290,
		CarYear = 2018,
		ImageRbxAssetId = "rbxassetid://139381536113439",
		VehicleType = "Utility"
	},
	
	{
		Name = "Tontoya Tronda",
		Teams = {"Civilian"},
		Price  =  40000,
		TopSpeed = 130,
		HorsePower = 300,
		CarYear = 2019,
		ImageRbxAssetId = "rbxassetid://120389554683894",
		VehicleType = "Utility"
	},
	
	{
		Name = "Chevlon Tahon",
		Teams = {"Civilian"},
		Price  =  45000,
		TopSpeed = 130,
		HorsePower = 300,
		CarYear = 2018,
		ImageRbxAssetId = "rbxassetid://112430073890455",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Cadillon Escalade",
		Teams = {"Civilian"},
		Price  =  75000,
		TopSpeed = 140,
		HorsePower = 320,
		CarYear = 2022,
		ImageRbxAssetId = "rbxassetid://109365704659513",
		VehicleType = "SUV"
	},
	
	{
		Name = "Bullghini Uros",
		Teams = {"Civilian"},
		Price  =  200000,
		TopSpeed = 180,
		HorsePower = 340,
		CarYear = 2023,
		GamepassOnly = "Luxury Cars",
		GamepassProvidesVehicle = false,
		ImageRbxAssetId = "rbxassetid://89132471575163",
		VehicleType = "Luxury"
	},

	{
		Name = "RR Collinan",
		Teams = {"Civilian"},
		Price  =  0,
		TopSpeed = 200,
		HorsePower = 300,
		CarYear = 2021,
		GamepassOnly = "Luxury Cars",
		GamepassProvidesVehicle = true,
		ImageRbxAssetId = "rbxassetid://103627336466442",
		VehicleType = "Luxury"
	},
	
	{
		Name = "Ferdinand 911 GT3",
		Teams = {"Civilian"},
		Price  =  470000,
		TopSpeed = 200,
		HorsePower = 370,
		CarYear = 2023,
		GamepassOnly = "Luxury Cars",
		GamepassProvidesVehicle = false,
		ImageRbxAssetId = "rbxassetid://79665198124096",
		VehicleType = "Luxury"
	},

	
	--// Border Patrol
	
	{
		Name = "Falcon Crown BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  0,
		TopSpeed = 120,
		HorsePower = 290,
		CarYear = 2012,
		ImageRbxAssetId = "rbxassetid://95615218024012",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Falcon Explorer BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  12500,
		TopSpeed = 120,
		HorsePower = 290,
		CarYear = 2021,
		ImageRbxAssetId = "rbxassetid://94549355229136",
		VehicleType = "SUV"
	},
	
	{
		Name = "Bull Charger BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  24500,
		TopSpeed = 150,
		HorsePower = 330,
		CarYear = 2017,
		ImageRbxAssetId = "rbxassetid://117512327595726",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Chevlon Express BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  28500,
		TopSpeed = 125,
		HorsePower = 290,
		CarYear = 2015,
		ImageRbxAssetId = "rbxassetid://123290957737974",
		VehicleType = "Utility"
	},
	
	{
		Name = "Chevlon Tahon BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  37000,
		TopSpeed = 130,
		HorsePower = 300,
		CarYear = 2017,
		ImageRbxAssetId = "rbxassetid://79382630508366",
		VehicleType = "SUV"
	},

	{
		Name = "Chevlon Silverado BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  47000,
		TopSpeed = 130,
		HorsePower = 280,
		CarYear = 2020,
		ImageRbxAssetId = "rbxassetid://93982402588711",
		VehicleType = "Utility"
	},
	
	
	
	{
		Name = "Falcon Raptor BP",
		Teams = {"Border Patrol", "BORTAC"},
		Price  =  72000,
		TopSpeed = 140,
		HorsePower = 320,
		CarYear = 2018,
		ImageRbxAssetId = "rbxassetid://137429244526978",
		VehicleType = "Utility"
	},
	
	--// Unmarked
	
	{
		Name = "Falcon Crown Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  0,
		TopSpeed = 120,
		HorsePower = 280,
		CarYear = 2012,
		ImageRbxAssetId = "rbxassetid://118212782400080",
		VehicleType = "Cargo"
	},
	
	{
		Name = "Bull Charger Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  32500,
		TopSpeed = 130,
		HorsePower = 290,
		CarYear = 2017,
		ImageRbxAssetId = "rbxassetid://99970400939745",
		VehicleType = "SUV"
	},
	
	{
		Name = "Falcon F150 Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  32500,
		TopSpeed = 130,
		HorsePower = 290,
		CarYear = 2018,
		ImageRbxAssetId = "rbxassetid://130522498362212",
		VehicleType = "SUV"
	},
	{
		Name = "Chevlon Silverado Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  47000,
		TopSpeed = 120,
		HorsePower = 270,
		CarYear = 2020,
		ImageRbxAssetId = "rbxassetid://97746304778521",
		VehicleType = "Utility"
	},
	
	
	
	{
		Name = "Falcon Expedition Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  69500,
		TopSpeed = 130,
		HorsePower = 290,
		CarYear = 2023,
		ImageRbxAssetId = "rbxassetid://121703160955457",
		VehicleType = "SUV"
	},
	
	{
		Name = "Chevlon Tahon Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  45000,
		TopSpeed = 130,
		HorsePower = 300,
		CarYear = 2017,
		ImageRbxAssetId = "rbxassetid://108923330151564",
		VehicleType = "SUV"
	},
	
	
	
	{
		Name = "Tontoya Comry Unmarked",
		Teams = {"HSI", "BORTAC", "FBI", "US Army"},
		Price  =  20000,
		TopSpeed = 200,
		HorsePower = 300,
		CarYear = 2012,
		ImageRbxAssetId = "rbxassetid://117242771261129",
		VehicleType = "Sedan"
	},
	
	--// state trooper
	
	{
		Name = "Chevlon Tahon Trooper",
		Teams = {"State Trooper"},
		Price  =  0,
		TopSpeed = 120,
		HorsePower = 280,
		CarYear = 2017,
		ImageRbxAssetId = "rbxassetid://74814651040014",
		VehicleType = "Cargo"
	},
	
	
	{
		Name = "Falcon Explorer Trooper",
		Teams = {"State Trooper"},
		Price  =  20000,
		TopSpeed = 120,
		HorsePower = 290,
		CarYear = 2021,
		ImageRbxAssetId = "rbxassetid://115377696041560",
		VehicleType = "SUV"
	},
	
	{
		Name = "Bull Charger Trooper",
		Teams = {"State Trooper"},
		Price  =  24500,
		TopSpeed = 150,
		HorsePower = 330,
		CarYear = 2017,
		ImageRbxAssetId = "rbxassetid://81782944090421",
		VehicleType = "Sedan"
	},
	
	{
		Name = "Falcon Crown Trooper",
		Teams = {"State Trooper"},
		Price  =  20000,
		TopSpeed = 120,
		HorsePower = 290,
		CarYear = 2012,
		ImageRbxAssetId = "rbxassetid://106535484445434",
		VehicleType = "Sedan"
	},
	
	
	
	
	--// GAMEPASS ONLY //--
	
	
	{
		Name = "Humvee M1114",
		Teams = {"US Army"},
		Price  =  0,
		TopSpeed = 120,
		HorsePower = 300,
		GamepassOnly = "US Army",
		GamepassProvidesVehicle = true,
		CarYear = 2005,
		ImageRbxAssetId = "rbxassetid://137261039293760",
		VehicleType = "Military"
	},
	
	{
		Name = "Poloros MZR4",
		Teams = {"Federal"},
		Price  =  0,
		TopSpeed = 120,
		HorsePower = 300,
		GamepassOnly = "US Army",
		GamepassProvidesVehicle = true,
		CarYear = 2014,
		ImageRbxAssetId = "rbxassetid://139270860927032",
		VehicleType = "Cargo"
	},
	
	{
		Name = "Osnkosh BearCat G4",
		Teams = {"Federal"},
		Price  =  285000,
		TopSpeed = 110,
		HorsePower = 300,
		CarYear = 2013,
		ImageRbxAssetId = "rbxassetid://128739114731863",
		VehicleType = "Military"
	},
	
	
	--// Luxury cars

	
	
	
}

return List
