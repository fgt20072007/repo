local Fx = script.Parent.Fx
local List = script.Parent.HUD.List
local Evt = script.Parent.Refresh

function Refresh(CombatLog)
	for _,v in pairs(List:GetChildren()) do
		if v:IsA("TextLabel") then
			v:Destroy()
		end
	end
	
	for _,v in pairs(CombatLog) do
		local Texto = Fx.LogText:clone()
		Texto.Parent = List
		Texto.Text = v
		Texto.Visible = true
	end
end

function Close()
	script.Parent:Destroy()
end

Evt.Event:Connect(Refresh)
script.Parent.HUD.Close.MouseButton1Click:Connect(Close)
