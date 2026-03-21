--!strict

local Grant = {}

function Grant.Apply(_player: Player, ContainerModel: Model, _isRobux: boolean): boolean
	if ContainerModel.Parent == nil then
		return false
	end
	
	print(`ContainerService.Grant:{_player.Name}:{ContainerModel:GetFullName()}:{_isRobux}`)
	
	return true
end

return table.freeze(Grant)