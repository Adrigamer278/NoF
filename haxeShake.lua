-- the license is the license is the license is the license is the license is the license is the license is the license is the license is the license 
-- some kind of port of flxObj.shake() ; for a camera you can just put "Camera" as the obj

local currentObjShakeData = {}
local function shake(obj,duration,intensity)
	if currentObjShakeData[obj] then
		currentObjShakeData[obj] = {
			startDuration = duration,
			Duration = duration or 0,
			i=currentObjShakeData[obj].i+1 or 0;
			Intensity = intensity,
			startPos=currentObjShakeData[obj].startPos or obj.Position,
			Completed = false,
			axesShake = {X=true,Y=true}
		}
	else
		currentObjShakeData[obj] = {
			startDuration = duration,
			Duration = duration or 0,
			i=0;
			startPos=obj.Position,
			Intensity = intensity,
			Completed = false,
			axesShake = {X=true,Y=true}
		}
	end
	
	local FRAME_RATE=60 -- THE FRAME RATE (used to not cause the really happy incident for high fps)
	
	local shake = 0 -- we dont want to kill 240fps players
	local originalPos = currentObjShakeData[obj].startPos
	local ind=currentObjShakeData[obj].i -- cancelation token (i think thats how its called)
	while not currentObjShakeData[obj].Completed and currentObjShakeData[obj].i == ind do
		if currentObjShakeData[obj].Duration>0 then
			local dt = game["Run Service"].Heartbeat:Wait()
			shake+=dt
			currentObjShakeData[obj].Duration-=dt
			if currentObjShakeData[obj].Duration<=0 or gameended then -- if duration <=0 or game stopped, then complete
				currentObjShakeData[obj].Completed = true
			else
				if shake > (1/FRAME_RATE) then
					shake-=(1/FRAME_RATE)
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
						camera.shake = Vector3.new((newUdim.X.Offset/width)*30,(newUdim.Y.Offset/height)*30)
					end
				end
			end

		else
			if not currentObjShakeData[obj].Completed then
				currentObjShakeData[obj].Completed = true
			end
		end
	end
	if currentObjShakeData[obj].i == ind then
		-- reset!
		if obj ~= "Camera" then
			obj.Position = originalPos
		else
			camera.shake = Vector3.new()
		end
		currentObjShakeData[obj]=nil;
	end
end
