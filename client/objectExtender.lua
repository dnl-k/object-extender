OE = {
  selectedElement,
  isPreviewVisible = false,
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

function OE:init()
  setmetatable({}, OE.metatable)
  self.controls = {
    ["extend"] = { key = "g", friendlyName = "Extend Object" }
  }
  self.data = oe_elementData

  self:resetObject(self.objects.north)
  exports.editor_main:registerEditorElements(self.objects.north)

  self:resetObject(self.objects.east)
  exports.editor_main:registerEditorElements(self.objects.east)

  self:resetObject(self.objects.south)
  exports.editor_main:registerEditorElements(self.objects.south)

  self:resetObject(self.objects.west)
  exports.editor_main:registerEditorElements(self.objects.west)

  self:setupControls()
  addEventHandler("onClientRender", root, function() self:onClientRender() end)
  return self
end

-------------------------------------
-- Reset things
-------------------------------------
function OE:resetObject(object)
  object:setData("oe.isPreviewObject", true)
  object:setModel(1337)
  object:setAlpha(150)
  object:setScale(1.0)
  object:setPosition(0.0, 0.0, 0.0)
  object:setRotation(0.0, 0.0, 0.0)
  object:setDimension(localPlayer.dimension + 1)
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
    if self.selectedElement:getData("oe.isPreviewObject") then
      exports.editor_main:dropElement()
      -- TODO: Find out how to not cause errors :)
      return
    end


    local matrix = self.selectedElement:getMatrix()
    local model = self.selectedElement:getModel()
    local scale = self.selectedElement:getScale()
    local rotation = self.selectedElement:getRotation()
    local data = self.data[tostring(model)]

    -- North
    self.objects.north:setPosition(matrix:transformPosition(data.y.position * scale))
    self.objects.north:setRotation(rotation + data.y.rotation)

    -- East
    self.objects.east:setPosition(matrix:transformPosition(data.x.position * scale))
    self.objects.east:setRotation(rotation + data.x.rotation)
    --South
    self.objects.south:setPosition(matrix:transformPosition(data.y.position * scale * -1.0))
    self.objects.south:setRotation(rotation + (data.y.rotation * -1.0))
    -- West
    self.objects.west:setPosition(matrix:transformPosition(data.x.position * scale * -1.0))
    self.objects.west:setRotation(rotation + (data.x.rotation * -1.0))

    for i, object in pairs(self.objects) do
      if isElement(object) then
        object:setModel(model)
        object:setScale(scale)
        object:setDimension(localPlayer.dimension)
      end
    end
    self.isPreviewVisible = true
  else
    if self.isPreviewVisible then
      for i, object in pairs(self.objects) do
        if isElement(object) then
          self:resetObject(object)
        end
      end
      self.isPreviewVisible = false
    end
  end
end