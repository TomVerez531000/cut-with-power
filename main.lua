function get_movements()	
	local module = {}

	module.AimMode = "Mouse"
	module.HitboxEnabled  = false
	local uis = game:GetService("UserInputService")
	local movespeed = 30
	local player = game.Players.LocalPlayer
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp = char:WaitForChild("HumanoidRootPart")
	local linearvel
	local moveHeight

	local noclipping = {}
	local function noclip(state)
		if state then
			for _,v in pairs(player.Character:GetDescendants()) do
				if v:IsA("BasePart") then
					table.insert(noclipping, {
						part = v,
						cc = v.CanCollide,
						connec = game:GetService("RunService").Stepped:Connect(function()
							v.CanCollide = false
						end)
					})
					v.CanCollide = false
				end
			end
		else
			for _,item in pairs(noclipping) do
				if item.part and item.cc then
					item.part.CanCollide = true
				end
				item.connec:Disconnect()
			end
			noclipping = {}
		end
	end

	local function get_closest_enemy()
		local closest
		local closestdist = math.huge
		for _,v in pairs(workspace.Alive:GetChildren()) do
			if v == char then continue end
			if not (v:GetAttribute("NPC") or v:GetAttribute("hasPVP")) then continue end
			local dist = (v:GetPivot().Position-hrp.Position).Magnitude
			if dist < closestdist then
				closestdist = dist
				closest = v
			end
		end
		return closest
	end

	local moveconnec
	function module.Start()
		module.viewpart = Instance.new("Part",workspace)
		module.viewpart.CanCollide = false
		module.viewpart.Transparency = 1
		module.viewpart.Anchored = true
		workspace.CurrentCamera.CameraSubject = module.viewpart
		local flypos = CFrame.new(char:GetPivot().Position)
		if not char then
			char = player.Character or player.CharacterAdded:Wait()
			hrp = char:WaitForChild("HumanoidRootPart")
		end
		moveHeight = hrp.Position.Y
		hrp.Anchored = false
		if linearvel then linearvel:Destroy() end
		linearvel = Instance.new("AlignPosition", hrp)
		linearvel.Mode = Enum.PositionAlignmentMode.OneAttachment
		linearvel.Attachment0 = hrp.RootAttachment
		linearvel.MaxForce = math.huge
		linearvel.Responsiveness = 100
		linearvel.Position = hrp.Position
		noclip(true)

		if moveconnec then
			moveconnec:Disconnect()
		end
		moveconnec = game:GetService("RunService").Stepped:Connect(function(t, dT)
			local movedir = Vector3.new(0,0,0)
			local camCF = workspace.CurrentCamera.CFrame

			local Z = uis:IsKeyDown(Enum.KeyCode.W)
			local Q = uis:IsKeyDown(Enum.KeyCode.A)
			local S = uis:IsKeyDown(Enum.KeyCode.S)
			local D = uis:IsKeyDown(Enum.KeyCode.D)
			local Space = uis:IsKeyDown(Enum.KeyCode.Space)
			local Alt = uis:IsKeyDown(Enum.KeyCode.LeftAlt)
			local Shift = uis:IsKeyDown(Enum.KeyCode.LeftShift)

			if Space then moveHeight += dT * 20 end
			if Alt then moveHeight -= dT * 20 end

			if Z then movedir += camCF.LookVector end
			if Q then movedir -= camCF.RightVector end
			if S then movedir -= camCF.LookVector end
			if D then movedir += camCF.RightVector end
			local dir = Vector3.new(0,0,0)
			if movedir.Magnitude > 0 then
				dir = Vector3.new(movedir.X, 0, movedir.Z).Unit*movespeed*dT*(Shift and 3 or 1)
			end

			local aimPos = hrp.Position
			if module.AimMode == "Mouse" then
				local mouse = player:GetMouse()
				mouse.TargetFilter = workspace:WaitForChild("dstobj")
				aimPos = mouse.Hit.Position or aimPos
			elseif module.AimMode == "Enemy" then
				local closest = get_closest_enemy()
				aimPos = closest and closest:GetPivot().Position or aimPos
			end
			local positionoffset = Vector3.new(0,0,0)
			if module.HitboxEnabled then
				local speed = 30
				local angle = (tick()*speed)%361
				local vector = Vector3.new(math.cos(angle), 0, math.sin(angle))
				
				positionoffset = vector * 10
			end

			flypos = CFrame.new(flypos.Position + dir)
			module.viewpart.CFrame = flypos
			local finalcf = CFrame.new((positionoffset+Vector3.new(flypos.X, moveHeight, flypos.Z)), aimPos)
			linearvel.Position = finalcf.Position
			char:PivotTo(finalcf)
		end)
	end

	function module.Stop()
		if moveconnec then
			moveconnec:Disconnect()
		end
		if module.viewpart then
			module.viewpart:Destroy()
			workspace.CurrentCamera.CameraSubject = char:WaitForChild("Humanoid")
		end
		if linearvel then linearvel:Destroy() end
		if not char then
			char = player.Character or player.CharacterAdded:Wait()
			hrp = char:WaitForChild("HumanoidRootPart")
		end
		hrp.Anchored = false
		noclip(false)
	end
	
	function module.toggleAimMode(mode)
		module.AimMode = mode
	end
	
	function module.toggleHitbox(state)
		module.HitboxEnabled = state
	end

	return module
end

local movements = get_movements()

local toggled = false
game:GetService("UserInputService").InputBegan:Connect(function(Key, gamep)
	if gamep then return end
	if Key.KeyCode == Enum.KeyCode.F then
		toggled = not toggled
		if toggled then
			movements.Start()
		else
			movements.Stop()
		end
	elseif Key.KeyCode == Enum.KeyCode.G then
		if movements.AimMode == "Mouse" then
			movements.toggleAimMode("Enemy")
		else
			movements.toggleAimMode("Mouse")
		end
	elseif Key.KeyCode == Enum.KeyCode.H then
		movements.toggleHitbox(not movements.HitboxEnabled)
	end
end)
