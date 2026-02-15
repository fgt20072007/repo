for i = 1, math.random(14,20) do
	local cl = game.ReplicatedStorage.ACS_MICTLAN.Assets.Explosion.Fire:Clone()
	cl.Position = script.Parent.Position
	cl.Velocity = Vector3.new(math.random(-90,90),math.random(-90,90),math.random(-90,90))
	--cl.CanCollide = false
	cl.Parent = workspace
	delay(math.random(14,35)/10,function()
		cl.Attachment.Fire.Enabled = false
		wait(math.random(14,35)/10)
		cl.Attachment.Smoke.Enabled = false
		cl.Anchored = true
		cl.CanCollide = false
		game:GetService("Debris"):AddItem(cl,10)
	end)
end