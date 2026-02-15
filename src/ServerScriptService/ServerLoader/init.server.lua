local LoaderModule = script.Init :: ModuleScript
if not LoaderModule then return end

local success, result = pcall(require, LoaderModule)

if success then
	result.Init()
else
	warn("Failed to require module:", result)
end