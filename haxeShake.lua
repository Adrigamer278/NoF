-- this kinda has support for when people do shake("Camera",)

local currentObjShakeData = {}

local function shake(obj,duration,intensity)
	currentObjShakeData[obj] = {
		startDuration = duration,
		Duration = duration or 0,
		Intensity = intensity,
		Completed = false,
		axesShake = {X=true,Y=true}
	}
	local shake = 0 -- we dont want to kill 240fps players
	local originalPos = obj.Position
	while not currentObjShakeData[obj].Completed do
		if currentObjShakeData[obj].Duration>0 then
			local dt = game["Run Service"].Heartbeat:Wait()
			shake+=dt
			currentObjShakeData[obj].Duration-=dt
			if currentObjShakeData[obj].Duration<=0 then
				currentObjShakeData[obj].Completed = true
			else
				if shake > (1/60) then
					shake-=(1/60)
					-- proceed to shake
					local _fxShakeIntensity=currentObjShakeData[obj].Intensity
					local width,height = 
						obj ~= "Camera" and obj.AbsoluteSize.X or game.Workspace.CurrentCamera.ViewportSize.X
					,obj ~= "Camera" and obj.AbsoluteSize.X or game.Workspace.CurrentCamera.ViewportSize.Y
					local zoom = 1
					local newUdim=UDim2.fromOffset(
						currentObjShakeData[obj].axesShake.X and
							(math.random(-_fxShakeIntensity * width, _fxShakeIntensity * width) * zoom) or 0,
						currentObjShakeData[obj].axesShake.Y and
							(math.random(-_fxShakeIntensity * height, _fxShakeIntensity * height) * zoom) or 0
					)
					if obj ~= "Camera" then
						obj.Position = originalPos + newUdim
					else
						-- tweak this bc it can be real different
						camera.shake = Vector3.new((newUdim.X.Offset/width)*3,(newUdim.Y.Offset/height)*3)
					end
				end
			end
			
		else
			if not currentObjShakeData[obj].Completed then
				currentObjShakeData[obj].Completed = true
			end
		end
	end
	if obj ~= "Camera" then
		obj.Position = originalPos
	else
		camera.shake = Vector3.new()
	end
end
