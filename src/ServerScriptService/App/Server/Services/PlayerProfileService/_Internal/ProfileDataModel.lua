--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local profilesData = sharedData:WaitForChild("Profiles")

local PlayerProfileSchema = require(profilesData:WaitForChild("PlayerProfileSchema"))
local ProfileSchemaUtil = require(profilesData:WaitForChild("ProfileSchemaUtil"))

local fields = PlayerProfileSchema.Fields
local storeNames = PlayerProfileSchema.StoreNames or {}

local resolvedStoreName = if RunService:IsStudio() then (storeNames.Dev or "Dev") else (storeNames.Live or "Live")

local ProfileDataModel = {
	StoreName = resolvedStoreName,
	UseMock = PlayerProfileSchema.UseMock == true,
	ReplicaToken = PlayerProfileSchema.ReplicaToken,
}

function ProfileDataModel.BuildTemplate()
	return ProfileSchemaUtil.BuildTemplate(fields)
end

function ProfileDataModel.SanitizeData(data: { [string]: any })
	ProfileSchemaUtil.SanitizeData(fields, data)
end

function ProfileDataModel.BuildReplicaData(data: { [string]: any }): { [string]: any }
	return ProfileSchemaUtil.BuildReplicatedData(fields, data)
end

function ProfileDataModel.GetRule(fieldName: string)
	return fields[fieldName]
end

function ProfileDataModel.IsReplicatedField(fieldName: string): boolean
	local fieldDefinition = fields[fieldName]
	if fieldDefinition == nil then
		return false
	end

	return ProfileSchemaUtil.IsReplicatedField(fieldDefinition)
end

function ProfileDataModel.NormalizeValue(fieldName: string, value: any): (boolean, any)
	local fieldDefinition = fields[fieldName]
	if fieldDefinition == nil then
		return false, nil
	end

	return ProfileSchemaUtil.NormalizeValue(fieldDefinition, value)
end

function ProfileDataModel.CloneValue(value: any): any
	return ProfileSchemaUtil.CloneValue(value)
end

function ProfileDataModel.IsNumericField(fieldName: string): boolean
	local fieldDefinition = fields[fieldName]
	if fieldDefinition == nil then
		return false
	end

	return ProfileSchemaUtil.IsNumericRule(fieldDefinition)
end

return table.freeze(ProfileDataModel)
