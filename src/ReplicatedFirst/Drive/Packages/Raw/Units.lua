--// 1 weight = 1 kg

local Units = {}

Units.Torque_Nm = 12.75
Units.Rads_RPM = 30/math.pi
Units.Meters_Studs = 25/7
Units.Studs_Meters = 7/25
Units.V_MPH = 2.23693629/Units.Meters_Studs
Units.KMH_Studs = Units.Meters_Studs/3.6
Units.RPM_KMH = math.pi*60/1000

return Units