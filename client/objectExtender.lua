OE = {
  controls = {}
  objects = {}
  metatable = {
    __index = OE
  }
}

function OE:init()
  setmetatable({}, OE.metatable)
  self.controls = {
    ["extend"] = { key = "g", friendlyName = "Extend Object" }
  }
  self:setupControls()
  addEventHandler("onClientRender", root, function() self:onClientRender() end)
  return self
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

function MR:getControlState(control)
  if self.controls[control] == nil then return false end
  local key = getKeyBoundToCommand(self.controls[control].friendlyName)
  local keyState = getKeyState(key)
  return keyState
end

function MR:getControlKey(control)
  if self.controls[control] == nil then return false end
  return getKeyBoundToCommand(self.controls[control].friendlyName)
end


function OE:onClientRender()
  if self:getControlState("extend") then

  else
    if #self.objects > 0 then
      for i, object in pairs(self.objects) do
        if isElement(object) then
          object:destroy()
        end
      end
      self.objects = {}
    end
  end
end