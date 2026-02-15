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
local Loadouts_Data = require(Data.Loadouts)
local RanksData = require(Data.Ranks)

local Player = Players.LocalPlayer
local PlayerGui  = Player:WaitForChild("PlayerGui") :: PlayerGui

local LoadoutUI = PlayerGui:WaitForChild("Loadout") :: ScreenGui

local frame = LoadoutUI:WaitForChild("TeamLoadout") :: Frame

local Buttons = frame:WaitForChild("Buttons")
local CloseButton = Buttons:WaitForChild("Close"):WaitForChild("Trigger")
local RemoveBundleButton = Buttons:WaitForChild("Remove"):WaitForChild("Trigger")

local LeftFrame = frame:WaitForChild("LeftSide")
local RightFrame = frame:WaitForChild("RightSide")

--[[
local Holder = frame:WaitForChild("Holder") :: Frame
local Grid = Holder:WaitForChild('UIGridLayout') :: UIGridLayout
local Template = Holder:WaitForChild("Template") :: Frame
]]



local Remote = Net:RemoteEvent("Loadout")

local UpdateConnection = nil
local CanonicalLoadoutTeamAliases: {[string]: string} = {
	["ICE"] = "HSI",
}
local LegacyLoadoutTeamAliases: {[string]: string} = {
	["HSI"] = "ICE",
}

local function GetCanonicalLoadoutTeam(teamName: string): string
	return CanonicalLoadoutTeamAliases[teamName] or teamName
end

local function GetLegacyLoadoutTeam(teamName: string): string?
	return LegacyLoadoutTeamAliases[teamName]
end

local function GetTeamLoadoutData(loadoutsData: any, teamName: string): any
	if not loadoutsData then return nil end
	local canonicalTeamName = GetCanonicalLoadoutTeam(teamName)
	local teamData = loadoutsData[canonicalTeamName]
	if teamData ~= nil then return teamData end
	local legacyTeamName = GetLegacyLoadoutTeam(canonicalTeamName)
	if legacyTeamName then
		return loadoutsData[legacyTeamName]
	end
	return nil
end

local function GetLegacyEquippedName(teamName: string, buttonName: string): string?
	local canonicalTeamName = GetCanonicalLoadoutTeam(teamName)
	if canonicalTeamName ~= "HSI" then return nil end
	if string.sub(buttonName, 1, 4) == "HSI " then
		return `ICE {string.sub(buttonName, 5)}`
	end
	if string.sub(buttonName, 1, 4) == "ICE " then
		return `HSI {string.sub(buttonName, 5)}`
	end
	return nil
end

local function IsButtonEquipped(buttonName: string, categoryData: any, teamName: string): boolean
	if categoryData == nil then return false end
	local legacyName = GetLegacyEquippedName(teamName, buttonName)

	if typeof(categoryData) == "string" then
		return categoryData == buttonName or (legacyName ~= nil and categoryData == legacyName)
	end
	if typeof(categoryData) ~= "table" then return false end
	if #categoryData > 0 then
		return table.find(categoryData, buttonName) ~= nil or (legacyName ~= nil and table.find(categoryData, legacyName) ~= nil)
	end
	return categoryData[buttonName] == true or (legacyName ~= nil and categoryData[legacyName] == true)
end


local function UpdateAllFrames()
	local PlayerData  = ReplicaController.GetReplica('PlayerData')
	local Data = PlayerData and PlayerData.Data
	local LoadoutsData = Data and Data.Loadouts

	if not LoadoutsData then return end

	local CurrentTeam = Player.Team and Player.Team.Name
	if not CurrentTeam then return end

	local function UpdateButton(Button)
		local CategoryIndex = Button:GetAttribute("CategoryName")
		local TeamData = GetTeamLoadoutData(LoadoutsData, CurrentTeam)
		--local CategoryData = TeamData and TeamData[CategoryIndex]

		--print(CategoryData,CategoryIndex, TeamData)
		--if not CategoryData then return end
		if not TeamData then return end
		local categoryData = TeamData[CategoryIndex]
		local IsEquipped = IsButtonEquipped(Button.Name, categoryData, CurrentTeam)
		Button:SetAttribute("LastEquipped", IsEquipped)

		local Color = IsEquipped and Color3.fromRGB(255, 179, 0) or Color3.fromRGB(85, 255, 127)
		Button.Effect.BackgroundColor3 = Color
		Button.Effect.Frame.BackgroundColor3 = Color
		Button.ObjectStatus.Text = IsEquipped and "Equipped" or "Unlocked"
	end

	local LeftHolderScrollingFrame = LeftFrame.Container.ScrollingFrame
	local RightHolderScrollingFrame = RightFrame.Container.ScrollingFrame

	for _, RankFrame in LeftHolderScrollingFrame:GetChildren() do
		if not (RankFrame:IsA("Frame") and RankFrame.Name ~= "RankTemplate") then continue end

		for _, Button in RankFrame.Lower.ItemsHolder:GetChildren() do
			if not (Button:IsA("Frame") and RankFrame.Name ~= "ItemTemplate") then continue end
			UpdateButton(Button)
		end
	end

	for _, RankFrame in RightHolderScrollingFrame:GetChildren() do
		if not (RankFrame:IsA("Frame") and RankFrame.Name ~= "RankTemplate") then continue end

		for _, Button in RankFrame.Lower.ItemsHolder:GetChildren() do
			if not (Button:IsA("Frame") and RankFrame.Name ~= "ItemTemplate") then continue end
			UpdateButton(Button)
		end
	end


