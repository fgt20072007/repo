local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

type AnimatedState = {
	angle: number,
	starterPivot: CFrame,
	rotating: boolean,
}

local trackedInstances: {[Instance]: AnimatedState} = {}

local function canAnimate(instance: Instance): boolean
	return instance:IsA("Model") or instance:IsA("BasePart")
end

local function addTrackedInstance(instance: Instance, rotating: boolean)
	if not canAnimate(instance) then
		return
	end

	trackedInstances[instance] = {
		angle = 0,
		starterPivot = instance:GetPivot(),
		rotating = rotating,
	}
end

local function removeTrackedInstance(instance: Instance)
	local isRotating = CollectionService:HasTag(instance, "Rotating")
	local isSine = CollectionService:HasTag(instance, "Sine")
	if isRotating then
		addTrackedInstance(instance, true)
	elseif isSine then
		addTrackedInstance(instance, false)
	else
		trackedInstances[instance] = nil
	end
end

for _, instance in CollectionService:GetTagged("Sine") do
	addTrackedInstance(instance, false)
end

for _, instance in CollectionService:GetTagged("Rotating") do
	addTrackedInstance(instance, true)
end

CollectionService:GetInstanceAddedSignal("Sine"):Connect(function(instance)
	addTrackedInstance(instance, false)
end)
CollectionService:GetInstanceRemovedSignal("Sine"):Connect(removeTrackedInstance)

CollectionService:GetInstanceAddedSignal("Rotating"):Connect(function(instance)
	addTrackedInstance(instance, true)
end)
CollectionService:GetInstanceRemovedSignal("Rotating"):Connect(removeTrackedInstance)

RunService.RenderStepped:Connect(function(deltaTime)
	for instance, state in trackedInstances do
		if instance.Parent == nil then
			trackedInstances[instance] = nil
			continue
		end

		state.angle += deltaTime
		local baseCFrame = state.starterPivot * CFrame.new(0, math.sin(state.angle), 0)
		if state.rotating then
			instance:PivotTo(baseCFrame * CFrame.Angles(0, math.rad(state.angle * 12), 0))
		else
			instance:PivotTo(baseCFrame * CFrame.Angles(0, math.rad(math.cos(state.angle) * 10), math.rad(math.sin(state.angle) * 15)))
		end
	end
end)