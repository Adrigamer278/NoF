local Drag = {
	_VERSION = 1.0,
	_Info = [[
	Drag module made by Minz#0708 / Adrigamer278YT, for NoF (Night Of Funk)
	Supports gamepad / touch controls

	Discord Server:
	discord.gg/ACrKtktwPj

	Ask for permission or let me know if your game uses it
	Thanks!
	]]
}
Drag.__index = Drag

local UserInputService = game:GetService("UserInputService")
local GamepadService = game:GetService("GamepadService")
local currentDrag = nil
local CONTROLLER_DEADZONE = 0

function Drag.new(obj)
	local self	= {
		isGamepad = false,
		curGamepadMovement = Vector2.new(),
		Object = obj,
		Dragging = false,
		dragInput = nil,
		dragStart = nil,
		startPos = nil,
		preparingToDrag	= false,
		Enabled = true,
		Events = {
			DraggedStarted = Instance.new("BindableEvent"),
			Dragged = Instance.new("BindableEvent"),
			DraggedEnded = Instance.new("BindableEvent"),
		}
	}

	setmetatable(self, Drag)
	return self
end

function Drag:Enable()
	-- Disable movement
	local obj = self.Object
	self.Enabled = true

	local function update(input)
		local delta 		= input.Position - self.dragStart
		local newPosition	= UDim2.new(self.startPos.X.Scale, self.startPos.X.Offset + delta.X, self.startPos.Y.Scale, self.startPos.Y.Offset + delta.Y)
		obj.Position 	= newPosition
		local ScaleXPos = obj.Position.X.Offset/obj.Parent.AbsoluteSize.X + obj.Position.X.Scale
		local ScaleYPos = obj.Position.Y.Offset/obj.Parent.AbsoluteSize.Y + obj.Position.Y.Scale
		obj.Position = UDim2.fromScale(ScaleXPos,ScaleYPos)
		return newPosition
	end

	self.InputBegan = UserInputService.InputBegan:Connect(function(input)
		self.curGamepadMovement = input.Position
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.Gamepad1 then
			if input.UserInputType == Enum.UserInputType.Gamepad1 then
				GamepadService:DisableGamepadCursor()	
				UserInputService.MouseIconEnabled = false
				self.isGamepad = true
			else
				self.isGamepad = false
			end
			self.preparingToDrag = true
			currentDrag = obj

			local connection 
			connection = input.Changed:Connect(function()
				pcall(function()
					if input.UserInputState == Enum.UserInputState.End and (self.Dragging or self.preparingToDrag) then
						self.curGamepadMovement = Vector2.new(0,0)
						self.Dragging = false
						currentDrag = nil
						connection:Disconnect()
						self.preparingToDrag = false
						self:Disable()
					end
				end)
			end)
		end
	end)

	self.InputChanged = obj.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			self.dragInput = input
		end
	end)

	self.InputChanged2 = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Gamepad1 then
			self.curGamepadMovement = input.Position
		end
		if obj.Parent == nil then
			self:Disable()
			return
		end

		if self.preparingToDrag then
			self.preparingToDrag = false
			self.Events.DraggedStarted:Fire()
			self.Dragging	= true
			self.dragStart = input.Position
			self.startPos = obj.Position
		end

		if not self.isGamepad and self.Dragging then
			local newPosition = update(input)
		end
	end)

	self.InputEnded = UserInputService.InputEnded:Connect(function(input)
		self.curGamepadMovement = Vector2.new(0,0)
		if not self.isGamepad then
			self:Disable()
		end
		--	StopLOL(obj)
	end)

	task.spawn(function()
		local dt = 0
		local stored = tick()
		while self.Enabled and task.wait() do
			local newtick = tick()
			dt = stored-newtick
			stored = newtick
			local movement = self.curGamepadMovement
			pcall(function()
				if (self.Dragging or self.preparingToDrag) and self.isGamepad then
					local xPos = obj.Position.X.Offset + (math.abs(movement.X) > CONTROLLER_DEADZONE and -(movement.X>0 and movement.X-CONTROLLER_DEADZONE or movement.X+CONTROLLER_DEADZONE)*750*dt or 0)
					local yPos = obj.Position.Y.Offset + (math.abs(movement.Y) > CONTROLLER_DEADZONE and (movement.Y>0 and movement.Y-CONTROLLER_DEADZONE or movement.Y+CONTROLLER_DEADZONE)*750*dt or 0)
					obj.Position = UDim2.new(obj.Position.X.Scale,xPos,obj.Position.Y.Scale,yPos)
					local ScaleXPos = obj.Position.X.Offset/obj.Parent.AbsoluteSize.X + obj.Position.X.Scale
					local ScaleYPos = obj.Position.Y.Offset/obj.Parent.AbsoluteSize.Y + obj.Position.Y.Scale
					obj.Position = UDim2.fromScale(ScaleXPos,ScaleYPos)
				end 
			end)
		end
	end)
end

function Drag:Connect(eventName,run)
	if not self.Events[eventName] then return error("Invalid Event Name!") end
	self.Events[eventName].Event:Connect(function()
		pcall(function()
			run()
		end)
	end)
end

function Drag:Disable(dontShow)
	if not self then return end
	if self.Enabled == false then return end
	if currentDrag == self.Object then currentDrag = nil end
	self.Events.DraggedEnded:Fire()
	self.isGamepad = false
	local obj = self.Object
	if not dontShow then
		UserInputService.MouseIconEnabled = true
		if UserInputService.GamepadEnabled then
			GamepadService:EnableGamepadCursor(obj)
		end
	end
	pcall(function()
		self.InputBegan:Disconnect()
	end)
	pcall(function()
		self.InputChanged:Disconnect()
	end)
	pcall(function()
		self.InputChanged2:Disconnect()
	end)
	pcall(function()
		self.InputEnded:Disconnect()
	end)
	for _,thing in pairs(self.Events) do
		thing:Destroy()
	end
	local ScaleXPos = obj.Position.X.Offset/obj.Parent.AbsoluteSize.X + obj.Position.X.Scale
	local ScaleYPos = obj.Position.Y.Offset/obj.Parent.AbsoluteSize.Y + obj.Position.Y.Scale
	obj.Position = UDim2.fromScale(ScaleXPos,ScaleYPos)
	-- save data owo
	self.Dragging = false
	self.Enabled = false
	self = nil
end

function Drag:Destroy()

end

return Drag
