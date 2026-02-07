local PathfindingService = game:GetService("PathfindingService")

local DEFAULT_WAYPOINTS = 12

local DEFAULT_CONFIG = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 4,
	Costs = {},
}

local Path = {}

function Path.ConnectPoints(list: { Part | Vector3 }, Waypoints: number)
	local positions = {}

	for key, value in list do
		if typeof(value) == "Instance" and value:IsA("BasePart") then
			value = value.Position
		end

		local nextKey = key + 1
		if nextKey > #list then
			break
		end

		local points = Path.Connect2Points(value, list[nextKey], Waypoints)

		for _, point in points do
			table.insert(positions, point)
		end
	end

	return positions
end

function Path.Connect2Points(Point1: Part | Vector3, Point2: Part | Vector3, Waypoints: number?)
	Waypoints = Waypoints or DEFAULT_WAYPOINTS

	Point1 = typeof(Point1) == "Vector3" and Point1 or Point1.Position
	Point2 = typeof(Point2) == "Vector3" and Point2 or Point2.Position

	local Direction = (Point2 - Point1).Unit
	local Distance = (Point2 - Point1).Magnitude
	local waypointSegment = Distance / Waypoints

	local positions = table.create(Waypoints - 1)

	for i = 1, Waypoints - 1 do
		positions[i] = Point1 + Direction * waypointSegment * i
	end

	return positions
end

function Path.CreatePath(Configs: typeof(DEFAULT_CONFIG)): Path
	Configs = Configs or DEFAULT_CONFIG

	return PathfindingService:CreatePath(Configs)
end

function Path.GetDistanceBetweenPoints(Point1: Part | Vector3, Point2: Part | Vector3)
	Point1 = typeof(Point1) == "Vector3" and Point1 or Point1.Position
	Point2 = typeof(Point2) == "Vector3" and Point2 or Point2.Position

	return (Point1 - Point2).Magnitude
end

return Path
