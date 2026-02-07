-- This is a script you would create in ServerScriptService, for example.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cmdr = require(script.Cmdr)

Cmdr:RegisterDefaultCommands() -- This loads the default set of commands that Cmdr comes with. (Optional)
Cmdr:RegisterCommandsIn(script.CmdrCommands) -- Register commands from your own folder. (Optional)
Cmdr:RegisterHooksIn(script.Hooks)