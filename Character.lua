local Character = {}
Character.__index=Character

local getAnimFolder = function(animFolder)
	return animFolder:FindFirstChild("Animations") or animFolder:FindFirstChild("Anims") or {}
end

local function getAnimations(animData,side)
	local animFolder=animData:FindFirstChild(side) or getAnimFolder(animData)
	local animations={}
	local offset=nil
	if not (typeof(animFolder) == "table") then
		for _,anim:Animation in pairs(animFolder:GetChildren()) do
			animations[anim.Name]={Id=anim.AnimationId,Anim=anim}
		end
	end
	offset=animData:FindFirstChild("Offset") and animData.Offset.Value or animFolder:FindFirstChild("Offset") and animFolder.Offset.Value or nil
	return animations
end

local directions={
	"Left",
	"Down",
	"Up",
	"Right"
}

function Character:isLocked()
	return self.locked or false
end

function Character.new(char,side,cf,anim,HD,remote,locked)	
	anim=anim or "Default"
	local self = {
		missStuff={},
		locked=false, -- if locked, nothing will work (made for asigning other plr chars to a char class)
		char=char, -- char instance
		destroyChar=false,
		preloadedAnims={}, -- preloadedanims
		HD=nil, -- humanoiddescription
		Destroyed=false,
		CustomRig=nil, -- rig instance
		preloadedRigs={}, -- preloaded rigs
		animOffset=CFrame.new(), -- animoffset for cf
		animName=anim,-- start animName
		followPart=typeof(cf)=="Instance" and cf or nil,
		startCf=typeof(cf)=="Instance" and cf.CFrame or cf or char and char.PrimaryPart.CFrame or CFrame.new(),-- cf
		remote=remote,
		side=side,-- side
		Anims={}, -- anim table
		Danced=false, -- internal beatdance changing
		animData={}, -- animData
		Animator=nil, -- animator
		Humanoid=char and char:FindFirstChild("Humanoid"), --humanoid
		BeatDance=false, -- beatdance bool
		isRig=false, -- rig bool
		isR6=false, -- r6 bool
		BPM=120, -- for idle anim speed maybe?
		tracksPlayed=0, -- for counting how many anims has played
		currentAnim=nil,
		AnimatorScript=char and char:FindFirstChild("Animate"),
		HB=nil,
	}
	setmetatable(self,Character)
	
	if locked then self.locked=true return self end
	
	self:AnimatorScriptState(false) -- disable animator script
	
	--every physics frame
	self.HB=(game:GetService("RunService"):IsClient() and game:GetService("RunService").RenderStepped or game:GetService("RunService").Stepped):Connect(function()
		if self.followPart then
			if self.startCf ~= self.followPart.CFrame then
				self:SetCF(self.followPart.CFrame)
			end
		end
		if typeof(self.Parent)=="Instance" then
			self.char.Parent=self.Parent
		end
	end)
	-- replication
	if self.remote and game:GetService("RunService"):IsServer() then
		-- connect
		self.remoteConnection=self.remote.OnServerEvent:Connect(function(plr,...)
			local data={...}
			if data[1] == "Animate" then
				self:PlayAnimation(data[2],data[3],false,data[4])
			end
			if data[1] == "ChangeAnim" then
				self:ChangeAnim(data[2])
			end
			if data[1] == "PreloadAnim" then
				self:PreloadAnim(data[2])
			end
		end)
	end
	local newData={Humanoid=false,Animator=false}
	char.Parent=game.ReplicatedStorage
	if not self.Humanoid then -- humanoid creation
		local hum=Instance.new("Humanoid")
		hum.Parent=char
		self.Humanoid=hum
		newData.Humanoid=true
	end
	self.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	self.Animator=self.Humanoid:FindFirstChild("Animator")
	if not self.Animator then
		local animator=Instance.new("Animator")
		animator.Parent=self.Humanoid
		self.Animator=animator
		newData.Animator=true
	end
	self.HD=HD or newData.Humanoid==false and char.Humanoid:GetAppliedDescription()
	self.charData={Humanoid=self.Humanoid,Animator=self.Animator,Char=self.char}
	local animOffset=CFrame.new()
	local animData=game:GetService("ReplicatedStorage").Animations:FindFirstChild(anim)
	if animData then
		local da=self:PreloadAnim(anim) -- also preloads the rig
		self.currentAnim=anim
		self:UnloadRig()
		self:LoadRig(animData)
		local preloadedAnim=da
		local animations=preloadedAnim.anims
		if animData:GetAttribute("Mic") and not self.CustomRig then -- rig has the mic created on preload
			self.micData = self:CreateMicro(self.char,animData)
		end
		self.animData=preloadedAnim.animData
		self.BeatDance=preloadedAnim.isBeatDance and true or false
		for name,anims in pairs(animations) do
			self.Anims[name]=anims
		end
		self:Dance()
	end
	self.animOffset=animOffset
	self:SetCF(self.startCf)
	return self
