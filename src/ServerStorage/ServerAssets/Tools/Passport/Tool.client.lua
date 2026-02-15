local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages:WaitForChild("Net"))

local Player = Players.LocalPlayer

local SetPassportOwnerRF = Net:RemoteFunction("SetPassportOwner") 

local Tool = script.Parent

local Handle = Tool:WaitForChild("Handle")
local Highlight = Handle:WaitForChild("Highlight")



local OwnerSet = false

if not OwnerSet then
	local canSetOwner = SetPassportOwnerRF:InvokeServer()
	if not canSetOwner then
		return 
	end
	OwnerSet = true
end