end

local function GetCurrentInstitution(player: Player): string?
	local plrTeam = player.Team
	if not plrTeam then return nil end

	for id, data in RanksData do
		if not table.find(data.Teams, plrTeam.Name) then continue end
		return id
	end

	return nil
end

local function GetCurrentExp(Player)
	local Institution = GetCurrentInstitution(Player)
	if not Institution then return nil end

	local succ, Replica: ReplicaController.Replica = ReplicaController.GetReplicaAsync("PlayerData"):await()
	if not succ or not Replica then return nil end

	local xpTable = Replica.Data and Replica.Data.XP
	if not xpTable then return 0 end

	return xpTable[Institution] or 0
end

local function GetCurrentRank(Player:Player)
	local CurrentIntitution = GetCurrentInstitution(Player)
	local CurrentExp = GetCurrentExp(Player)	

	if not CurrentIntitution or CurrentExp == nil then return end

	local RankIndex, CurrentRank = nil, nil
	for thisRankIndex, RankData in RanksData[CurrentIntitution].Ranks do
		if RankData.Requirement > CurrentExp then continue end
		RankIndex = thisRankIndex
		CurrentRank = RankData.Name
	end

	return RankIndex, CurrentRank
end

local function IsRankReached(RankName:string)
	local CurrentInstitution = GetCurrentInstitution(Player)
	if not CurrentInstitution then return false end

	local institutionData = RanksData[CurrentInstitution]
	if not institutionData then return false end

	local CurrentExp = GetCurrentExp(Player)
	if CurrentExp == nil then return false end

	for _, RankData in institutionData.Ranks do
		if RankData.Name == RankName then
			return RankData.Requirement <= CurrentExp
		end
	end

	return false
end

local function Clean()
	for _, Frame in LeftFrame.Container.ScrollingFrame:GetChildren() do
		if Frame:IsA("Frame") and Frame.Name ~= "RankTemplate" then
			Frame:Destroy()
		end
	end

	for _, Frame in RightFrame.Container.ScrollingFrame:GetChildren() do
		if Frame:IsA("Frame") and Frame.Name ~= "RankTemplate" then
			Frame:Destroy()
		end
	end
end

local function GetOrCreateRankTemplate(RankName, RankTemplate:Instance)
	local RankCategoryFrame = RankTemplate.Parent:FindFirstChild(RankName)
	if not RankCategoryFrame then
		RankCategoryFrame = RankTemplate:Clone()
		RankCategoryFrame.Header.Title.Text = `Rank: {RankName}`
		RankCategoryFrame.Name = RankName
		RankCategoryFrame.Visible = true
		RankCategoryFrame.Parent = RankTemplate.Parent
		RankCategoryFrame.Lower.LockedFrame.Visible = not IsRankReached(RankName) and true or false
	end
	return RankCategoryFrame
end

