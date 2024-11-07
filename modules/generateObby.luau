local roblox = require("@lune/roblox")
local quickTypes = require("quickTypes")
local fs = require("@lune/fs")
local CFrame: { [any]: any } = roblox.CFrame

local function generateObby(Settings: quickTypes.settings, game: roblox.DataModel): roblox.DataModel
	local perDifficulty = math.floor(Settings.sections / #Settings.difficulties)
	local lastModel = game:GetService("Workspace"):FindFirstChildWhichIsA("SpawnLocation")
	local models = roblox.deserializeModel(fs.readFile("./assets/Assets.rbxm"))[1]

	if not models then
		return error("Error: Assets file has no valid assets to use!")
	end

	game:GetService("Workspace")["Baseplate"]:Destroy()

	for difficulty = 1, #Settings.difficulties do
		local difficultyName = Settings.difficulties[difficulty]

		if not models[difficultyName] then
			print(
				string.format(
					"Error: '%s' is not a valid difficulty at path './models/data/%s/'!",
					difficultyName,
					difficultyName
				)
			)
			continue
		end

		for i = 1, perDifficulty do
			local newModel =
				models[difficultyName]:GetChildren()[math.random(1, #models[difficultyName]:GetChildren())]:Clone()

			newModel:AddTag("StageModel")
			newModel.Name = tostring(difficulty * i)
			newModel.Parent = game:GetService("Workspace")

			local endPart = lastModel :: roblox.Instance
			local handlePart = lastModel :: roblox.Instance

			if lastModel and lastModel.ClassName ~= "SpawnLocation" then
				endPart = lastModel["End"]
				handlePart = lastModel["PrimaryPart"]
			end

			local newCFrame = endPart["CFrame"]
				* CFrame.new(0, handlePart["Size"].Y / 2, 0)
				* CFrame.new(0, 0, -(newModel.PrimaryPart.Size.Z + handlePart["Size"].Z) / 2)

			newModel.PrimaryPart.CFrame = newCFrame
			lastModel = newModel
		end
	end

	return game
end

return generateObby
