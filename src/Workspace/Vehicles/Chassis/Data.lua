return {
	--// ENGINE
	PeakTorque = 470, -- n-m [Engine max torque]
	PeakTorqueRPM = 6_100, -- [Engine max torque RPM]

	IdleRPM = 900, -- [Engine idle RPM]
	IdleTorque = 50, -- n-m [Engine idle torque]
	IdleTorqueCurve = 0.3, -- 1/% [Engine idle torque curve curvature]

	RedlineRPM = 9_000, -- [Engine max RPM]
	RedlineTorque = 370, -- n-m [Engine redline torque]
	RedlineTorqueCurve = 0.8, -- 1/% [Engine redline torque curve curvature]

	FlywheelInertia = 4, -- kg-s^2 [Flywheel energy storage]

	--// GEARBOX
	TopSpeeds = { -- km/h [Top speed for each gear]
		[-1] = 60,
		[1] = 76,
		[2] = 120,
		[3] = 165,
		[4] = 210,
		[5] = 255,
		[6] = 295,
		[7] = 320,
	},

	ShiftTime = 0.03, -- s [Time to shift between each gear]

	--// DIFFERENTIAL
	DifferentialBias = 0, -- 0 = rear, 0.5 = front & rear, 1 = front [Differential torque distribution]
	DifferentialPreload = 350, --// 0 = open, +0 = limited slip, INF = locked [Differential torque lock]
	DifferentialMaxTorque = 900, -- n-m [Differential max torque transfer]

	--// BRAKING
	BrakeForce = 16_000, -- n-m [Brake force]
	BrakeBias = 0, --// 0 = rear, 0.5 = front & rear, 1 = front [Brake torque distribution]

	ParkingBrakeForce = 2_000, -- n-m [Parking brake force]

	--// SUSPENSION
	FrontStiffness = 255_000, -- kg/s2 [Front suspension rigidty]
	FrontDamping = 19_500, -- kg/s [Front suspension smoothing]
	FrontMinLength = 0.8, -- studs [Front suspension min compression length]
	FrontFreeLength = 2.4, -- studs [Front suspension free length]
	FrontMaxLength = 3.3, -- studs [Front suspension max extension length]

	RearStiffness = 330_000, -- kg/s2 [Rear suspension rigidty]
	RearDamping = 25_500, -- kg/s [Rear suspension smoothing]
	RearMinLength = 0.8, -- studs [Rear suspension min compression length]
	RearFreeLength = 2.4, -- studs [Rear suspension free length]
	RearMaxLength = 3.3, -- studs [Rear suspension max extension length]
	
	--// ANTIROLL
	FrontAntirollStiffness = 3_000, -- kg/s2 [Front antiroll bar rigidty]
	RearAntirollStiffness = 10_000, -- kg/s2 [Rear antiroll bar rigidty]

	--// STEERING
	SteerRatio = 12, -- [Steering rotation for the rack]
	SteerLock = 1.8, -- [Steering wheel periods until lock]
	SteerAckerman = 0.8, -- (0.7 - 1.2) [Steering ackerman coefficient]
	SteerSpeed = 0.08, -- deg/s [Steering wheel rotation speed]
	SteerReturnSpeed = 0.15, -- deg/s [Steering wheel return speed]
	SteerSpeedDecay = 320, -- km/h [Steering wheel cutoff speed]
	SteerMinSpeed = 50, -- % [Steering min during speed decay]
	SteerDecay = 320, -- km/h [Steering cutoff speed]
	SteerMinDecayAngle = 15, -- % [Steering max during speed decay]
	
	--// SYSTEMS
	ABSLimit = 0, -- [Braking unblock percent when ABS active]
	ABSThreshold = 4, -- km/h [ABS activation threshold]

	TCSLimit = 8, -- % [Torque correction percent]
	TCSGradient = 20, -- km/h [Desired speed during correction]
	TCSThreshold = 10, -- km/h [TCS activation threshold]

	--// BODY
	Weight = 1_435, -- kg [Weight for the vehicle body]
	Gravity = 192.6, -- studs/s2 [Gravity for the vehicle body]
}