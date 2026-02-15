return {
	HumanoidRootPart = {BodyPart = "HumanoidRootPart",},

	LowerTorso = {
		BodyPart = "LowerTorso",
		Part0 = "UpperTorso",
		Motor = "Root"
	},

	LeftUpperLeg = {BodyPart = "LeftUpperLeg",
		Part0 = "LowerTorso",
		Motor = "LeftHip",
		CollisionFilter = {
			"LowerTorso",
			"RightUpperLeg",
			"UpperTorso"
		}	
	},
	LeftLowerLeg = {BodyPart = "LeftLowerLeg",
		Part0 = "LeftUpperLeg",
		Motor = "LeftKnee",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso"
		}		
	},
	LeftFoot = {BodyPart = "LeftFoot",
		Part0 = "LeftLowerLeg",
		Motor = "LeftAnkle",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso"
		}	
	},

	RightUpperLeg = {BodyPart = "RightUpperLeg",
		Part0 = "LowerTorso",
		Motor = "RightHip",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso",
			"LeftUpperLeg"
		}		
	},
	RightLowerLeg = {BodyPart = "RightLowerLeg",
		Part0 = "RightUpperLeg",
		Motor = "RightKnee",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso"
		}
	},

	RightFoot = {BodyPart = "RightFoot",
		Part0 = "RightLowerLeg",
		Motor = "RightAnkle",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso"
		}		
	},

	UpperTorso = {BodyPart = "UpperTorso",
		Part0 = "LowerTorso",
		Motor = "Waist"},

	LeftUpperArm = {BodyPart = "LeftUpperArm",
		Part0 = "UpperTorso",
		Motor = "LeftShoulder",
		CollisionFilter = {
			"UpperTorso",
			"LowerTorso",
			"LeftUpperLeg",
			"RightUpperLeg",
			"RightUpperArm",
		}
	},
	LeftLowerArm = {BodyPart = "LeftLowerArm",
		Part0 = "LeftUpperArm",
		Motor = "LeftElbow",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso"
		}		
	},
	LeftHand = {BodyPart = "LeftHand",
		Part0 = "LeftLowerArm",
		Motor ="LeftWrist",
		CollisionFilter = {
			"UpperTorso",
		}		
	},

	RightUpperArm = {BodyPart = "RightUpperArm",
		Part0 = "UpperTorso",
		Motor = "RightShoulder",
		CollisionFilter = {
			"UpperTorso",
			"LowerTorso",
			"LeftUpperLeg",
			"RightUpperLeg",
			"LeftUpperArm",
		}
	},
	RightLowerArm = {BodyPart = "RightLowerArm",
		Part0 = "RightUpperArm",
		Motor = "RightElbow",
		CollisionFilter = {
			"LowerTorso",
			"UpperTorso"
		}	
	},
	RightHand = {BodyPart = "RightHand",
		Part0 = "RightLowerArm",
		Motor = "RightWrist",
		CollisionFilter = {
			"UpperTorso",
		}	
	},

	Head = {BodyPart = "Head",
		Part0 = "UpperTorso",
		Motor = "Neck",

		CollisionFilter = {
			"UpperTorso",
			"LowerTorso",
			"LeftUpperArm",
			"RightUpperArm",
			"LeftUpperLeg",
			"RightUpperLeg",
			"HumanoidRootPart"
		}
	},
}