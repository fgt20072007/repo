local RunService = game:GetService("RunService")

local Debug = {}

function Debug:Breakpoint(name: string, statement: string, studio: boolean)
	if not name then return false end
	
	if studio and not RunService:IsStudio() then return true end
	
	local str = ""
	if statement then
		str = ("[%s] %s"):format(name, statement)
	else
		str = ("[%s]"):format(name)
	end
	
	warn(str)
	
	return true
end


return Debug