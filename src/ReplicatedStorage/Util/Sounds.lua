local SoundService = game:GetService 'SoundService'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type Properties = {[string]: any}

-- Util
local function Query(path: string): Sound|Folder|nil
	local current = SoundService
	
	for seg in string.gmatch(path, "[^/]+") do
		if not current then return nil end
		
		current = current:FindFirstChild(seg)
	end
	
	return if current~=SoundService then current :: any else nil
end

-- Manager
local Manager = {}

function Manager.ToggleGroup(id: string, to: number)
	local group = SoundService:FindFirstChild(id)
	if not (group and group:IsA('SoundGroup')) then return end
	
	local default = group:GetAttribute('_DefaultVolume')
	if default == nil then
		default = group.Volume
		group:SetAttribute('_DefaultVolume', default)
	end
	
	group.Volume = if to then default else 0
end

function Manager.GetSound(path: string): Sound?
	local found = Query(path)
	if not found then return nil end
	
	if found:IsA('Folder') then
		local filtered: {Sound} = TableUtil.Filter(found:GetChildren(), function(des: Instance)
			return des:IsA('Sound')
		end) :: any
		
		return if #filtered>0 then filtered[math.random(1, #filtered)] else nil
	elseif found:IsA('Sound') then
		return found
	end
	
	return nil
end

function Manager.CloneCustom(sound: Sound, override: Properties): Sound
	local new = sound:Clone()
	
	for propId, propValue in override do
		local succ, res = pcall(function()
			new[propId] = propValue
		end)
		if not succ	then print(res) end
	end
	
	return new
end

function Manager._Run(sound: Sound, override: Properties, parent: Instance?, cleanParentOnCompletion: boolean?)
	if override and parent then
		override.Parent = parent
	end

	local overriden = Manager.CloneCustom(sound, override or {Parent = parent or SoundService})
	if parent then
		overriden:Play()
	else
		SoundService:PlayLocalSound(overriden)
	end

	if overriden.Looped then return end
	task.delay(overriden.TimeLength, function()
		overriden:Destroy()

		if cleanParentOnCompletion and parent then
			parent:Destroy()
		end
	end)
end

function Manager.Play(query: string, override: Properties?): boolean
	local sound = Manager.GetSound(query)
	if not sound then return false end

	if override then
		Manager._Run(sound, override)
	else
		SoundService:PlayLocalSound(sound)
	end
	
	return true
end

function Manager.PlayAt(query: string, at: Vector3, override: Properties?): boolean
	local sound = Manager.GetSound(query)
	if not sound then return false end
	
	local att = Instance.new('Attachment')
		att.Name = `_Sound_{query}`
		att.WorldCFrame = CFrame.new(at)
		att.Parent = workspace.Terrain
		
	Manager._Run(sound, override, att, true)
	return true
end

return Manager
