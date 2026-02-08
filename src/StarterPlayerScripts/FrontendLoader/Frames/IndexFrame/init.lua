-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Frames = Gui.Frames
local IndexFrame = Frames.IndexFrame

local ChoichesButtons = IndexFrame.Container.ChoicesButtons
local ChoichesTemplate = ChoichesButtons.MutationButtonTemplate

local ScrollingFrameTemplate = IndexFrame.Container.ScrollingFrame
local EntityTemplate = script.TemplateButton

local Banner = IndexFrame.Banner

local bottom = IndexFrame.Container.Bottom

local Mutations = require(ReplicatedStorage.DataModules.Mutations)
local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local Entities = require(ReplicatedStorage.DataModules.EntityCatalog)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local CameraUtils = require(script.CameraUtils)

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)

local Frame = {}
local ScrollingFrameCache = {}
local CurrentMutation = "Normal"

local ViewportCaches = {}

local function isValidAnimationId(animationId)
	return typeof(animationId) == "string" and string.match(animationId, "^rbxassetid://%d+$") ~= nil
end

local function HandlerViewport(Model, ViewportFrame, Animation)
	ViewportFrame:ClearAllChildren()
	if not Model or not Model:IsA("Model") then
		return ViewportFrame
	end

	local WolrdModel = Instance.new("WorldModel")
	WolrdModel.Parent = ViewportFrame

	local ModelClone = Model:Clone()
	ModelClone:PivotTo(CFrame.new(0,0,0))
	ModelClone.Parent = WolrdModel

	local Camera = Instance.new("Camera")
	Camera:PivotTo(CFrame.lookAt(CameraUtils:GetCameraPositionForModel(ModelClone, 70), Vector3.zero))
	Camera.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = Camera

	if isValidAnimationId(Animation) then
		local animationInstance = Instance.new("Animation")
		animationInstance.AnimationId = Animation
		local Humanoid = ModelClone:FindFirstChildWhichIsA("Humanoid") or ModelClone:FindFirstChildWhichIsA("AnimationController")
		if Humanoid then
			local Animator = Humanoid:FindFirstChildWhichIsA("Animator")
			if Animator then
				local AnimationTrack = Animator:LoadAnimation(animationInstance)
				AnimationTrack:Play()
			end
		end
	end

	return ViewportFrame
end

local ArrowsCache = {}

function Frame.FillScrollingFrame(scrollingFrame, Mutation)
	local indexInformations = DataService.client:get({"index", Mutation})

	DataService.client:getArrayInsertedSignal({"index", Mutation}):Connect(function(index, value)
		local func = ViewportCaches[Mutation][value]
		if func then func() end
		Frame.UpdateBar()
		Frame.UpdateTop()
	end)

	ViewportCaches[Mutation] = {}

	for entityName, entityInfo in Entities do
		if typeof(entityInfo) ~= "table" then
			continue
		end

		local rarityName = entityInfo.Rarity
		local rarityInfo = if typeof(rarityName) == "string" then Rarities[rarityName] else nil
		if not rarityInfo then
			continue
		end

		local new = EntityTemplate:Clone()

		new.Name = entityName
		new.LayoutOrder = rarityInfo.Weight
		new.RarityLabel.Text = rarityName
		local RarityGradient = rarityInfo.Gradient:Clone()
		RarityGradient.Parent = new.RarityLabel
		new.NameLabel.Text = entityInfo.DisplayName
		new.Visible = true

		local owns = false
		if indexInformations and table.find(indexInformations, entityName) then
			owns = true
		end

		local variantModel = select(1, SharedFunctions.GetEntityVariantModel(entityName, Mutation))
		local Viewport = HandlerViewport(variantModel, new.ViewportFrame, entityInfo.Animation)

		if owns then
			Viewport.ImageColor3 = Color3.fromRGB(255, 255, 255)
		else
			Viewport.ImageColor3 = Color3.fromRGB(0, 0, 0)
			ViewportCaches[Mutation][entityName] = function()
				Viewport.ImageColor3 = Color3.fromRGB(255, 255, 255)
			end
		end

		new.Parent = scrollingFrame

		task.wait()
	end
end

function Frame.GetUnlockedAmount()
	local indexInformations = DataService.client:get({"index", CurrentMutation})
	local amount = 0
	if indexInformations then
		amount = #indexInformations
	end
	return amount
end

function Frame.UpdateTop()
	local lenghtOfEntities = SharedUtilities.getLenghtOfT(Entities)

	local amount = Frame.GetUnlockedAmount() 
	Banner.PercentageLabel.Text = math.floor((amount / lenghtOfEntities)) * 100 .. "%"
	Banner.DiscovredAmount.Text = amount .. "/" .. lenghtOfEntities .. " Discovered"
end

function Frame.UpdateBar()

	local amount = Frame.GetUnlockedAmount() 
	local amountNeeded = GlobalConfiguration.EntitiesForMulti
	local clamped = math.clamp(amount / amountNeeded, 0, 1)
	bottom.Bar.Inner.Size = UDim2.fromScale(clamped, 1)

	bottom.Bar.TextLabel.Text = amount .. "/" .. amountNeeded

	bottom.TextLabel.Text = "Collect " .. amountNeeded .. " " .. CurrentMutation .. " Entities to unlock Multipliers!"
end

-- Initialization function for the script
function Frame:Initialize()

	task.spawn(function()
		Frame.UpdateTop()
		Frame.UpdateBar()
		for mutationName, info in Mutations do
			local NewScrollingFrame = ScrollingFrameTemplate:Clone()
			NewScrollingFrame.Name = mutationName .. "ScrollingFrame"

			ScrollingFrameCache[mutationName] = NewScrollingFrame
			NewScrollingFrame.Parent = IndexFrame.Container

			Frame.FillScrollingFrame(NewScrollingFrame, mutationName)

			NewScrollingFrame.Visible = mutationName == CurrentMutation

			local new = ChoichesTemplate:Clone()
			for _, v in new:GetDescendants() do
				if v:IsA("UIGradient") then
					local newGradient = info.Gradient:Clone()
					newGradient.Parent = v.Parent
					v:Destroy()
				end
			end

			new.Parent = ChoichesButtons

			ArrowsCache[mutationName] = new.Arrow
			if mutationName == CurrentMutation then
				new.Arrow.Visible = true
			end

			new.TextLabel.Text = mutationName
			new.LayoutOrder = info.Multiplier
			new.Activated:Connect(function()
				CurrentMutation = mutationName
				for i, v in ScrollingFrameCache do
					v.Visible = i == mutationName
				end

				for _, v in ArrowsCache do
					v.Visible = false
				end
				new.Arrow.Visible = true

				Frame.UpdateBar()
				Frame.UpdateTop()
			end)
			new.Visible = true

			task.wait(0.1)
		end
	end)
end

return Frame