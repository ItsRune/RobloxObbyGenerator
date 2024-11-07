local fs = require("@lune/fs")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance

local function recursivelyParseAndCreateInstances(
	data: { [any]: any },
	parent: roblox.Instance?,
	isTopLevel: boolean?,
	fileName: string?
): roblox.Instance?
	local Inst: roblox.Instance?

	if not Inst then
		local isOk, newInst = pcall(Instance.new, data["Class"])

		if not isOk then
			warn("BROKE")
			return nil
		end

		Inst = newInst

		if isTopLevel and data["Name"] == nil and fileName ~= nil then
			newInst.Name = fileName
		end
	end

	for key, value in data do
		-- Class already handled.
		if key == "Class" then
			continue
		-- Handle 'Children'
		elseif key == "Children" then
			parent = Inst

			for _, moreData in value do
				local newInst = recursivelyParseAndCreateInstances(moreData, parent)

				if not newInst then
					continue
				elseif parent == nil then
					Inst = newInst
					continue
				end

				newInst.Parent = parent
			end
		-- Protective call setting properties.
		else
			pcall(function(...)
				(Inst :: roblox.Instance)[key] = value
			end)
		end
	end

	if parent ~= nil and Inst ~= nil then
		pcall(function(...)
			Inst.Parent = parent
		end)
	end

	return Inst
end

local function syncWithRobloxFromConfigLanguage(parent: roblox.Instance, path: string): boolean
	local split, routeSplit = string.split(path, "."), string.split(path, "/")
	local suffix: serde.EncodeDecodeFormat = string.lower(split[#split]) :: any

	local isOk, decoded = pcall(serde.decode, suffix, fs.readFile(path))
	assert(isOk, "Error syncing a configuration language with path '" .. path .. "'!")

	local test = recursivelyParseAndCreateInstances(
		decoded,
		parent,
		true,
		string.split(routeSplit[#routeSplit], ".")[1]
	) :: roblox.Instance

	pcall(function(...)
		test.Parent = parent
	end)

	return typeof(test) ~= nil
end

return syncWithRobloxFromConfigLanguage
