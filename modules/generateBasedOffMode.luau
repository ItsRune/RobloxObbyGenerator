local roblox = require("@lune/roblox")

local obbyGeneration = require("generateObby")
local quickTypes = require("quickTypes")

local function run(Settings: quickTypes.settings, game: roblox.DataModel): roblox.DataModel
	assert(string.lower(Settings.mode) == "obby", "This version only supports 'Obby' generation.")

	return obbyGeneration(Settings, game)
end

return run
