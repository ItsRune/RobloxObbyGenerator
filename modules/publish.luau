local roblox = require("@lune/roblox")
local net = require("@lune/net")
local fs = require("@lune/fs")
local quickTypes = require("quickTypes")

local function handler(Settings: quickTypes.settings)
	local cookie = roblox.getAuthCookie(true)
	local robloxBinary = fs.readFile("./output/output.rbxl")
	local experienceId, placeId = Settings.Publish.experienceId, Settings.Publish.placeId

	assert(
		typeof(experienceId) == "number",
		"Expected a number for setting 'Publish.experienceId', received '" .. typeof(experienceId) .. "'!"
	)

	assert(
		typeof(placeId) == "number",
		"Expected a number for setting 'Publish.placeId', received '" .. typeof(placeId) .. "'!"
	)

	local Options = {
		-- This URL is for publishing models, not uploading (I THINK)
		url = "https://data.roblox.com/Data/Upload.ashx?assetid={}",
		method = "POST",
		headers = {
			["Cookie"] = cookie,
			["UserAgent"] = "Roblox/WinInet",
			["Content-Type"] = "application/xml",
			["Accept"] = "application/json",
		},
		body = robloxBinary,
	} :: any

	print("Uploading...")
	local response = net.request(Options)

	-- As per following rojo's implmentation of this; We should retry the request with the
	-- CSRF token when receiving a forbidden page.
	if response.statusCode == 403 and response.headers["X-CSRF-Token"] ~= nil then
		Options.headers["X-CSRF-Token"] = response.headers["X-CSRF-Token"]
		response = net.request(Options)
	end

	if not response.ok then
		error("The Roblox API returned an unexpected error: " .. tostring(response.body))
	end
end

return handler
