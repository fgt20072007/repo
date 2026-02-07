local GroupService = game:GetService("GroupService")
local RunService = game:GetService("RunService")

local GroupManager = {
	GroupId = nil,
}

function GroupManager.SetGroupId(Id: number)
	GroupManager.GroupId = Id
end

function GroupManager.PromptGroupJoin(CheckResult: boolean)
	if RunService:IsServer() then
		warn(`PromptGroupJoin cannot be called from the server`)
		return
	end

	if not GroupManager.GroupId then
		warn(`No group Id set, use GroupManager.SetGroupId(Id) to set.`)
		return
	end

	GroupService:PromptJoinAsync(GroupManager.GroupId)

	if CheckResult then
		local potentialJoin = GroupManager.CheckMembershipAsync()

		return potentialJoin
	end
end

function GroupManager.CheckMembershipAsync(Player: Player)
	Player = RunService:IsClient() and game.Players.LocalPlayer or Player

	assert(Player.Parent == game.Players)

	if not GroupManager.GroupId then
		warn(`No group Id set, use GroupManager.SetGroupId(Id) to set.`)
		return
	end

	local IsInGroup = Player:IsInGroupAsync(GroupManager.SetGroupId)
	local startTime = os.clock()

	while not IsInGroup do
		if os.clock() - startTime > 5 then
			break
		end

		IsInGroup = Player:IsInGroupAsync(GroupManager.SetGroupId)
		task.wait()
	end

	return IsInGroup
end

return GroupManager