end

function Character:AnimatorScriptState(bool:boolean)
	if self.AnimatorScript and self.AnimatorScript:IsA("LocalScript") then
		self.AnimatorScript.Disabled = not bool
	end
end

function Character:triggerModule()
	-- for modules stuff with animations :v
end

function Character:triggerRemote(...)
	local args={...}
	--if args[1] ~="Animate" then -- prevent print spam
	--	warn("Firing: ".. tostring(args[1]).. " with arguments: ".. tostring(args[2]).." // "..tostring(args[3]))
	--end
	if self.remote and game:GetService("RunService"):IsClient() then
		self.remote:FireServer(table.unpack(args))
	end
end

function Character:Dance()
	--	print"DANCING"
	if self.locked then return end
	if(self.BeatDance)then
		self.Danced=not self.Danced
		self:PlayAnimation(self.Danced and 'idleLeft' or 'idleRight',true,true)
	else
		self:PlayAnimation("Idle",true,true)
	end
	if not self:IsSinging() then
		self:triggerRemote("Animate","Idle",true)
	end
end

function Character:UnloadDirProps()
	
end

function Character:LoadDirProps(dir)
	-- unload props
end

local getInstance = function(char,data)
	if data==nil then return end
	local block = char
	for i=1,#data do
		local storedBlock = data[i]
		if not block:FindFirstChild(storedBlock) then break end
		block = block:FindFirstChild(storedBlock)
	end
	return block
end

local getrealName = function(char,block)
	if block == nil then return nil end
	local tab = {}
	local newParent = block
	table.insert(tab,1,block.Name)
	newParent = block.Parent
	if newParent ~= char then
		table.insert(tab,1,newParent.Name)
		repeat
			if newParent.Parent ~= char then
				newParent = newParent.Parent
				table.insert(tab,1,newParent.Name)
			end
		until newParent.Parent == char
	end
	return tab
end


local microphone=game.ReplicatedStorage.Mic:Clone()
local function getMicro()
	local micro = microphone:Clone()
	local motor = Instance.new("Motor6D")
	return micro,motor	
end

function Character:CreateMicro(char,animFolder)
	local mic,motor = getMicro()
	local char= char or self.CustomRig or self.char
	local par=animFolder:GetAttribute("MicAttach")
	if par then
		if string.split(par,"/")>1 then
			par=getInstance(char,string.split(par,"/"))
		else
			par=char:FindFirstChild(par)
		end
	end
	mic.Parent = par or char[animFolder:GetAttribute("FlipMic") and (animFolder:GetAttribute("R6") and "LeftArm" or "LeftHand") or (animFolder:GetAttribute("R6") and "RightArm" or "RightHand")]
	motor.Name = "Mic6D"
	motor.Parent = mic
	motor.Part0 =par or  char[animFolder:GetAttribute("FlipMic") and (animFolder:GetAttribute("R6") and "LeftArm" or "LeftHand") or (animFolder:GetAttribute("R6") and "RightArm" or "RightHand")]
	motor.Part1 = mic
	motor.C1 = CFrame.new(0,0.25,0.35) --offset
	return{Mic=mic,Motor=motor,Char=char}
end

function Character:GetCharacter()
	return self.CustomRig or self.char
end

function Character:SwitchMicro(micData)
	-- switch the micro hand!
	if not self.micData and not micData then return end
	local micData=micData or self.micData
	local partName=micData.Motor.Part0.Name
	local part=micData.Char:FindFirstChild(	
		partName=="LeftArm" and "RightArm" or
		partName=="RightArm" and "LeftArm" or
		partName=="LeftHand" and "RightHand" or
		partName=="RightHand" and "LeftHand")
	
	part=part or micData.Motor.Part0
	micData.Motor.Part0=part
