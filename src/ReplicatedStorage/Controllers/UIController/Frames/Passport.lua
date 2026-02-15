local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages:WaitForChild("Net"))
local Observers = require(Packages:WaitForChild("Observers"))
local Trove = require(Packages:WaitForChild("Trove"))

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Main = PlayerGui:WaitForChild("Main")
local PassportUI = Main:WaitForChild("Passport")
local CloseButton = PassportUI:WaitForChild("CloseButton") :: GuiButton

local ShowPassportRE = Net:RemoteEvent("ShowPassport")

local trove

local Passport = {}
Passport.__index = Passport

local function getRandomDate()
	-- Start: January 1, 1970
	local from = os.time({
		year = 1970,
		month = 1,
		day = 1,
	})

	-- End: December 31, 2001
	local to = os.time({
		year = 2001,
		month = 12,
		day = 31,
	})

	-- Random unix timestamp between those two
	local randomUnix = math.random(from, to)

	-- Get as a table (year, month, day, etc.)
	local t = os.date("*t", randomUnix)

	-- Format as mm/dd/yyyy (or whatever you want)
	local dateString = string.format("%02d/%02d/%04d", t.month, t.day, t.year)

	return dateString
end

local function PadToLength(str: string, len: number): string
	str = string.upper(str)
	str = str:gsub("[^A-Z0-9]", "") -- quitamos caracteres raros

	if #str >= len then
		return str:sub(1, len)
	end

	return str .. string.rep("X", len - #str)
end

local function GenerateFakeCURP(player: Player): string
	-- 1) Parte del nombre (4 caracteres)
	local namePart = PadToLength(player.Name, 4)

	-- 2) Parte del UserId (últimos 6 dígitos)
	local userIdStr = tostring(player.UserId)
	local idPart = userIdStr
	if #userIdStr > 6 then
		idPart = userIdStr:sub(#userIdStr - 5, #userIdStr)
	elseif #userIdStr < 6 then
		idPart = string.rep("0", 6 - #userIdStr) .. userIdStr
	end

	-- 3) Parte aleatoria (8 caracteres alfanuméricos)
	local randomPart = ""

	-- Semilla pseudoaleatoria (opcional, para variar por jugador)
	math.randomseed(os.time() + player.UserId)

	for _ = 1, 8 do
		local n = math.random(0, 35) -- 0-9 + A-Z
		if n < 10 then
			randomPart ..= tostring(n)
		else
			randomPart ..= string.char(55 + n) -- 10 -> 'A', 11 -> 'B', etc.
		end
	end

	-- Total: 4 + 6 + 8 = 18 caracteres (como una CURP real, pero falsa)
	local fakeCURP = namePart .. idPart .. randomPart
	return fakeCURP
end

local date = getRandomDate()

function Passport.new(controller: any)
	local self = setmetatable({}, Passport)

	self._UIController = controller
	self._Trove = Trove.new()


	self:_Init()
	return self
end

function Passport:_Init()

	ShowPassportRE.OnClientEvent:Connect(function(ownerId: number)	
		self._UIController:Open("Passport")
		self:_setupPassport(ownerId)
	end)




end

function Passport:_setupPassport(ownerId: number)

	local player = Players:GetPlayerByUserId(ownerId)
	if not player then return end


	local usernameLabel = PassportUI:WaitForChild("Username") :: TextLabel
	if not usernameLabel then return end

	usernameLabel.Text = player.Name

	local displaynameLabel = PassportUI:WaitForChild("Displayname") :: TextLabel
	if not displaynameLabel then return end

	displaynameLabel.Text = player.DisplayName

	local userIdLabel = PassportUI:WaitForChild("UserId") :: TextLabel
	if not userIdLabel then return end

	userIdLabel.Text = player.UserId

	local dateLabel = PassportUI:WaitForChild("Date") :: TextLabel
	if not dateLabel then return end



	dateLabel.Text = date

	local playerImage = PassportUI:WaitForChild("PlayerImage") :: ImageLabel
	if not playerImage then return end

	local userImage = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

	playerImage.Image = userImage

	local randomSeed = PassportUI:WaitForChild("RandomSeed") :: TextLabel
	if not randomSeed then return end



	randomSeed.Text = GenerateFakeCURP(player)

	local dateOfIssue = PassportUI:WaitForChild("DateOfIssue") :: TextLabel
	if not dateOfIssue then return end

	dateOfIssue.Text = os.date("%x")

	local expiryDate = PassportUI:WaitForChild("ExpiryDate") :: TextLabel
	if not expiryDate then return end

	expiryDate.Text = os.date("%x", os.time() + (60 * 60 * 24 * 365 * 10))

	local signature = PassportUI:WaitForChild("Signature") :: TextLabel
	if not signature then return end

	signature.Text = player.Name

	local acceptedImage = PassportUI:WaitForChild("Accepted") :: ImageLabel
	if not acceptedImage then return end

	local revisionImages = {
		Approved = acceptedImage.Image,
		Secondary = "rbxassetid://134271761107706",
	}

	local function updateRevision(state: string?)
		local image = state and revisionImages[state] or nil
		if image then
			acceptedImage.Image = image
			acceptedImage.Visible = true
		else
			acceptedImage.Visible = false
		end
	end

	updateRevision(player:GetAttribute("Revision"))
	self._Trove:Add(Observers.observeAttribute(player, "Revision", function(state: string)
		updateRevision(state)
	end))


end

function Passport:OnOpen()
	if self._Trove then
		self._Trove:Destroy()
	end

	self._Trove = Trove.new()

	self._Trove:Connect(CloseButton.MouseButton1Click, function()
		self._UIController:Close(script.Name)
	end)

	return true
end

function Passport:OnClose()
	return 	true
end

return Passport