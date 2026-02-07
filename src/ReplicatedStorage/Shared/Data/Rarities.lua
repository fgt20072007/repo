local Rarities = {
	Common = {
		Name = "Common",
		Color = Color3.fromRGB(180, 180, 180),
		MinChance = 0.4,
	},
	Uncommon = {
		Name = "Uncommon",
		Color = Color3.fromRGB(76, 209, 55),
		MinChance = 0.2,
	},
	Rare = {
		Name = "Rare",
		Color = Color3.fromRGB(72, 126, 255),
		MinChance = 0.1,
	},
	Epic = {
		Name = "Epic",
		Color = Color3.fromRGB(190, 75, 219),
		MinChance = 0.01,
	},
	Legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(255, 195, 0),
		MinChance = 0,
	},
}

Rarities.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

function Rarities.GetFromChance(chance: number): { Name: string, Color: Color3, MinChance: number }
	for i = 1, #Rarities.Order do
		local rarity = Rarities[Rarities.Order[i]]
		if chance >= rarity.MinChance then return rarity end
	end
	return Rarities.Legendary
end

return Rarities