end

function Character:PreloadRig(animData)
	if self.locked then return end
	if animData and animData:GetAttribute("Character") ~= "" and animData:GetAttribute("Character") and not self.preloadedRigs[animData:GetAttribute("Character")] then
		local preloadedData={}
		preloadedData.isRig = false
		preloadedData.isR6 = false
		preloadedData.Hidden=false
		local isR6=animData:GetAttribute("R6")
		local hasChar=animData:GetAttribute("Character") or ""
		local hide=animData:GetAttribute("Hide") or animData:GetAttribute("HideCharacter")
		if hide then
			preloadedData.Hidden=true
		end
		hasChar=game:GetService("ReplicatedStorage").Characters:FindFirstChild(hasChar)
		if (hasChar) or (isR6 and self.Humanoid.RigType == Enum.RigType.R15 and not hasChar) then
			local char=nil
			if hasChar then
				-- has custom char/rig // apply
				preloadedData.Rig=hasChar:Clone()
				char=preloadedData.Rig
				preloadedData.isRig=true

			elseif (isR6 and self.Humanoid.RigType == Enum.RigType.R15 and not hasChar) then
				-- is r15, convert to r6
				preloadedData.Rig=game:GetService("ReplicatedStorage").Characters.DefaultR6:Clone()
				preloadedData.isR6=true
				char=preloadedData.Rig
			end
			char.Parent=game.ReplicatedStorage
			char.Name="PRELOADED_PlayerRig"
			preloadedData.Humanoid=char:FindFirstChild("Humanoid")
			if not preloadedData.Humanoid then
				local hum=Instance.new("Humanoid")
				hum.Parent=char
				preloadedData.Humanoid=hum
			end
			preloadedData.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			preloadedData.Animator=preloadedData.Humanoid:FindFirstChild("Animator")
			if not preloadedData.Animator then
				local animator=Instance.new("Animator")
				animator.Parent=preloadedData.Humanoid
				preloadedData.Animator=animator
			end
			
			-- mic
			
			if animData:GetAttribute("Mic") then
				preloadedData.micData = self:CreateMicro(preloadedData.Rig,animData)
			end

			task.spawn(function() -- humanoid STUFF
				local Motor6DS = {}
				for _,descendant in pairs(char:GetDescendants()) do -- store motor6d to reload / reasign
					if descendant:IsA("Motor6D") then
						-- remember
						Motor6DS[descendant] = {
							[1] = getrealName(char,descendant.Part0),
							[2] = getrealName(char,descendant.Part1),
						}
					end
					if descendant:IsA("Highlight") then
						-- remember
						Motor6DS[descendant] = {
							[1] = getrealName(char,descendant.Adornee),
						}
						descendant.Adornee=nil
					end
				end

				if self.HD and not char:GetAttribute("NoDescription") then
					pcall(function()
						preloadedData.Humanoid:ApplyDescription(self.HD)
						print("Applied description")
					end)
				end

				for motor6d,dataer in pairs(Motor6DS) do -- reasign motor6d
					if motor6d:IsA("Highlight") then
						motor6d.Adornee = getInstance(char,dataer[1])
					else
						motor6d.Part0 = getInstance(char,dataer[1])
						motor6d.Part1 = getInstance(char,dataer[2])
					end
				end
			end)
		end
		self.preloadedRigs[animData:GetAttribute("Character")]=preloadedData
		return preloadedData
	end
end

function Character:LoadRig(animData)
	-- LOAD RIG // ANIM DATA!
	local rigData=self.preloadedRigs[animData:GetAttribute("Character")] or (not print"Preloading unloaded rig // Rig wasn't found") and self:PreloadRig(animData)
	if rigData then
		if rigData.Hidden or rigData.Rig then
			for i,v:BasePart in pairs(self.char:GetDescendants()) do
				if (v:IsA("BasePart") or v:IsA("Decal")) and (rigData.Rig and not v:IsAncestorOf(rigData.Rig)) then
					v.Transparency = 1
				end
			end
		end
		local rigFolder=self.char:FindFirstChild("Rig") or Instance.new"Folder"
		rigFolder.Name="Rig"
		rigFolder.Parent=self.char
		rigData.Rig:SetPrimaryPartCFrame(self.char.PrimaryPart.CFrame)
		for i,v in pairs(rigData.Rig:GetDescendants()) do
			if v:IsA("Highlight") then
				v.Enabled = true
			end
		end
		local weld=Instance.new("WeldConstraint")
		weld.Enabled=true
		weld.Part0=self.char.PrimaryPart
		weld.Part1=rigData.Rig.PrimaryPart
		weld.Parent=rigFolder
		rigData.Rig.Parent=rigFolder
		rigData.Rig.Name="PlayerRig"
		self.CustomRig=rigData.Rig
		self.Humanoid=rigData.Humanoid
		self.Animator=rigData.Animator
	end
