--!nocheck

local roblox = require("@lune/roblox")
local quickTypes = require("quickTypes")
local fs = require("@lune/fs")
local CFrame, Vector3 = roblox.CFrame, roblox.Vector3

local function _GetBoundingBox(model)
	if model:IsA("Model") then
		model = model:GetDescendants()
	end

	local orientation = CFrame.new()

	local abs = math.abs
	local inf = math.huge

	local minx, miny, minz = inf, inf, inf
	local maxx, maxy, maxz = -inf, -inf, -inf

	for _, obj in pairs(model) do
		if obj:IsA("BasePart") then
			local cf = obj.CFrame
			cf = orientation:ToObjectSpace(cf)
			local size = obj.Size
			local sx, sy, sz = size.X, size.Y, size.Z

			local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:GetComponents()

			local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz)
			local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz)
			local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz)

			if minx > x - wsx then
				minx = x - wsx
			end
			if miny > y - wsy then
				miny = y - wsy
			end
			if minz > z - wsz then
				minz = z - wsz
			end

			if maxx < x + wsx then
				maxx = x + wsx
			end
			if maxy < y + wsy then
				maxy = y + wsy
			end
			if maxz < z + wsz then
				maxz = z + wsz
			end
		end
	end

	local omin, omax = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
	local omiddle = (omax + omin) / 2
	local wCf = orientation - orientation.Position + orientation:PointToWorldSpace(omiddle)
	local size = (omax - omin)

	return wCf, size
end

local function generateObby(Settings: quickTypes.settings, game: roblox.DataModel): roblox.DataModel
	local perDifficulty = math.floor(Settings.sections / #Settings.difficulties)
	local start = game:GetService("Workspace"):FindFirstChildWhichIsA("SpawnLocation")
	local models = roblox.deserializeModel(fs.readFile("./assets/Assets.rbxm"))[1]

	if not models then
		return error("Error: Assets file has no valid assets to use!")
	end

	game:GetService("Workspace").Baseplate:Destroy()

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

			-- The line below works for the first iteration then breaks for the rest.
			newModel.PrimaryPart.CFrame = start.CFrame
				* CFrame.new(0, start.Size.Y / 2, 0)
				* CFrame.new(0, 0, -(newModel.PrimaryPart.Size.Z + start.Size.Z) / 2)

			start = newModel.End
		end
	end

	return game
end

return generateObby
