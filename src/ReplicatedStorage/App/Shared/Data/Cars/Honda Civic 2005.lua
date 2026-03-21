local Vehicle = {
	["Honda Civic 2005"] = {
		-- Stock/base stats for this car.
		-- Numeric values inside CompatibleParts[*].StatDeltas are additive.
		-- Example: base TopSpeed = 190 and a part delta TopSpeed = 50 means final TopSpeed = 240.
		-- If multiple equipped parts change Suspension.Softness, every delta is added to the final value.
		Stats = {
			ZeroToHundred = 9.5, -- seconds
			EngineType = "V4",
			TopSpeed = 190, -- km/h

			Power = {
				RPM = {
					Idle = 800,
					Max = 6500,
					Peak = 4800,
				},
				HP = {
					Min = 90,
					Max = 140,
				},
			},

			Traction = {
				Value = 0.60,
				Type = "FWD",
			},

			Suspension = {
				Rigidity = 0.40,
				Softness = 0.65,
			},

			Handling = 0.75,
		},

		-- The stock loadout for the car. The equipped player part should resolve against this whitelist.
		DefaultParts = {
			EngineBlock = 1,
			CylinderHead = 1,
			ExhaustManifold = 1,
			Transmission = 1,
			Battery = 1,
			Turbo = 1,
			SparkPlugs = 1,
			Radiator = 1,
		},

		-- CompatibleParts acts as the whitelist for this specific car.
		-- Every entry is a level-up for the same component on this car.
		-- Each option only stores the stat deltas it applies over the base Stats table above.
		CompatibleParts = {
			EngineBlock = {
				[1] = {
					Id = "engine_block_lv1",
					Level = 1,
					Name = "Engine Block Lv. 1",
					Notes = "Base engine block for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "engine_block_lv2",
					Level = 2,
					Name = "Engine Block Lv. 2",
					Notes = "Level 2 engine block upgrade for stronger street builds.",
					StatDeltas = {
						Power = {
							HP = {
								Min = 4,
								Max = 10,
							},
							RPM = {
								Max = 200,
							},
						},
						ZeroToHundred = -0.20,
					},
				},
				[3] = {
					Id = "engine_block_lv3",
					Level = 3,
					Name = "Engine Block Lv. 3",
					Notes = "Level 3 engine block upgrade for high-stress builds.",
					StatDeltas = {
						Power = {
							HP = {
								Min = 8,
								Max = 22,
							},
							RPM = {
								Max = 450,
							},
						},
						ZeroToHundred = -0.45,
					},
				},
			},

			CylinderHead = {
				[1] = {
					Id = "cylinder_head_lv1",
					Level = 1,
					Name = "Cylinder Head Lv. 1",
					Notes = "Base cylinder head for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "cylinder_head_lv2",
					Level = 2,
					Name = "Cylinder Head Lv. 2",
					Notes = "Level 2 cylinder head upgrade with improved airflow.",
					StatDeltas = {
						Power = {
							HP = {
								Max = 7,
							},
							RPM = {
								Peak = 200,
							},
						},
						TopSpeed = 2,
					},
				},
				[3] = {
					Id = "cylinder_head_lv3",
					Level = 3,
					Name = "Cylinder Head Lv. 3",
					Notes = "Level 3 cylinder head upgrade for tuned builds.",
					StatDeltas = {
						Power = {
							HP = {
								Max = 14,
							},
							RPM = {
								Peak = 350,
							},
						},
						TopSpeed = 4,
						ZeroToHundred = -0.15,
					},
				},
			},

			ExhaustManifold = {
				[1] = {
					Id = "exhaust_manifold_lv1",
					Level = 1,
					Name = "Exhaust Manifold Lv. 1",
					Notes = "Base exhaust manifold for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "exhaust_manifold_lv2",
					Level = 2,
					Name = "Exhaust Manifold Lv. 2",
					Notes = "Level 2 exhaust manifold upgrade with better flow.",
					StatDeltas = {
						Power = {
							HP = {
								Max = 5,
							},
						},
						TopSpeed = 3,
						ZeroToHundred = -0.10,
					},
				},
				[3] = {
					Id = "exhaust_manifold_lv3",
					Level = 3,
					Name = "Exhaust Manifold Lv. 3",
					Notes = "Level 3 exhaust manifold upgrade for high-flow setups.",
					StatDeltas = {
						Power = {
							HP = {
								Max = 10,
							},
						},
						TopSpeed = 5,
						ZeroToHundred = -0.20,
					},
				},
			},

			Transmission = {
				[1] = {
					Id = "transmission_lv1",
					Level = 1,
					Name = "Transmission Lv. 1",
					Notes = "Base transmission for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "transmission_lv2",
					Level = 2,
					Name = "Transmission Lv. 2",
					Notes = "Level 2 transmission upgrade with better gearing.",
					StatDeltas = {
						ZeroToHundred = -0.35,
						TopSpeed = 5,
						Handling = 0.02,
					},
				},
				[3] = {
					Id = "transmission_lv3",
					Level = 3,
					Name = "Transmission Lv. 3",
					Notes = "Level 3 transmission upgrade for aggressive setups.",
					StatDeltas = {
						ZeroToHundred = -0.60,
						TopSpeed = 8,
						Handling = 0.04,
					},
				},
			},

			Battery = {
				[1] = {
					Id = "battery_lv1",
					Level = 1,
					Name = "Battery Lv. 1",
					Notes = "Base battery for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "battery_lv2",
					Level = 2,
					Name = "Battery Lv. 2",
					Notes = "Level 2 battery upgrade for higher electrical demand.",
					StatDeltas = {
						Power = {
							RPM = {
								Idle = 50,
							},
						},
						Handling = 0.01,
					},
				},
				[3] = {
					Id = "battery_lv3",
					Level = 3,
					Name = "Battery Lv. 3",
					Notes = "Level 3 lightweight battery upgrade.",
					StatDeltas = {
						Handling = 0.03,
						TopSpeed = 1,
						ZeroToHundred = -0.05,
					},
				},
			},

			Turbo = {
				[1] = {
					Id = "turbo_lv1",
					Level = 1,
					Name = "Turbo Lv. 1",
					Notes = "No turbo installed. This is the stock naturally aspirated setup.",
					StatDeltas = {},
				},
				[2] = {
					Id = "turbo_lv2",
					Level = 2,
					Name = "Turbo Lv. 2",
					Notes = "Level 2 turbo upgrade for street performance.",
					StatDeltas = {
						Power = {
							HP = {
								Min = 12,
								Max = 35,
							},
							RPM = {
								Peak = 300,
							},
						},
						TopSpeed = 12,
						ZeroToHundred = -0.80,
						Traction = {
							Value = -0.02,
						},
					},
				},
				[3] = {
					Id = "turbo_lv3",
					Level = 3,
					Name = "Turbo Lv. 3",
					Notes = "Level 3 turbo upgrade for maximum forced induction.",
					StatDeltas = {
						Power = {
							HP = {
								Min = 20,
								Max = 55,
							},
							RPM = {
								Peak = 500,
							},
						},
						TopSpeed = 20,
						ZeroToHundred = -1.20,
						Traction = {
							Value = -0.04,
						},
						Handling = -0.02,
					},
				},
			},

			SparkPlugs = {
				[1] = {
					Id = "spark_plugs_lv1",
					Level = 1,
					Name = "Spark Plugs Lv. 1",
					Notes = "Base spark plugs for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "spark_plugs_lv2",
					Level = 2,
					Name = "Spark Plugs Lv. 2",
					Notes = "Level 2 spark plug upgrade for better ignition stability.",
					StatDeltas = {
						Power = {
							HP = {
								Max = 2,
							},
						},
						ZeroToHundred = -0.05,
					},
				},
				[3] = {
					Id = "spark_plugs_lv3",
					Level = 3,
					Name = "Spark Plugs Lv. 3",
					Notes = "Level 3 spark plug upgrade for tuned or boosted builds.",
					StatDeltas = {
						Power = {
							HP = {
								Max = 4,
							},
							RPM = {
								Peak = 50,
							},
						},
						ZeroToHundred = -0.08,
					},
				},
			},

			Radiator = {
				[1] = {
					Id = "radiator_lv1",
					Level = 1,
					Name = "Radiator Lv. 1",
					Notes = "Base radiator for the Honda Civic 2005.",
					StatDeltas = {},
				},
				[2] = {
					Id = "radiator_lv2",
					Level = 2,
					Name = "Radiator Lv. 2",
					Notes = "Level 2 radiator upgrade for better cooling.",
					StatDeltas = {
						Power = {
							RPM = {
								Max = 150,
								Peak = 100,
							},
						},
					},
				},
				[3] = {
					Id = "radiator_lv3",
					Level = 3,
					Name = "Radiator Lv. 3",
					Notes = "Level 3 radiator upgrade for demanding builds.",
					StatDeltas = {
						Power = {
							RPM = {
								Max = 300,
								Peak = 200,
							},
						},
						Handling = 0.01,
					},
				},
			},
		},
	},
}

return Vehicle