end

function Character:UnloadRig()
	if self.CustomRig then self.CustomRig.Parent=game.ReplicatedStorage
		local rigFolder=self.char:FindFirstChild("Rig")
		if rigFolder then rigFolder:Destroy() end
		for i,v in pairs(self.CustomRig:GetDescendants()) do
			if v:IsA("Highlight") then
				v.Enabled = false
			end
		end
		for i,v in pairs(self.char:GetDescendants()) do
			if (v:IsA("BasePart") or v:IsA("Decal")) and v~=self.char.PrimaryPart then
				v.Transparency = 0
			end
		end
		self.Humanoid=self.charData.Humanoid
		self.Animator=self.charData.Animator
	end
end

local function getId(id)
	if typeof(id) == "string" then
		if string.find(id,"rbxassetid") or string.len(id) > 30 then
			return id
		else 
			return 'rbxassetid://' .. id
		end 
	else 
		return 'rbxassetid://' .. id
	end
end


function Character:Destroy()
	self.Destroyed=true
	self.locked=true
	self:UnloadRig()
	for _,data in pairs(self.preloadedRigs) do
		data.Rig:Destroy()
	end
	for _,data in pairs(self.preloadedAnims) do
		for _,anim in pairs(data.anims) do
			anim:Stop(0)
			anim:Destroy()
		end
	end
	if self.remoteConnection then
		self.remoteConnection:Disconnect()
	end
	if self.Animator then
		for _,anim in pairs(self.Animator:GetPlayingAnimationTracks()) do
			anim:Stop(0)
		end		
	end
	
	for _,stuff in pairs(self.missStuff or {}) do
		pcall(function()
			stuff:Destroy()
		end)
	end
	
	if self.destroyChar then
		if self.CustomRig then
			self.CustomRig:Destroy()
		end
		if self.char then
			self.char:Destroy()
		end
	end
	if self.HB then
		self.HB:Disconnect()
	end
	if self.micData then
		self.micData.Mic:Destroy()
		self.micData.Motor:Destroy()
	end
	self:AnimatorScriptState(true) -- enable animator script
end

function Character:AddAnimation(name,id,speed,looped,priority,isPreload,onRig)
	if self.locked then return end
-- isPreload will not add anim to the anim table, onRig will load it on a rig instead of self.Animator
	local anim = Instance.new("Animation")
	anim.AnimationId=getId(id)
	--warn(anim.AnimationId)
	local track = onRig and onRig.Animator:LoadAnimation(anim) or self.Animator:LoadAnimation(anim)
	track.Name=name;
	track.Looped=looped or false
	track.Priority=priority or track.Priority
	track:SetAttribute("Speed",speed or 1)
	track:SetAttribute("Playing",false)
	track:SetAttribute("Priority",track.Priority.Value)
	if not isPreload then
		self.Anims[name]=track;
	end
	return track
end

function Character:isAnimLoaded(anims,id)
	if self.locked then return end
	for _,v in pairs(anims or self.Anims) do
		if(v.Animation.AnimationId=='rbxassetid://'..id)then
			return true;
		end
	end
	return false;
end

function Character:GetTrack(name)
	return self.Anims[name]
end

function Character:StopCurrentTracks()
	for animname,anim in pairs(self.Anims) do
		if animname ~= "Idle" and animname ~="idleRight" and animname~="idleLeft" then
			anim:Stop(0)
			anim:SetAttribute("Playing",false)
		end
	end
end

function Character:isIdle(track)
	if typeof(track)=="string" then
		return not (track ~= "Idle" and track ~="idleRight" and track~="idleLeft")
	end
