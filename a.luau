-- Port build.rbxl -> src (Rojo style)
-- Usage: lune run a.luau

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local INPUT_PATH = "build.rbxl"
local OUTPUT_DIR = "src"
local DEBUG = true

local Exporter = {}
Exporter.__index = Exporter

function Exporter.new(config)
	local self = setmetatable({}, Exporter)
	self.inputPath = config.inputPath
	self.outputDir = config.outputDir
	self.debug = config.debug
	return self
end

function Exporter:log(message)
	if not self.debug then return end
	print(message)
end

function Exporter:pathJoin(...)
	return table.concat({ ... }, "/")
end

function Exporter:ensureDir(path)
	local ok, isDir = pcall(fs.isDir, path)
	if ok and isDir then return end
	fs.writeDir(path)
end

function Exporter:sanitizeName(name)
	local sanitized = name:gsub("[<>:\"/\\|%?%*]", "_")
	if sanitized == "" then return "_" end
	return sanitized
end

function Exporter:uniqueName(base, used)
	if not used[base] then
		used[base] = 1
		return base
	end
	local i = used[base] + 1
	used[base] = i
	return base .. "_" .. tostring(i)
end

function Exporter:describeInstance(instance)
	local ok, fullName = pcall(function() return instance:GetFullName() end)
	if ok then return instance.ClassName .. " " .. fullName end
	return instance.ClassName .. " " .. instance.Name
end

function Exporter:writeFile(path, contents)
	self:log("[WRITE] " .. path)
	fs.writeFile(path, contents)
end

function Exporter:exportInstance(instance, parentPath, usedNames)
	local fileBase = self:uniqueName(self:sanitizeName(instance.Name), usedNames)
	local className = instance.ClassName
	local children = instance:GetChildren()
	local hasChildren = #children > 0
	local targetPath = self:pathJoin(parentPath, fileBase)

	self:log("[EXPORT] " .. self:describeInstance(instance) .. " -> " .. targetPath)

	if className == "Folder" then
		self:ensureDir(targetPath)
		local used = {}
		for _, child in children do
			self:exportInstance(child, targetPath, used)
		end
		return
	end

	if className == "Script" or className == "LocalScript" or className == "ModuleScript" then
		local ext = ".lua"
		if className == "Script" then ext = ".server.lua"
		elseif className == "LocalScript" then ext = ".client.lua" end

		if hasChildren then
			self:ensureDir(targetPath)
			self:writeFile(self:pathJoin(targetPath, "init" .. ext), instance.Source or "")
			local used = {}
			for _, child in children do
				self:exportInstance(child, targetPath, used)
			end
			return
		end

		self:writeFile(self:pathJoin(parentPath, fileBase .. ext), instance.Source or "")
		return
	end

	if hasChildren then
		self:ensureDir(targetPath)
		local used = {}
		for _, child in children do
			self:exportInstance(child, targetPath, used)
		end
		return
	end

	self:writeFile(self:pathJoin(parentPath, fileBase .. ".rbxmx"), roblox.serializeModel({ instance }, true))
end

function Exporter:exportService(service, serviceDir)
	self:ensureDir(serviceDir)
	self:log("[SERVICE] " .. service.Name .. " -> " .. serviceDir)
	local used = {}
	for _, child in service:GetChildren() do
		self:exportInstance(child, serviceDir, used)
	end
end

function Exporter:cleanOutput()
	local ok, isDir = pcall(fs.isDir, self.outputDir)
	if ok and isDir then
		self:log("[CLEAN] " .. self.outputDir)
		fs.removeDir(self.outputDir)
	end
	self:ensureDir(self.outputDir)
end

function Exporter:run()
	self:cleanOutput()
	local fileContents = fs.readFile(self.inputPath)
	local game = roblox.deserializePlace(fileContents)

	local services = { "Lighting", "ReplicatedFirst", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "Workspace" }

	for _, name in services do
		local success, service = pcall(function() return game:GetService(name) end)
		if success and service then
			self:exportService(service, self:pathJoin(self.outputDir, name))
		else
			self:log("[MISSING] " .. name)
		end
	end

	local success, starterPlayer = pcall(function() return game:GetService("StarterPlayer") end)
	if success and starterPlayer then
		local spScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
		if spScripts then self:exportService(spScripts, self:pathJoin(self.outputDir, "StarterPlayerScripts")) end

		local scScripts = starterPlayer:FindFirstChild("StarterCharacterScripts")
		if scScripts then self:exportService(scScripts, self:pathJoin(self.outputDir, "StarterCharacterScripts")) end
	end
end

local exporter = Exporter.new({
	inputPath = INPUT_PATH,
	outputDir = OUTPUT_DIR,
	debug = DEBUG,
})

exporter:run()
print("Port complete -> " .. OUTPUT_DIR)