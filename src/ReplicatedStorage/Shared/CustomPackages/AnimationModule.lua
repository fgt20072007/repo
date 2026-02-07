export type PlaySettings = {
	FadeTime: number,
	Weight: number,
	Speed: number,
}

local cache = {}

local AnimationModule = {}

function AnimationModule.SetCache(Character: Model)
	cache[Character] = {}

	return cache[Character]
end

function AnimationModule.LoadBulkAnimations(AnimationBulk: { Animation }, Character: Model)
	cache[Character] = cache[Character] or AnimationModule.SetCache(Character)

	local humanoidOrAnimationController = Character:FindFirstChildWhichIsA("Humanoid")
		or Character:FindFirstChildWhichIsA("AnimationController")

	if not humanoidOrAnimationController then
		warn(`Could not find animator source in {Character.Name}`)
		return
	end

	local animator = humanoidOrAnimationController:FindFirstChild("Animator") :: Animator

	if not animator or animator.ClassName ~= "Animator" then
		warn(`Failed to find animator in {Character}`)
		return
	end

	for _, animation in AnimationBulk do
		local track = animator:LoadAnimation(animation)

		cache[Character][animation.Name] = track
	end
end

function AnimationModule.PlayAnimation(Animation: string, Character, Settings: PlaySettings)
	local track = cache[Character] and cache[Character][Animation]

	if not track then
		return
	end

	if not Settings.FadeTime then
		Settings.FadeTime = 0.1
	end
	if not Settings.Speed then
		Settings.Speed = 1
	end
	if not Settings.Weight then
		Settings.Weight = 1
	end

	track:Play(Settings.FadeTime, Settings.Weight, Settings.Speed)
end

function AnimationModule.GetCharacterAnimations(Character: Model)
	return cache[Character]
end

return AnimationModule
