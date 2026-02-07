local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Signal = require(ReplicatedStorage.Shared.Packages.Signal)

local Flag = {}
Flag.__index = Flag

function Flag.new(FlagModel: Model)
	local self = setmetatable({}, Flag)

	self.Contested = Signal.new()
	self.FlagEmpty = Signal.new()

	self.ActivePlayers = {}
	self.ActivePlayersSet = {}
	self.Owner = nil
	self.Capturing = false
	self.ContestedState = false

	self.Flag = FlagModel.Flag
	self.Area = FlagModel.Hitbox

	self.FlagOrigin = self.Flag.CFrame
	self.FlagEnd = self.Flag.CFrame * CFrame.new(0, -20, 0)

	self.endTween = TweenService:Create(
		self.Flag,
		TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
		{ CFrame = self.FlagEnd }
	)

	self.upTween = TweenService:Create(
		self.Flag,
		TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
		{ CFrame = self.FlagOrigin }
	)

	self.endTween.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed then return end
		if self.ContestedState then
			self.Capturing = false
			return
		end
		if self.Capturing and #self.ActivePlayers > 0 then
			self.upTween:Play()
		end
	end)

	self.upTween.Completed:Connect(function(playbackState)
		if playbackState ~= Enum.PlaybackState.Completed then return end
		if not self.ContestedState and #self.ActivePlayers > 0 then
			self.Owner = self.ActivePlayers[1]
			self.TimeSinceLastReward = 0
		else
			self.Owner = nil
		end
		self.Capturing = false
	end)

	self.RewardTime = 30
	self.TimeSinceLastReward = 0

	return self
end

function Flag:_TryStartCapture()
	if self.Capturing then return end
	if self.ContestedState then return end
	if #self.ActivePlayers ~= 1 then return end
	if self.endTween.PlaybackState == Enum.PlaybackState.Playing then return end
	if self.upTween.PlaybackState == Enum.PlaybackState.Playing then return end

	self.Area.BillboardGui.Display.Text = "Claiming..."
	self.Owner = nil
	self.TimeSinceLastReward = 0
	self.Capturing = true
	self.endTween:Play()
end

function Flag:AddPlayer(Player: Player)
	if Player.Parent ~= Players then return end
	if self.ActivePlayersSet[Player] then return end

	self.ActivePlayersSet[Player] = true
	table.insert(self.ActivePlayers, Player)

	if #self.ActivePlayers > 1 then
		self.ContestedState = true
		self.Contested:Fire()
		return
	end

	self.ContestedState = false

	self:_TryStartCapture()

	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if success then
		self.Flag.BackSurfaceGui.PlayerImage.Image = thumbnail
		self.Flag.FrontSurfaceGui.PlayerImage.Image = thumbnail
		self.Flag.BackSurfaceGui.Enabled = true
		self.Flag.FrontSurfaceGui.Enabled = true
	end
end

function Flag:RemovePlayer(Player: Player)
	if not self.ActivePlayersSet[Player] then return end

	self.ActivePlayersSet[Player] = nil

	local index = table.find(self.ActivePlayers, Player)
	if index then table.remove(self.ActivePlayers, index) end

	if #self.ActivePlayers <= 1 then
		self.ContestedState = false
		self:_TryStartCapture()
	end

	if #self.ActivePlayers == 0 and not self.Owner then
		self.Capturing = false
		self.ContestedState = false
		self.endTween:Cancel()
		self.upTween:Cancel()
		self.Flag.CFrame = self.FlagOrigin
		self.FlagEmpty:Fire()
	end
end

return Flag
