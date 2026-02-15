wait(.5)
local frame=script.Parent
local user=game.Players.LocalPlayer
repeat wait() until user.Character local char=user.Character
local humanoid=char:WaitForChild("Humanoid")
local anim
function playanim(id)
	if char~=nil and humanoid~=nil then
		local id="rbxassetid://"..tostring(id)
		local oldanim=char:FindFirstChild("LocalAnimation")
		if anim~=nil then
			anim:Stop()
		end
		if oldanim~=nil then
			if oldanim.AnimationId==id then
				oldanim:Destroy()
				return
			end
			oldanim:Destroy()
		end
		local animation=Instance.new("Animation",char)
		animation.Name="LocalAnimation"
		animation.AnimationId=id
		anim=humanoid:LoadAnimation(animation)
		anim:Play()
	end
end
local b1=frame.Button1
b1.MouseButton1Down:connect(function() playanim(b1.AnimID.Value) end)
local b2=frame.Button2
b2.MouseButton1Down:connect(function() playanim(b2.AnimID.Value) end)
local b3=frame.Button3
b3.MouseButton1Down:connect(function() playanim(b3.AnimID.Value) end)
local b4=frame.Button4
b4.MouseButton1Down:connect(function() playanim(b4.AnimID.Value) end)
local b5=frame.Button5
b5.MouseButton1Down:connect(function() playanim(b5.AnimID.Value) end)
local b6=frame.Button6
b6.MouseButton1Down:connect(function() playanim(b6.AnimID.Value) end)
local b7=frame.Button7
b7.MouseButton1Down:connect(function() playanim(b7.AnimID.Value) end)
local b8=frame.Button8
b8.MouseButton1Down:connect(function() playanim(b8.AnimID.Value) end)
local b9=frame.Button9
b9.MouseButton1Down:connect(function() playanim(b9.AnimID.Value) end)




