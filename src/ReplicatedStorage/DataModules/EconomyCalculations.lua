local ReplicatedStorage = game:GetService('ReplicatedStorage')

local EconomyCalculations = {}

local EARNINGS_GROWTH_RATE = 1.15
local PRICE_GROWTH_RATE = 1.25
local BASE_PRICE_MULTIPLIER = 2
local EXPONENTIAL_PRICE_GROWTH = 1.3
local EXPONENTIAL_BASE_PRICE = 40
local GRAB_PRICE_GROWTH = 10
local GRAB_BASE_PRICE = 50000
local SLOW_PRICE_GROWTH = 3.162
local SLOW_BASE_PRICE = 0.1

function EconomyCalculations.calculateEarnings(baseEarnings, level)
	return baseEarnings * (EARNINGS_GROWTH_RATE ^ level)
end

function EconomyCalculations.calculateUpgradePrice(baseEarnings, level)
	return math.floor(baseEarnings * BASE_PRICE_MULTIPLIER * (PRICE_GROWTH_RATE ^ level))
end

function EconomyCalculations.calculateExponentialPrice(level)
	return math.floor(EXPONENTIAL_BASE_PRICE * (EXPONENTIAL_PRICE_GROWTH ^ (level - 12)))
end

function EconomyCalculations.calculateGrabUpgradePrice(level)
	return math.floor(GRAB_BASE_PRICE * (GRAB_PRICE_GROWTH ^ (level - 1)))
end

function EconomyCalculations.calculateSlowUpgradePrice(level)
	return math.floor(SLOW_BASE_PRICE * (SLOW_PRICE_GROWTH ^ level))
end

return EconomyCalculations