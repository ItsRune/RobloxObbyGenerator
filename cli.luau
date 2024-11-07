local stdio = require("@lune/stdio")
local serde = require("@lune/serde")
local fs = require("@lune/fs")

local generate = require("./modules/generate")
local _publish = require("./modules/publish")
local quickTypes = require("modules/quickTypes")

local settingsContents = fs.readFile("./settings.json")
local Settings = serde.decode("json", settingsContents) :: quickTypes.settings

local SELECTION_KIND = {
	"Generate",
	"Generate & Publish",
}

local result = stdio.prompt("select", "Please select the generation type you'd like to use:", SELECTION_KIND)
local resultKind = SELECTION_KIND[result]

if not resultKind then
	error("Unexpected error occurred.")
	return
end

if resultKind == SELECTION_KIND[2] then -- Publish too...
	Settings.output.xmlKind = true
	generate(Settings)

	assert(false, "Not implemented.")
elseif resultKind == SELECTION_KIND[1] then
	generate(Settings)
end