end

function Character:PlayAnimation(name,force,fromDance,prefix)
	force=true
	if self.locked then return end
	if self:isIdle(name) and not fromDance then return self:Dance() end
	local prefix= prefix or name:match("MISS") and "MISS" or name:match("ALT") and "ALT" or ""
	local track = self.Anims[name]
	if not track then
		if name:match("Right") then
			name = "Right"
		elseif name:match("Left") then
			name = "Left"
		elseif name:match("Up") or name:match("Square") or name:match("Plus") then
			name = "Up"
		elseif name:match("Down") then
			name = "Down"
		end
		track=self.Anims[name]
	end
	if(track)then
		--if(track:GetAttribute("Playing") and not force)then return end
		if not self:isIdle(name) then
			for _,stuff in pairs(self.missStuff or {}) do
				pcall(function()
					stuff:Destroy()
				end)
			end
			self.tracksPlayed +=1
			self:StopCurrentTracks()
			self:triggerRemote("Animate",name,force,prefix)
			if prefix=="MISS" then
				local tab = {}
				local misser = game:GetService("ReplicatedStorage").Assets.Missing:Clone()
				misser.Adornee = self:GetCharacter()
				misser.Parent = self:GetCharacter()
				misser.Name="MissEffect"
				table.insert(tab,misser)
				if self:GetCharacter():FindFirstChild("Head") then
					local at = game:GetService("ReplicatedStorage").Assets.MissHolder.Miss:Clone()
					at.Parent = self:GetCharacter().Head
					at.Part.CFrame = at.WorldCFrame
					at.Part.WeldConstraint.Part0 = self:GetCharacter().Head
					at.Part.WeldConstraint.Part1 = at.Part
					table.insert(tab,at)
				end

				self.missStuff = tab
			end
		end
		local curanimnum = self.tracksPlayed
		track:AdjustSpeed(self.Anims[name]:GetAttribute("Speed")or 1)
		track:SetAttribute("Playing",true)
		track.TimePosition=0
		track:Play(0)
		
		if self.LastTrack then
			self.LastTrack:Stop()
			self.LastTrack:SetAttribute("Playing",false)
		end
		
		task.delay((track.Length - 0.04)-track.TimePosition,function()
			if not self.Destroyed and curanimnum == self.tracksPlayed and not self:isIdle(name) then
				if prefix=="MISS" then
					for _,stuff in pairs(self.missStuff or {}) do
						pcall(function()
							stuff:Destroy()
						end)
					end
				end
				track:Stop(0)
				track:SetAttribute("Playing",false)
				self:triggerRemote("PropLoad","Idle",true)
			end
		end)		
	else
		if self.animData[name] then
			-- load unloaded anim
			local data=self.animData[name]
			self:AddAnimation(name,data.Id,data.Anim:GetAttribute("Speed") or 1,false,Enum.AnimationPriority[data.Anim:GetAttribute("Priority") or "Movement"])
			self:PlayAnimation(name,force,fromDance)
		end
	end
end

function Character:IsSinging()
	for n,v in next, self.Anims do
		if(not self:isIdle(n) and v:GetAttribute("Playing"))then
			return true
		end
	end
	return false
end

function Character:SetCF(cf) -- set the cf
	cf=cf or self.startCf
	self.startCf=cf
	self.char:SetPrimaryPartCFrame(cf*self.animOffset)
end

function Character:isPreloaded(anim)
	return self.preloadedAnims[anim] and true or false
end

