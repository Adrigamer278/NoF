local Tween = {
	_VERSION = 1.0,
	_Info = [[
	Variable Tweener module made by Minz#0708 / Adrigamer278YT, for NoF (Night Of Funk)
	with the use of tweening for lua (https://github.com/kikito/tween.lua) support him

	Discord Server:
	discord.gg/ACrKtktwPj

	No need to ask for permission
	Thanks for using!
	]]
}

Tween.__index = Tween

local RunningTweens = {}

game["Run Service"].Heartbeat:Connect(function(dt)
	for _,tween in pairs(RunningTweens) do
		-- for each tween
		local ended,isStart = tween:update(tween.self.aboutToLoop==true and -tween.clock or (dt * (tween.self.isReturning and -1 or 1)))
		tween.self.aboutToLoop=false
		if ended or isStart then
			-- Ended?
			if tween.self.Returns and tween.self.isReturning==false and ended then
				tween.self.isReturning=true
			elseif tween.self.Returns and tween.self.isReturning==true and isStart then
				-- loop fellas
				if (tween.self.Loops >0 and tween.self.LoopsDone < tween.self.Loops) or tween.self.Loops <=-1 then
					-- loop omg
					tween.self.isReturning=false
					tween.self.aboutToLoop=true
				end
			else
				if ended then
					if (tween.self.Loops >0 and tween.self.LoopsDone < tween.self.Loops) or tween.self.Loops <=-1 then
						-- loop omg
						tween.self.isReturning=false
						tween.self.aboutToLoop=true
					end
				end
			end
		end
	end
end)

local mainTween = require(script.Tween)
function formatTweenData(data:TweenInfo)
	local moreData={
		Delay=0,
		Loops=0,
		Returns=false,
	}
	local new={
		Duration = 1,
		Easing = "linear"
	}
	new.Duration = data.Time or 1
	moreData.Delay=data.DelayTime
	moreData.Loops=data.RepeatCount
	moreData.Returns=data.Reverses
	-- hardcoding the way roblox doesnt make easingstyle names shorter
	-- but doesnt affect performance as is on creation
	local EasingDir = data.EasingDirection and (data.EasingDirection.Name == "InOut" and "outIn" or string.lower(data.EasingDirection.Name)) or ""

	local EasingStyle = data.EasingStyle and (data.EasingStyle.Name == "Circular" and "Circ" or data.EasingStyle.Name == "Exponential" and "Expo" or data.EasingStyle.Name == "Linear" and "linear" or data.EasingStyle.Name) or "linear"
	if EasingStyle == "linear" then
		EasingDir = ""
	end
	new.Easing = EasingDir..EasingStyle
	return new,moreData
end

function create(tab,tweenData,tabValues)
	local moreData
	tweenData,moreData = formatTweenData(tweenData)
	local tween = mainTween.new(tweenData.Duration,tab,tabValues,tweenData.Easing)
	return tween,moreData
end

function Tween.new(tab,tweenInfo,data)
	local tw,data=create(tab,tweenInfo,data)
	local remo=Instance.new("BindableEvent")
	local self = {
		tween = tw,
		Dl=data.Delay,
		Loops=data.Loops,
		LoopsDone=0,
		aboutToLoop=false,
		isReturning=false,
		Returns=data.Returns,
		_REMOTE=remo,
		Completed=remo.Event,
		timesPlayed=0,
		timesPlayedCalled=0,
		waitingToPlay=false
	}
	setmetatable(self, Tween)
	self.tween.self=self
	return self
end

function Tween:Create(tab,tweenInfo,data)
	return Tween.new(tab,tweenInfo,data)
end

function Tween:Play()
	-- no yield
	coroutine.resume(coroutine.create(function()
		self.timesPlayedCalled+=1
		self.waitingToPlay=true
		local s=self.timesPlayedCalled
		if self.Dl>0 then
			task.wait(tonumber(self.Dl) or 0)
		end
		if s~=self.timesPlayedCalled and not self.waitingToPlay then return end
		if not table.find(RunningTweens,self.tween) then table.insert(RunningTweens,self.tween) end
	end))
end

function Tween:Pause()
	self.waitingToPlay=false
	if table.find(RunningTweens,self.tween) then table.remove(RunningTweens,table.find(RunningTweens,self.tween)) end
end

function Tween:Cancel()
	self.waitingToPlay=false
	self:Pause()
	self.tween.reset()
end

function Tween:Destroy()
	self:Pause()
	self = nil
end

return Tween
