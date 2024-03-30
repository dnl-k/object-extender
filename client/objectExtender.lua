OE = {
  selectedElement,
  isPreviewVisible = false,
  offset = 1,
  data = {},
  controls = {},
  objects = {
    north = Object(1337, 0.0, 0.0, 0.0),
    east = Object(1337, 0.0, 0.0, 0.0),
    south = Object(1337, 0.0, 0.0, 0.0),
    west = Object(1337, 0.0, 0.0, 0.0),

  },
  metatable = {
    __index = OE
  }
}

local cc = exports.editor_main:getControls()

function OE:init()
  setmetatable({}, OE.metatable)
  self.controls = {
    ["extend"] = { key = "g", friendlyName = "Extend Object" },
    ["increase_offset"] = { key = "mouse_wheel_up", friendlyName = "Increase Offset", handler = function() self:onClientMouseWheel("up") end },
    ["decrease_offset"] = { key = "mouse_wheel_down", friendlyName = "Decrease Offset", handler = function() self:onClientMouseWheel("down") end },
    ["reset_offset"] = { key = "mouse3", friendlyName = "Reset Offset", handler = function() self:setOffset(1) end }
  }
  self.data = oe_elementData

  self:resetObjects(self.objects)
  exports.editor_main:registerEditorElements(self.objects.north)
  exports.editor_main:registerEditorElements(self.objects.east)
  exports.editor_main:registerEditorElements(self.objects.south)
  exports.editor_main:registerEditorElements(self.objects.west)

  self:setupControls()
  addEventHandler("onClientRender", root, function() self:onClientRender() end)
  addEventHandler("onClientDoubleClick", root, function() self:onClientDoubleClick() end)
  addEventHandler("onClientCursorMove", root, function() self:onClientCursorMove() end)
  return self
end

-------------------------------------
-- Reset things
-------------------------------------
function OE:resetObjects(objects)
  for i, object in pairs(objects) do
    object:setData("oe.isPreviewObject", true)
    object:setData("oe.isHovered", false)
    object:setModel(1337)
    object:setAlpha(150)
    object:setScale(1.0)
    object:setPosition(0.0, 0.0, 0.0)
    object:setRotation(0.0, 0.0, 0.0)
    object:setDimension(localPlayer.dimension + 1)
  end
end

function OE:setOffset(value)
  self.offset = math.min(math.max(value, 1), 15)
end

-------------------------------------
-- Setup key bindings and commands
-------------------------------------
function OE:setupControls()
  for i, control in pairs(self.controls) do
    addCommandHandler(control.friendlyName, control.handler and control.handler or function() end )
    bindKey(control.key, "down", control.friendlyName)
  end
end

function OE:getControlState(control)
  if self.controls[control] == nil then return false end
  local key = getKeyBoundToCommand(self.controls[control].friendlyName)
  local keyState = getKeyState(key)
  return keyState
end

function OE:getControlKey(control)
  if self.controls[control] == nil then return false end
  return getKeyBoundToCommand(self.controls[control].friendlyName)
end


function OE:onClientRender()
  -- Determine currently selected element
  local editorSelectedElement = exports.editor_main:getSelectedElement()
  if editorSelectedElement and isElement(editorSelectedElement) and editorSelectedElement:getType() == "object" then
    if editorSelectedElement ~= self.selectedElement then
      self.selectedElement = editorSelectedElement
    end
  else
    self.selectedElement = nil
  end
  if not isElement(self.selectedElement) then self.selectedElement = nil end 


  if self:getControlState("extend") and self.selectedElement and self.data[tostring(self.selectedElement:getModel())] then
    local matrix = self.selectedElement:getMatrix()
    local model = self.selectedElement:getModel()
    local scale = self.selectedElement:getScale()
    local rotation = self.selectedElement:getRotation()
    local data = self.data[tostring(model)]

    -- North
    self.objects.north:setPosition(matrix:transformPosition((data.y.position * scale) * self.offset))
    self.objects.north:setRotation(rotation + data.y.rotation)

    -- East
    self.objects.east:setPosition(matrix:transformPosition((data.x.position * scale) * self.offset))
    self.objects.east:setRotation(rotation + data.x.rotation)

    --South
    self.objects.south:setPosition(matrix:transformPosition((data.y.position * scale * -1.0) * self.offset))
    self.objects.south:setRotation(rotation + (data.y.rotation * -1.0))

    -- West
    self.objects.west:setPosition(matrix:transformPosition((data.x.position * scale * -1.0) * self.offset))
    self.objects.west:setRotation(rotation + (data.x.rotation * -1.0))

    for i, object in pairs(self.objects) do
      if isElement(object) then
        object:setModel(model)
        object:setScale(scale)
        object:setDimension(localPlayer.dimension)
        if object:getData("oe.isHovered") then
          object:setAlpha(255)
        else
          object:setAlpha(150)
        end
      end
    end

    exports.editor_main:enableMouseOver(false)
    exports.editor_main:setWorldClickEnabled(false)
    exports.move_keyboard:disable()

    self.isPreviewVisible = true
  else
    if self.isPreviewVisible then
      self:resetObjects(self.objects)

      exports.editor_main:enableMouseOver(true)
      exports.editor_main:setWorldClickEnabled(true)
      exports.move_keyboard:enable()

      self.isPreviewVisible = false
    end
  end
end

function OE:onClientDoubleClick(button, state, absoluteX, absoluteY, worldX, worldY, worldZ, clickedElement)
  if not self.isPreviewVisible then return end

  local targetElement, targetX, targetY, targetZ = getTargetedElement(worldX, worldY, worldZ)
	clickedElement = targetElement or clickedElement

	if clickedElement then
    if clickedElement:getData("oe.isPreviewObject") then
      triggerServerEvent("oe:createObject", localPlayer, {
        model = clickedElement:getModel(),
        position = {
          clickedElement.position.x,
          clickedElement.position.y,
          clickedElement.position.z
        },
        rotation = {
          clickedElement.rotation.x,
          clickedElement.rotation.y,
          clickedElement.rotation.z
        },
        scale = clickedElement.scale
      })
    end
  end
end

function OE:onClientCursorMove(cursorX, cursorY, absoluteX, absoluteY, worldX, worldY, worldZ)
  if not self.isPreviewVisible then return end
  for i, object in pairs(self.objects) do
    if isElement(object) then
      object:setData("oe.isHovered", false)
    end
  end

  local targetElement, targetX, targetY, targetZ = getTargetedElement(worldX, worldY, worldZ)
  if not targetElement or not targetElement:getData("oe.isPreviewObject") then return end
  targetElement:setData("oe.isHovered", true)
end

function OE:onClientMouseWheel(up_down)
  if not self.isPreviewVisible then return end
  local slow, medium, fast = exports.move_keyboard:getMoveSpeeds()

  local speed
  if getKeyState(cc["mod_fast_speed"]) then
    speed = medium
  else
    speed = slow
  end

  self:setOffset(self.offset + (up_down == "up" and speed or - speed))
end

function getTargetedElement(hitX, hitY, hitZ)
	local targetX, targetY, targetZ, targetedElement
	targetX, targetY, targetZ, targetedElement, buildingInfo = exports.editor_main:processCursorLineOfSight()

	local camX, camY, camZ = getCameraMatrix()

	if targetedElement then
		if getElementType(targetedElement) == "player" then
			targetedElement = false
		end
	end

	return targetedElement, targetX, targetY, targetZ, buildingInfo
end