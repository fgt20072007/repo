--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local MarketplaceService = game:GetService("MarketplaceService")

--> Dependencies
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Debug = require(Packages:WaitForChild("Debug"))
local Net = require(Packages:WaitForChild("Net"))
local Trove = require(Packages:WaitForChild("Trove"))

local Controllers = ReplicatedStorage:WaitForChild('Controllers')
local ReplicaController = require(Controllers.ReplicaController)

local Data = ReplicatedStorage:WaitForChild("Data")
local Gamepass_Data = require(Data.Passes)
local Teams_Data = require(Data.Teams)
local GamepassOwnership = require(ReplicatedStorage.Util.GamepassOwnership)

local Player = Players.LocalPlayer
local PlayerGui  = Player:WaitForChild("PlayerGui") :: PlayerGui

local Main = PlayerGui:WaitForChild("Main") :: ScreenGui

local frame = Main:WaitForChild("ChooseTeam") :: Frame
local CloseButton = frame:WaitForChild("CloseButton") :: GuiButton

local Holder = frame:WaitForChild("Holder") :: Frame
local Grid = Holder:WaitForChild('UIGridLayout') :: UIGridLayout
local Template = Holder:WaitForChild("Template") :: Frame


local ChooseTeam = {}
ChooseTeam.__index = ChooseTeam

local GamepassToTeam = {}
local CanonicalTeamAliases: {[string]: string} = {
	["ICE"] = "HSI",
}
local LegacyTeamAliases: {[string]: string} = {
	["HSI"] = "ICE",
}

local function GetCanonicalTeamName(teamName: string): string
	return CanonicalTeamAliases[teamName] or teamName
end

local function ResolveTeamInstanceName(teamName: string): string?
	if Teams:FindFirstChild(teamName) then
		return teamName
	end

	local canonical = GetCanonicalTeamName(teamName)
	if canonical ~= teamName and Teams:FindFirstChild(canonical) then
		return canonical
	end

	local legacy = LegacyTeamAliases[canonical]
	if legacy and Teams:FindFirstChild(legacy) then
		return legacy
	end

	return nil
end

local function IsSameTeam(teamA: string?, teamB: string?): boolean
	if not teamA or not teamB then return false end
	if teamA == teamB then return true end
	return GetCanonicalTeamName(teamA) == GetCanonicalTeamName(teamB)
end

local function GetTeamMembers(teamName: string)
	if not teamName then return false end

	local resolvedTeamName = ResolveTeamInstanceName(teamName)
	if not resolvedTeamName then return false end

	local Team = Teams:FindFirstChild(resolvedTeamName) :: Team
	if not Team then return false end

	local playersInTeam = Team:GetPlayers()
	local amountOfPlayers = #playersInTeam

	if amountOfPlayers > 0 then
		return amountOfPlayers
	else
		return 0
	end
end


local function HasGamepass(GamepassName:string)
	return GamepassOwnership.Owns(GamepassName)
end

local function HasGamepassForTeam(TeamName:string)
	local TeamData = TeamName and Teams_Data[TeamName]
	if not TeamData then return true end

	local TeamGamepass = TeamData.GamepassID
	if not TeamGamepass then return true end -- Doesn't require gamepass so we give access

	return HasGamepass(TeamGamepass)
end

function ChooseTeam.new(controller)
	local self = setmetatable({}, ChooseTeam)

	self._name = "ChooseTeam"
	self._uiController = controller
	self._Trove = Trove.new()
	self._UI = frame
	self._choosenTeam = nil
	self._changeTeamRE = Net:RemoteEvent("ChangeTeam")

	self:_init()
	return self
end

function ChooseTeam:_init()
	self._UI.Visible = false
	return true
end

function ChooseTeam:_setupConnections()
	self._Trove:Connect(CloseButton.MouseButton1Click, function()
		self._uiController:Close(self._name)
	end)
	self._Trove:Add(Grid:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		self:_updateContentSize()
	end))

	self:_updateContentSize()
	return true
end

function ChooseTeam:_updateContentSize()
	local abs = Grid.AbsoluteContentSize
	Holder.CanvasSize = UDim2.fromOffset(abs.X, abs.Y + 20)
end


