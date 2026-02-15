--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Data = ReplicatedStorage.Data
local RanksData = require(Data.Ranks)

local Util = ReplicatedStorage.Util
local Format = require(Util.Format)

local Assets = ReplicatedStorage.Assets.UI
local ItemTemplate = Assets.Rank

-- Util
local function BuildItemFrom(id: string, data: RanksData.InstitutionData, parent: GuiObject): Frame
	local new = ItemTemplate:Clone()
		new.Name = id
		new.LayoutOrder = data.DisplayOrder * 2
		
	local teamName = new:FindFirstChild('TeamName')
	if teamName then
		teamName.Text = data.DisplayName
	end
	
	local teamIcon = new:FindFirstChild('TeamIcon')
	if teamIcon then
		teamIcon.Image = data.Icon
	end
	
	new.Parent = parent :: any
	return new
end

local function GetIndexFrom(xp: number, list: {RanksData.RankData})
	for index, data in ipairs(list) do
		if xp > data.Requirement then continue end
		return math.max(index - 1, 1)
	end
	
	return 1
end

-- Class
local Item = {}
Item.__index = Item

type Manager = {OpenXPAt: (Manager, string) -> ()}
export type Class = typeof(setmetatable({} :: {
	Id: string,
	Data: RanksData.InstitutionData,
	
	XP: number,
	
	Manager: Manager,
	Object: Frame,
	
	CurrentLabel: TextLabel?,
	NextLabel: TextLabel?,
	
	ProgressBar: Frame?,
	ProgressLabel: TextLabel?,
}, Item))

function Item.new(id: string, parent: GuiObject, manager: any): Class
	local instData = RanksData[id]
	assert(instData, 'Invalid rank data')
	
	local frame = BuildItemFrom(id, instData, parent)

	local currLabel = frame:FindFirstChild('CurrentRank')
	local nextLabel = frame:FindFirstChild('FutureRank')
	
	local progressHolder = frame:FindFirstChild('Progress')
	local progressBar = progressHolder and progressHolder:FindFirstChild('Bar') or nil
	local progressLabel = progressHolder and progressHolder:FindFirstChild('Count') or nil
	
	local self = setmetatable({
		Id = id,
		Data = instData,
		
		XP = 0,
		
		Manager = manager,
		Object = frame,
		
		CurrentLabel = currLabel :: any,
		NextLabel = nextLabel :: any,
		
		ProgressBar = progressBar :: any,
		ProgressLabel = progressLabel :: any,
	}, Item)
	
	self:Init()
	return self
end

function Item.Init(self: Class)
	local xpButton = self.Object:FindFirstChild('BuyXP') :: GuiButton?
	if xpButton then
		xpButton.MouseButton1Up:Connect(function()
			self.Manager:OpenXPAt(self.Id)
		end)
	end
	
	self:Update(0, true)
end

function Item.Update(self: Class, newXP: number, forceRecalc: boolean?)
	if not forceRecalc and newXP == self.XP then return end
	self.XP = newXP
	
	local rankOrder = GetIndexFrom(newXP, self.Data.Ranks)
	local currData = self.Data.Ranks[rankOrder] :: RanksData.RankData?
	if not currData then return end
	
	local nextData = self.Data.Ranks[rankOrder + 1] :: RanksData.RankData?
	
	if self.CurrentLabel then
		self.CurrentLabel.Text = currData and currData.Name or ''
	end
	
	if self.NextLabel then
		self.NextLabel.Text = nextData and nextData.Name or 'MAXXED'
	end
	
	local progress = if (currData and nextData) then
		math.clamp(
			(newXP - currData.Requirement)
			/ (nextData.Requirement - currData.Requirement),
			0, 1
		)
		else 1
	
	if self.ProgressBar then
		self.ProgressBar.Size = UDim2.fromScale(progress, 1)
	end
	
	if self.ProgressLabel then
		local left = if nextData then
			nextData.Requirement - newXP
			else nil
		
		self.ProgressLabel.Text = if (currData and nextData) then
			`{
				Format.WithCommas(newXP)
			}/{
				Format.WithCommas(nextData.Requirement)
			} XP ({
				Format.WithCommas(left :: number)
			} XP LEFT)`
			else 'MAXXED'
	end
end

return Item
