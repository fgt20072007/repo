local Vehicle = {
	["Honda Civic 2005"] = {
		Stats = {
			ZeroToHundred = 9.5, -- seconds
			Engine = "V4",
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

		CompatibleParts = {
			EngineBlock = {
				[1] = {
					Name = "Stock V4 Block",
					Notes = "Factory engine block based on the provided Civic 2005 data.",
				},
				[2] = {
					Name = "Street Reinforced V4 Block",
					Notes = "Stronger block for mild performance builds.",
				},
				[3] = {
					Name = "Forged V4 Block",
					Notes = "Built block for higher stress and advanced setups.",
				},
			},

			CylinderHead = {
				[1] = {
					Name = "Stock V4 Cylinder Head",
					Notes = "Factory-style cylinder head matching the base engine.",
				},
				[2] = {
					Name = "Ported Street Cylinder Head",
					Notes = "Improved airflow for better street performance.",
				},
				[3] = {
					Name = "Performance Cylinder Head",
					Notes = "Higher airflow head for tuned builds.",
				},
			},

			ExhaustManifold = {
				[1] = {
					Name = "Stock Exhaust Manifold",
					Notes = "Standard factory exhaust manifold.",
				},
				[2] = {
					Name = "Street Header",
					Notes = "Improved exhaust flow for better response.",
				},
				[3] = {
					Name = "Performance Header",
					Notes = "High-flow setup for stronger upper-range performance.",
				},
			},

			Transmission = {
				[1] = {
					Name = "Stock FWD Transmission",
					Notes = "Base transmission paired with the stock Civic setup.",
				},
				[2] = {
					Name = "Street Transmission",
					Notes = "Improved shift feel and better gearing.",
				},
				[3] = {
					Name = "Performance Transmission",
					Notes = "More aggressive gearing for advanced builds.",
				},
			},

			Battery = {
				[1] = {
					Name = "Stock Battery",
					Notes = "Factory electrical setup.",
				},
				[2] = {
					Name = "High Output Battery",
					Notes = "More reliable under upgraded load.",
				},
				[3] = {
					Name = "Lightweight Performance Battery",
					Notes = "Reduced weight, performance-focused option.",
				},
			},

			Turbo = {
				[1] = {
					Name = "No Turbo",
					Notes = "This base Honda Civic 2005 setup is naturally aspirated and does not use a turbo.",
				},
				[2] = {
					Name = "Street Turbo Kit",
					Notes = "Aftermarket turbo option, not part of the stock setup.",
				},
				[3] = {
					Name = "Performance Turbo Kit",
					Notes = "High-power forced induction build, not stock.",
				},
			},

			SparkPlugs = {
				[1] = {
					Name = "Stock Spark Plugs",
					Notes = "Standard plugs for the stock engine setup.",
				},
				[2] = {
					Name = "Iridium Spark Plugs",
					Notes = "Better ignition stability and longevity.",
				},
				[3] = {
					Name = "Performance Spark Plugs",
					Notes = "Optimized for tuned or boosted builds.",
				},
			},

			Radiator = {
				[1] = {
					Name = "Stock Radiator",
					Notes = "Factory cooling system for the base engine.",
				},
				[2] = {
					Name = "Street Radiator",
					Notes = "Improved cooling for heavier street use.",
				},
				[3] = {
					Name = "Performance Radiator",
					Notes = "High-capacity cooling for demanding builds.",
				},
			},
		},
	},
}

return Vehicle