local function Setup()
	local CurrentInstitution = GetCurrentInstitution(Player)

	local Header = LeftFrame:WaitForChild("Header")
	local RankLabel = Header:WaitForChild("RankLabel")
	local TopLabel = Header:WaitForChild("TopLabel")
	local IconFrame = Header:WaitForChild("IconFrame")

	local CurrentInstitution = GetCurrentInstitution(Player)

	local CurrentRankIndex, CurrentRankName = GetCurrentRank(Player)
	RankLabel.Text = `Current Rank: {CurrentRankName or "N/A"}`
	TopLabel.Text = `{CurrentInstitution or "My"} Locker`
	IconFrame.IconImage.Image = RanksData[CurrentInstitution] and RanksData[CurrentInstitution].Icon or ""


	local CurrentTeam = Player.Team and Player.Team.Name
	if not CurrentTeam then return end

	local CurrentTeamLoadouts = GetTeamLoadoutData(Loadouts_Data, CurrentTeam)
	if not CurrentTeamLoadouts then return end

	--Setup Left Frame
	local LeftHolderScrollingFrame = LeftFrame.Container.ScrollingFrame
	local LeftRankCategoryTemplate = LeftHolderScrollingFrame.RankTemplate

	local RightHolderScrollingFrame = RightFrame.Container.ScrollingFrame
	local RightRankCategoryTemplate = RightHolderScrollingFrame.RankTemplate

	local CurrentInstitution = GetCurrentInstitution(Player)
	if not CurrentInstitution then return end

	for rankId, RankData in RanksData[CurrentInstitution].Ranks do
		local RankName = RankData.Name
		local RankLoadoutData = CurrentTeamLoadouts[RankName]
		if not RankLoadoutData then continue end

		for CategoryName:string, CategoryData in RankLoadoutData do
			if #CategoryData <= 0 then continue end

			local RankCategoryFrame = (CategoryName ~= "Weapons" and CategoryName ~= "Tools") and GetOrCreateRankTemplate(RankName, LeftRankCategoryTemplate) or GetOrCreateRankTemplate(RankName, RightRankCategoryTemplate)
			local ButtonTemplate = RankCategoryFrame.Lower.ItemsHolder.ItemTemplate
			for Index, ObjectData in CategoryData do
				local ObjectName = ObjectData.Name
				local ThumbnailImage = ObjectData.ThumbnailImage

				local NewButton = ButtonTemplate:Clone()
				NewButton.Visible = true
				NewButton.IconImage.Image = ThumbnailImage
				NewButton.ObjectName.Text = ObjectName
				NewButton.Name = ObjectName
				NewButton:SetAttribute("CategoryName", CategoryName)
				NewButton.Parent = ButtonTemplate.Parent

				NewButton.Trigger.MouseButton1Click:Connect(function()
					if not IsRankReached(RankName) then return end

					local PlayerData  = ReplicaController.GetReplica('PlayerData')
					local Data = PlayerData and PlayerData.Data
					local LoadoutsData = Data and Data.Loadouts
					local TeamData = GetTeamLoadoutData(LoadoutsData, CurrentTeam)
					local categoryData = TeamData and TeamData[CategoryName]
					local equipped = IsButtonEquipped(ObjectName, categoryData, CurrentTeam)
					local action = equipped and "Unequip" or "Equip"
					Remote:FireServer({
						Root = `{RankName}/{CategoryName}/{Index}/{ObjectName}`,
						Action = action,
					})
				end)
			end
		end
	end

	UpdateAllFrames()
end



local TeamLoadout = {}
TeamLoadout.__index = TeamLoadout

function TeamLoadout.new(controller)
	local self = setmetatable({}, TeamLoadout)
	self._name = "TeamLoadout"
	self._uiController = controller
	self._Trove = Trove.new()
	self._UI = frame

	self:_init()
	return self
end


function TeamLoadout:_setupConnections()
	self._Trove:Connect(CloseButton.MouseButton1Click, function()
		self._uiController:Close(self._name)
	end)


	local succ, Replica: ReplicaController.Replica = ReplicaController.GetReplicaAsync("PlayerData"):await()
	if not succ then return end
	UpdateConnection = Replica:OnChange(function(Listener, Path)
		if Path[1] ~= "Loadouts" then return end
		UpdateAllFrames()
	end)



	self._Trove:Connect(RemoveBundleButton.MouseButton1Click, function()
		Remote:FireServer(`RemoveBundle`)
	end)

	self._Trove:Connect(Remote.OnClientEvent, function(payload)
		if typeof(payload) ~= "table" then return end
	end)

	return true
end

function TeamLoadout:_init()
	self._UI.Visible = false

	local HolderScrollingFrame = LeftFrame.Container.ScrollingFrame
	local RankCategoryTemplate = HolderScrollingFrame.RankTemplate
	RankCategoryTemplate.Visible = false
	--
	--game:GetService("UserInputService").InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	--if input.KeyCode == Enum.KeyCode.Y then
	--print(self._uiController:GetClass("Ranks").Built)
	----TODO: Check all posibly owned items
	--self._uiController:Open(self._name)
	--end
	--end)	

	return true
end

function TeamLoadout:OnOpen()
	if self._Trove then self._Trove:Clean() end
	self:_setupConnections()

	Setup()
end

function TeamLoadout:OnClose()
	if self._Trove then self._Trove:Clean() end

	if UpdateConnection then
		UpdateConnection:Disconnect()
		UpdateConnection = nil
	end

	Clean()
end


return TeamLoadout
