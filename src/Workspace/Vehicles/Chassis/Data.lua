return {
	--// ENGINE
	PeakTorque = 470, -- n-m
	PeakTorqueRPM = 6_100,

	IdleRPM = 900,
	IdleTorque = 50, -- n-m
	IdleTorqueCurve = 0.3, -- 1/%

	RedlineRPM = 9_000,
	RedlineTorque = 370, -- n-m
	RedlineTorqueCurve = 0.8, -- 1/%

	FlywheelInertia = 4, -- kg-s^2

	--// GEARBOX
	TopSpeeds = { -- km/h
		[-1] = 60,
		[1] = 76,
		[2] = 120,
		[3] = 165,
		[4] = 210,
		[5] = 255,
		[6] = 295,
		[7] = 320,
	},

	ShiftTime = 0.03,

	--// DIFFERENTIAL
	DifferentialBias = 0, -- torque distribution, 0 = rear, 0.5 = front & rear, 1 = front
	DifferentialPreload = 350, --// 0 = open, +0 = limited slip, INF = locked
	DifferentialMaxTorque = 900, -- n-m

	--// BRAKING
	BrakeForce = 16_000, -- n-m
	BrakeBias = 0, --// 0 = front, 0.5 = front & rear, 1 = rear

	ParkingBrakeForce = 2_000, -- n-m

	--// SUSPENSION
	FrontStiffness = 85_000, -- kg/s2
	FrontDamping = 6_500, -- kg/s
	FrontMinLength = 0.5, -- studs
	FrontFreeLength = 2.2, -- studs
	FrontMaxLength = 3.1, -- studs

	RearStiffness = 110_000, -- kg/s2
	RearDamping = 8_500, -- kg/s
	RearMinLength = 0.5, -- studs
	RearFreeLength = 2.2, -- studs
	RearMaxLength = 3.1, -- studs

	--// ANTIROLL
	FrontAntirollStiffness = 3_000, -- kg/s2
	RearAntirollStiffness = 10_000, -- kg/s2

	--// STEERING
	SteerRatio = 12,
	SteerLock = 1.8, -- steer wheel periods until lock
	SteerAckerman = 0.8, -- ackerman coefficient [0.7 - 1.2]
	SteerSpeed = 0.08, -- rad/s
	SteerReturnSpeed = 0.15, -- rad/s
	SteerSpeedDecay = 320, -- steer cutoff km/h
	SteerMinSpeed = 50, -- %
	SteerDecay = 320, -- cutoff km/h
	SteerMinDecayAngle = 15, -- %

	--// SYSTEMS
	ABSLimit = 0,
	ABSThreshold = 4, -- km/h

	TCSLimit = 8, -- %
	TCSGradient = 20, -- km/h
	TCSThreshold = 10, -- km/h

	--// BODY
	Weight = 1_435, -- kg
	Gravity = 196.2, -- studs/s2
}