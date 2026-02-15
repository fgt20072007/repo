local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local Players = game:GetService 'Players'

local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui

local Assets = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('UI')
local Template = Assets:WaitForChild('PlayerBillboard')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Observers = require(Packages.Observers)
local Trove = require(Packages.Trove)
local Net = require(Packages.Net)

local PREFIX = `Overhead_`
local DES_WHITELIST = table.freeze {'Head', 'Humanoid'}

local REVISION_IMAGES = table.freeze {
	Secondary = 134271761107706,
	Approved = 135514205515614,
	Wanted = 99952157127227,
	Hostile = 9111498641,
}	

local Manager = {}

function Manager.HideFor(player: Player)
	local billboard = PlayerGui:FindFirstChild(PREFIX..player.Name)
	if not billboard then return end
	
	billboard.Enabled = false
end

function Manager.OnRevisionUpdate(player: Player)
	local billboard = PlayerGui:FindFirstChild(PREFIX..player.Name)
	if not billboard then return end

	local list = billboard:FindFirstChild('Icons') :: Frame?
	local revIcon = list and list:FindFirstChild('Revision') :: ImageLabel? or nil
	if not revIcon then return end

	local revision = player:GetAttribute('Revision')
	local image = revision and REVISION_IMAGES[revision] or nil

	revIcon.Visible = image~=nil
	revIcon.Image = image and `rbxassetid://{image}` or ''
end

function Manager.UpdateCanChat(player: Player)
	if player == Client then return end
	
	local billboard = PlayerGui:FindFirstChild(PREFIX..player.Name)
	if not billboard then return end
	
	local icons = billboard:FindFirstChild('Icons')
	local chatIcon = icons and icons:FindFirstChild('DisabledChat') :: ImageLabel or nil
	if not chatIcon then return end
	
	local res = Net:Invoke('CanChatWith', player.UserId)
	local mayChat = if res~= nil then res else true
	
	if not (billboard and billboard:IsDescendantOf(PlayerGui)) then return end
	chatIcon.Visible = not mayChat 
end

function Manager.OnTeamUpdate(player: Player)
	local billboard = PlayerGui:FindFirstChild(PREFIX..player.Name)
	if not billboard then return end

	local label = billboard:FindFirstChild('PlayerTeam') :: TextLabel?
	if not label then return end
	
	local team = player.Team
	label.Text = team and team.Name or 'Civilian'
end

function Manager.OnCharacterLoaded(player: Player, character: Model)
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return Manager.HideFor(player)  end
	
	hum.DisplayName = " "
	
	local head = character:FindFirstChild('Head') :: BasePart
	if not head then return Manager.HideFor(player) end
	
	local billboard = PlayerGui:FindFirstChild(PREFIX..player.Name) :: BillboardGui
	if not billboard then
		local new = Template:Clone()
			new.Name = PREFIX..player.Name
			new.Parent = PlayerGui
			new.Enabled = true
		
		local userLabel = new:FindFirstChild('PlayerName') :: TextLabel
			userLabel.Text = `{
				player.Name
			}{
				player.MembershipType ~= Enum.MembershipType.None
				and utf8.char(0xE001) or ''
			}{
				player.HasVerifiedBadge and utf8.char(0xE000) or ''
			}`
			
		billboard = new
	end
	
	billboard.Adornee = head
	billboard.Enabled = true
	
	task.spawn(Manager.OnTeamUpdate, player)
	task.spawn(Manager.OnRevisionUpdate, player)
	task.spawn(Manager.UpdateCanChat, player)
end

function Manager.Init()
	-- Observers
	Observers.observeCharacter(function(player: Player, character: Model)
		local trove = Trove.new()
		
		trove:Add(character.DescendantAdded:Connect(function(des)
			if not table.find(DES_WHITELIST, des.Name) then return end
			trove:Add(task.spawn(Manager.OnCharacterLoaded, player, character))
		end))
		
		trove:Add(character.DescendantRemoving:Connect(function(des)
			if not table.find(DES_WHITELIST, des.Name) then return end
			trove:Add(task.spawn(Manager.OnCharacterLoaded, player, character))
		end))
		
		trove:Add(task.spawn(Manager.OnCharacterLoaded, player, character))
		
		return function()
			if trove then
				trove:Destroy()
				trove = nil
			end
			
			Manager.HideFor(player)
		end
	end)
	
	Observers.observePlayer(function(player: Player)
		local trove = Trove.new()
		
		trove:Add(player:GetAttributeChangedSignal('Revision'):Connect(function()
			Manager.OnRevisionUpdate(player)
		end))

		trove:Add(player:GetPropertyChangedSignal('Team'):Connect(function()
			Manager.OnTeamUpdate(player)
		end))

		task.spawn(Manager.OnRevisionUpdate, player)
		task.spawn(Manager.OnTeamUpdate, player)
		task.spawn(Manager.UpdateCanChat, player)
		
		return function()
			if trove then
				trove:Destroy()
				trove = nil
			end

			local billboard = PlayerGui:FindFirstChild(PREFIX..player.Name)
			if billboard then
				billboard:Destroy()
			end
		end
	end)
end

return Manager
