--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

export type Cutscene = {
	Speed: number,
	Sequences: {string},
	NonStop: boolean?,
}

export type InterfaceGuide = {
	Action: {string}?,
	Track: {
		Input: {string},
		Property: string,
		Check: (any) -> (boolean)
	}
}

export type Step = {
	Label: string,
	
	Cutscene: Cutscene?,
	InterfaceGuide: InterfaceGuide?
}

local List: {[string]: {[number]: Step}} = {
	Civilian = {
		[1] = {
			Label = 'This is the start of your journey',
			
			Cutscene = {
				Speed = 55,
				Sequences = {'MexicoBorder', 'USBorder'},
			},
		},
		[2] = {
			Label = 'Here you can spawn a vehicle to move around the map',

			Cutscene = {
				Speed = 0,
				Sequences = {'CarSpawner'},
			},
		},
		[3] = {
			Label = 'At this location you can acquire contraband goods',
			
			Cutscene = {
				Speed = 0,
				Sequences = {'SmuggleShop'},
			},
		},
		[4] = {
			Label = 'On the other side of the border, you can trade the contraband you carry',
			
			Cutscene = {
				Speed = 20,
				Sequences = {'Smuggling'},
				NonStop = true,
			},
		},
		[5] = {
			Label = 'Here you can get a legal job and earn money safely',

			Cutscene = {
				Speed = 25,
				Sequences = {'Job'},
				NonStop = true,
			},
		},
		[6] = {
			Label = 'Your main goal is to cross the border',

			Cutscene = {
				Speed = 80,
				Sequences = {'Across'},
				NonStop = true,
			},
		},
		[8] = {
			Label = 'If you want to change teams and experience a different path, open this menu',
			
			InterfaceGuide = {
				Action = {'HUD', 'Buttons', 'Holder', 'ChooseTeam'},
				Track = {
					Input = {'Main', 'ChooseTeam'},
					Property = 'Visible',
					Check = function(visible: boolean?)
						return visible == true
					end,
				}
			}
		},
	},
	HSI = {
		[1] = {
			Label = 'Stop and search every civilian who attempts to cross the border',

			Cutscene = {
				Speed = 25,
				Sequences = {'Gates'},
				NonStop = true,
			},
		},
		[2] = {
			Label = 'If everything is in order, approve their status and let them pass',

			Cutscene = {
				Speed = 25,
				Sequences = {'Authorized'},
				NonStop = true,
			},
		},
		[3] = {
			Label = 'Send for secondary inspection if you suspect smuggling',

			Cutscene = {
				Speed = 35,
				Sequences = {'SecondaryInspection'},
			},
		},
		[4] = {
			Label = 'Protect the border at all costs',
			
			Cutscene = {
				Speed = 0,
				Sequences = {'ProtectBorder'},
			},
		}
	},
	['Border Patrol'] = {
		[1] = {
			Label = 'Constantly patrol the border area and check on any suspicious individuals',

			Cutscene = {
				Speed = 55,
				Sequences = {'Border'},
				NonStop = true,
			},
		},
		[2] = {
			Label = 'Intercept illegal crossings and report incidents',

			Cutscene = {
				Speed = 25,
				Sequences = {'ExplosiveGate'},
				NonStop = true,
			},
		},
		[3] = {
			Label = 'Support HSI Agents and protect the border at all costs',

			Cutscene = {
				Speed = 0,
				Sequences = {'ProtectBorder'},
			},
		},
	},
	['State Trooper'] = {
		[1] = {
			Label = 'Keep order on roads and in nearby areas',

			Cutscene = {
				Speed = 80,
				Sequences = {'Across'},
				NonStop = true,
			},
		},
		[2] = {
			Label = 'Pursue suspects who try to escape and prevent the sale of contraband',

			Cutscene = {
				Speed = 0,
				Sequences = {'PreventSelling'},
			},
		},
		[3] = {
			Label = 'Provide support in operations and risky situations',

			Cutscene = {
				Speed = 0,
				Sequences = {'ProtectBorder'},
			},
		},
	},
}

return TableUtil.Lock(List)