function Character:PreloadAnim(anim) -- Also known as LoadAnim
	if self.locked then return end
	local side=self.side
	local animData=game:GetService("ReplicatedStorage").Animations:FindFirstChild(anim)
	if animData and not self.preloadedAnims[anim] then
		self:triggerRemote("PreloadAnim",anim)
		local rig=(animData:GetAttribute("Character") or animData:GetAttribute("R6"))
		if rig then
			rig=self:PreloadRig(animData) -- preload anims INSIDE the rig humanoid//animator
		end
		if not rig then
			rig=self.charData --lets troll saying it has a rig (it doesnt!)
			-- just to make sure it loads on the player character.....
		end
		local preloadedAnimData={anims={}}
		local animations=getAnimations(animData,side)
		local data=animData:FindFirstChild("Data") and require(animData.Data) or {}
		preloadedAnimData.animData=animations

		if(animations.idleLeft and animations.idleRight)then
			preloadedAnimData["isBeatDance"]=true;
			preloadedAnimData.anims["idleLeft"]=self:AddAnimation("idleLeft",animations["idleLeft"].Id,animations["idleLeft"].Anim:GetAttribute("Speed") or 1,true,Enum.AnimationPriority.Idle,true,rig)
			preloadedAnimData.anims["idleRight"]=self:AddAnimation("idleRight",animations["idleRight"].Id,animations["idleRight"].Anim:GetAttribute("Speed") or 1,true,Enum.AnimationPriority.Idle,true,rig)
		else
			preloadedAnimData.anims["Idle"]=self:AddAnimation("Idle",animations["Idle"].Id,animations["Idle"].Anim:GetAttribute("Speed") or 1,true,Enum.AnimationPriority.Idle,true,rig)
		end
		for _,dir in pairs(directions) do
			local data=animations[dir]
			if data then
				preloadedAnimData.anims[dir]=self:AddAnimation(dir,data.Id,data.Anim:GetAttribute("Speed")or 1,false,Enum.AnimationPriority.Movement,true,rig)
				-- miss // alts?
				local alt=animations["ALT"..dir]
				if alt then
					preloadedAnimData.anims["ALT"..dir]=self:AddAnimation("ALT"..dir,alt.Id,alt.Anim:GetAttribute("Speed")or 1,false,Enum.AnimationPriority.Movement,true,rig)
				else
					preloadedAnimData.anims["ALT"..dir]=preloadedAnimData.anims[dir]
				end

				local miss=animations[dir.."MISS"]
				if miss then
					preloadedAnimData.anims[dir.."MISS"]=self:AddAnimation(dir.."MISS",miss.Id,miss.Anim:GetAttribute("Speed")or 1,false,Enum.AnimationPriority.Movement,true,rig)
				else
					preloadedAnimData.anims["ALT"..dir]=preloadedAnimData.anims[dir.."MISS"]
				end
			end
		end
		for name,data in next,animations do
			if((typeof(data.Id)=='string' or typeof(data.Id)=='number') and not self:isAnimLoaded(preloadedAnimData.anims,data.Id) and not preloadedAnimData.anims[name])then
				preloadedAnimData.anims[name]=self:AddAnimation(name,data.Id,data.Anim:GetAttribute("Speed") or 1,false,Enum.AnimationPriority[data.Anim:GetAttribute("Priority") or "Action"],true,rig)
			end
		end
		self.preloadedAnims[anim]=preloadedAnimData
		return preloadedAnimData
	end
end

function Character:UnloadMic(micData)
	local micData=micData or self.micData
	if not micData then return end
	micData.Mic:Destroy()
	micData.Motor:Destroy()
	if micData==self.micData then
		self.micData=nil
	end
end

function Character:ChangeAnim(anim)
	if self.locked then return end
	local side=self.side
	local animOffset=CFrame.new()
	local animData=game:GetService("ReplicatedStorage").Animations:FindFirstChild(anim)
	if animData and self.currentAnim~=anim then
		self:triggerRemote("ChangeAnim",anim)
		local realAnims={}
		local oldAnims=self.Anims
		local da=self.preloadedAnims[anim] or self:PreloadAnim(anim)
		self.currentAnim=anim
		self:UnloadRig()
		da.anims["Idle"]:Play(0)
		self:LoadRig(animData)
		self:UnloadMic(self.micData)
		if animData:GetAttribute("Mic") and not self.CustomRig then
			self.micData = self:CreateMicro(self.char,animData)
		end
		local preloadedAnim=da
		local animations=preloadedAnim.anims
		realAnims=animations
		self.Anims["Idle"]:Stop()
		for name,anims in pairs(animations) do
			anims:Stop(0)
			self.Anims[name]=anims
		end
		self.animData=preloadedAnim.animData
		self.BeatDance=preloadedAnim.isBeatDance and true or false
		for name,anim in pairs(oldAnims) do -- unload old anims
			anim:Stop(0)
			if not realAnims[name] then
				self.Anims[name]=nil -- destroy!
			end
		end
	end
	self.animOffset=animOffset
	self:SetCF()
end

return Character
