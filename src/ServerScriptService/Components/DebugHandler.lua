-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local DebugHandler = {}

--Fields the API returns, helps with autocomplete
type serverGeolocation = {as: string, asname: string, city: string, continent: string, continentCode: string,
	country: string, countryCode: string, currency: string, district: string, hosting: boolean, isp: string,
	lat: number, lon: number, mobile: boolean, offset: number, org: string, proxy: boolean, query: string,
	region: string, regionName: string, status: string, timezone: string, zip: string}

local function getServerGeolocation(): serverGeolocation
	local url = "https://demo.ip-api.com/json?fields=66842623"
	local success, response = pcall(function()
		return game.HttpService:GetAsync(url, nil, {origin = "https://ip-api.com"})
	end)
	if not success then
		warn(response)
		task.wait(1)
		return getServerGeolocation() 
	end
	local data = game.HttpService:JSONDecode(response)
	if data.status ~= "success" then
		warn("Failed to fetch server geolocation")
		task.wait(1)
		return getServerGeolocation()
	end
	return data 
end

-- Initialization function for the script
function DebugHandler:Initialize()

	local ServerData = getServerGeolocation()
	if ServerData then
		local ServerLocation = ServerData["countryCode"]
		
		RemoteBank.GetServerRegion.OnServerInvoke = function()
			return ServerLocation
		end
	end
	
	local ServerStart = os.time()
	
	
	RemoteBank.GetServerUptime.OnServerInvoke = function()
		return ServerStart
	end
end

return DebugHandler
