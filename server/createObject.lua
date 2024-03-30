addEvent("oe:createObject", true)
addEventHandler("oe:createObject", root, function(parameters)
  local id = string.format("OE:Object (%d)", countObjects())

  local element = exports.edf:edfCreateElement("object", client, Resource.getFromName("editor_main"), {
    model = parameters.model,
    position = parameters.position,
    rotation = parameters.rotation,
    scale = parameters.scale,
    dimension = exports.editor_main:getWorkingDimension(),
    id = id
  }, true)
  element:setID(id)

  triggerClientEvent(client, "doSelectElement", element, 2)

  triggerEvent("onElementCreate_undoredo", element)
  triggerEvent("onElementCreate", element)
	triggerClientEvent(root, "onClientElementCreate", element)
end)

function countObjects()
	local counter = 0
	for key, element in pairs(Element.getAllByType("object")) do
    if string.find(element:getID(), "OE:Object") then counter = counter + 1 end
	end
	return counter
end