local function UpdateButtonFrame(teamName)
	local existingFrame = Holder:FindFirstChild(teamName)
	if not existingFrame then return end
	local joinButton = existingFrame:FindFirstChild("JoinButton", true) :: TextButton?
	if not joinButton then return end

	local hasGamepass = HasGamepassForTeam(teamName)
	local buttonText = hasGamepass and "Join" or "Buy Gamepass"

	local priceLabel = joinButton:FindFirstChild("PriceLabel", true)
	if priceLabel and priceLabel:IsA("TextLabel") then
		priceLabel.Text = buttonText
	else
		joinButton.Text = buttonText
	end

	for _, descendant in joinButton:GetDescendants() do
		if descendant.Name == "EnabledGradient" and descendant:IsA("UIGradient") then
			descendant.Enabled = hasGamepass
		elseif descendant.Name == "DisabledGradient" and descendant:IsA("UIGradient") then
			descendant.Enabled = not hasGamepass
		end
	end

	local enabledGradient = joinButton:FindFirstChild("EnabledGradient")
	if enabledGradient and enabledGradient:IsA("UIGradient") then
		enabledGradient.Enabled = hasGamepass
	end

	local disabledGradient = joinButton:FindFirstChild("DisabledGradient")
	if disabledGradient and disabledGradient:IsA("UIGradient") then
		disabledGradient.Enabled = not hasGamepass
	end

	return true	
end

local function UpdateAllFrames()
	for teamName, teamData in Teams_Data do
		if teamData.Ignore then continue end
		UpdateButtonFrame(teamName)
	end
end

function ChooseTeam:_createTeamFrame(teamName: string)
	if not teamName	then return end
	local existingFrame = Holder:FindFirstChild(teamName)
	if existingFrame then
		existingFrame:Destroy()
	end

	local teamInfo = Teams_Data[teamName]
	if not teamInfo then return false end


	local playerCount = GetTeamMembers(teamName)
	if not playerCount then
		Debug:Breakpoint(script.Name, "error getting team members")
		return false 
	end

	local teamFrame = self._Trove:Clone(Template)  :: Frame
	if not teamFrame then return false end

	teamFrame.Parent = Holder
	teamFrame.Name = teamName
	teamFrame.Visible = true
	teamFrame.LayoutOrder = teamInfo.LayoutOrder

	UpdateButtonFrame(teamName)

	local teamNameLabel = teamFrame:WaitForChild("TeamName") :: TextLabel
	if not teamNameLabel then return false end

	teamNameLabel.Text = teamInfo.Name or teamName

	local joinButton = teamFrame:WaitForChild("JoinButton") :: TextButton
	if not joinButton then return false end

	self._Trove:Connect(joinButton.MouseButton1Click, function()
		if not HasGamepassForTeam(teamName) then
			local passName = Teams_Data[teamName].GamepassID
			local passId = passName and Gamepass_Data[passName]
			if not passId then return end
			MarketplaceService:PromptGamePassPurchase(Player, passId)
			return
		end

		self._changeTeamRE:FireServer(teamName)
		self._uiController:Close(script.Name)
	end)


	local selectedUIStroke = teamFrame:WaitForChild("SelectedUIStroke") :: UIStroke
	selectedUIStroke.Enabled = false

	if IsSameTeam(Player.Team and Player.Team.Name, teamName) then
		joinButton.Visible = false

		if not selectedUIStroke then return false end
		selectedUIStroke.Enabled = true
	end

	local teamImage = teamFrame:WaitForChild("TeamImage") :: ImageLabel
	if not teamImage then return false end

	teamImage.Image = "rbxassetid://"..teamInfo.Image

	local playerCountLabel = teamFrame:WaitForChild("PlayerCount") :: TextLabel
	if not playerCountLabel then return false end

	if teamInfo.MaxPlayers then
		playerCountLabel.Text = string.format("(%s/%s)", playerCount, teamInfo.MaxPlayers :: any)
	else
		playerCountLabel.Text = playerCount
	end

end

function ChooseTeam:_setupTeamFrames()
	for index, value in Teams_Data do
		if value.Ignore then continue end
		self:_createTeamFrame(index) --//index is teamName
	end
end

local UpdateConnection = nil
function ChooseTeam:OnOpen()
	if self._Trove then
		self._Trove:Clean()
	end

	self:_setupConnections()	
	self:_setupTeamFrames()

	task.spawn(function()
		local succ, Replica: ReplicaController.Replica = ReplicaController.GetReplicaAsync("PlayerData"):await()
		if not succ then return end

		UpdateConnection = Replica:OnChange(function(Listener, Path)
			if Path[1] ~= "GiftedPasses" then return end
			GamepassOwnership.Invalidate()
			UpdateAllFrames()
		end)
		UpdateAllFrames()
	end)
end

function ChooseTeam:OnClose()
	if self._Trove then
		self._Trove:Clean()
	end

	if UpdateConnection then
		UpdateConnection:Disconnect()
	end

end


return ChooseTeam
