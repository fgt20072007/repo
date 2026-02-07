-- To add vending machines tag them with VendingMachine

-- Make sure each coin has it's own tool assigned attached to the data
-- You can scatter the coins anywhere around the map, proximity prompts are generated at runtime
-- Amount of coin is not strictly 3 it can be any amount

--  [VendingMachineName] = ToolsContainer
return {
	DefaultVending = {
		ToolFolder = script.Default,
		EntityToGive = "Hydra Dragon"
	}
}
