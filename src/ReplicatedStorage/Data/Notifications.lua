--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local TableUtil = require(Packages:WaitForChild('TableUtil'))

export type Type = 'Warning'|'Error'|'Info'|'Success'
export type Item = {
	Type: Type,
	Messages: {string}
}

return TableUtil.Lock({
	Placement = {
		ExceedingAngle = {
			Type = 'Warning',
			Messages = {'The placement angle is too steep. Adjust the object to a more suitable rotation.'}
		},
		TooFar = {
			Type = 'Warning',
			Messages = {'You are too far away to place this object. Move closer and try again.'},
		},
		Maxxed = {
			Type = 'Warning',
			Messages = {`Max objects of this class placed. Remove one to continue.`},
		},
		Obstructed = {
			Type = 'Error',
			Messages = {'Placement failed. The position is obstructed or restricted.'},
		},
		Floating = {
			Type = 'Error',
			Messages = {'Object must rest on a solid surface.'},
		},
		NotOwned = {
			Type = 'Error',
			Messages = {'You do not own this object and cannot remove it.'},
		}
	},
	ItemPurchase = {
		FedBlocked = {
			Type = 'Error',
			Messages = {`You're not able to purchase this as a Federal employee.`},
		},
		Success = {
			Type = 'Success',
			Messages = {'Successfully purchased this item!'}
		},
		MaxxedClass = {
			Type = 'Warning',
			Messages = {`You're not able to carry more items of this class.`}
		},
		MaxxedItem = {
			Type = 'Warning',
			Messages = {`You're not able to carry more stock of this item.`}
		},
		CantAfford =  {
			Type = 'Error',
			Messages = {`You can't afford to pay this item.`},
		},
		Unexpected =  {
			Type = 'Error',
			Messages = {
				`Something went wrong while completing your purchase! Please try again.`,
				`Unexpected error! Purchase failed. Try again.`
			},
		},

		PassRequired = {
			Type = 'Warning',
			Messages = {
				`This item requires a gamepass to be purchased.`,
			},
		},
	},

	Arrest = {
		Success = {
			Type = "Success",
			Messages = {
				`Player was sent to prison`,
				`Player arrest successful`
			},
		},

		Fail = {
			Type = "Warning",
			Messages = {
				`This player is neither wanted or hostile`,
			},
		},

		CantArrestHere = {
			Type = "Warning",
			Messages = {
				`You can't arrest players in this zone`,
			},
		}
	},

	Stamp = {
		StateBlocked = {
			Type = 'Warning',
			Messages = {
				"You can't stamp this player because they are {state}.",
				"Stamp blocked: target status is {state}.",
			},
		},
	},

	GiftPass = {
		PlayerNotFound = {
			Type = "Warning",
			Messages = {
				`Target player not found`
			},
		},

		AlreadyOwned = {
			Type = "Error",
			Messages = {
				`Target already owns this pass`
			},
		},

		PassGiftSuccess = {
			Type = "Success",
			Messages = {
				`Pass gifted success`
			},
		},

		PassGiftReceived = {
			Type = "Info",
			Messages = {
				`You've received a gifted pass!`
			},
		},
	},

	Vehicle = {
		DoorLocked = {
			Type = 'Error',
			Messages = {`Vehicle is currently locked.`}
		},
		IsNotOwner = {
			Type = 'Error',
			Messages = {`You are not the owner of this vehicle.`}
		},
	},

	VehicleShop = {
		NotEnoughCash = {
			Type = 'Warning',
			Messages = {`You don't have enough cash to purchase this vehicle.`}
		},

		RateLimited = {
			Type = 'Error',
			Messages = {`Wait a bit before trying again...`}
		},

		VehicleSpawned = {
			Type = 'Success',
			Messages = {`Vehicle spawned successfully.`}
		},

		VehiclePurchased = {
			Type = 'Success',
			Messages = {`Vehicle bought successfully.`}
		},
		CarModelNotFound = {
			Type = 'Error',
			Messages = {`Car Vehicle Model not found.`}
		}
	},

	GamepassShop = {
		GamepassPurchased = {
			Type = 'Success',
			Messages = {`Gamepass purchased successfully!`}
		},

		GamepassRemoved= {
			Type = 'Warning',
			Messages = {`Gamepass has been removed!`}
		},
	},

	Jobs = {
		Completed = {
			Type = 'Success',
			Messages = {`You've received a reward for completing this task.`},	
		},
		FedBlocked = {
			Type = 'Error',
			Messages = {`You're a Federal employee, there's no need to do this job.`},
		},
	},

	FedTools = {
		Purchased = {
			Type = 'Success',
			Messages = {`Successfully equipped!`},	
		},
		CivilianBlocked = {
			Type = 'Error',
			Messages = {`You're not a Federal employee! You're not able to equip this.`},
		},
		Unexpected =  {
			Type = 'Error',
			Messages = {`Something went wrong while equipping this item! Please try again.`},
		},
		AlreadyEquipped =  {
			Type = 'Error',
			Messages = {`You already have this item equipped!`},
		},
	},

	Gate = {
		NoC4Found = {
			Type = 'Warning',
			Messages = {`You must have a C4 equipped to destroy this gate.`}
		},
	},

	Smuggling = {
		NoSellable = {
			Type = 'Warning',
			Messages = {`You don’t have anything in your inventory that can be sold.`},
		},
		FedBlocked = {
			Type = 'Error',
			Messages = {'Uh-oh… smells like a fed. You can’t sell goods while wearing a badge.'},
		},
		SoldNoPrev = {
			Type = 'Success',
			Messages = {`You received a briefcase full of dirty money. Don’t forget to take it to the washing machine.`},
		},
		SoldPrev = {
			Type = 'Success',
			Messages = {`More money has been added to your briefcase.`},
		}
	},

	Laundering = {
		NoBriefcase = {
			Type = 'Warning',
			Messages = {`Come back when you actually have money to wash.`},
		},
		FedBlocked = {
			Type = 'Error',
			Messages = {'Nice try, fed. Internal Affairs is watching.'},
		},
		Sold = {
			Type = 'Success',
			Messages = {`Transaction complete. Money laundered successfully.`},
		},
	},

	Rewards = {
		Onboarding = {
			Type = 'Success',
			Messages = {'Thanks for completing the tutorial! You just received a cash reward'},
		}
	},

	Settings = {
		Failed = {
			Type = 'Error',
			Messages = {'Unexpected error! Failed to update setting. Try again.'},
		},
		Success = {
			Type = 'Success',
			Messages = {`Setting updated successfully.`},
		},
	},

	RestrictedZone = {
		Warning = {
			Type = 'Warning',
			Messages = {'You are invading Mexico! Leave in {time}s or you will be eliminated.'},
		},
	},

	Parking = {
		Warning = {
			Type = 'Warning',
			Messages = {'Illegal parking detected. Move your vehicle in {time}s or it will be removed.'},
		},
		Countdown = {
			Type = 'Warning',
			Messages = {'Move your vehicle now. It will be removed in {time}s.'},
		},
		Removed = {
			Type = 'Error',
			Messages = {'Your vehicle was removed for illegal parking.'},
		},
	}
} :: {[string]: {[string]: Item}})