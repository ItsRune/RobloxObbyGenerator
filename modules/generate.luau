local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local generateBasedOffMode = require("generateBasedOffMode")
local Table = require("table-util")
local quickTypes = require("quickTypes")
local syncWithRobloxFromConfigLanguage = require("syncJSONWithRoblox")

local Settings: quickTypes.settings
local fileSuffix: string, fileName: string, fullFileName: string

local Ignored = {}
local placeFile = fs.readFile("./Baseplate.rbxl")
local game = roblox.deserializePlace(placeFile)
local Instance = roblox.Instance

local robloxFileTypeEquivalent = {
	[".lua"] = "ModuleScript",
	[".server.lua"] = "Script",
	[".client.lua"] = "LocalScript",

	[".luau"] = "ModuleScript",
	[".server.luau"] = "Script",
	[".client.luau"] = "LocalScript",
}

-- Generation code here
--[=[
	Grabs the deepest instance based on the path provided.
	@param path string
	@return `Instance?`

	```lua
	--[[
	ReplicatedStorage<Service>
		- Child<Folder>
			- InnerChild<Folder>
				- Descendant<ModuleScript>
	]]--
	local path = "./code/ReplicatedStorage/Child/InnerChild/Descendant"
	local deepInstance = getDeepestInstance(path) --> ModuleScript
	```
]=]
local function getDeepestInstance(path: string): roblox.Instance?
	local pathSplit = string.split(string.gsub(path, "%.", ""), "/")
	local baseDescendant = nil

	for index, pathStr in ipairs(pathSplit) do
		if not baseDescendant then
			local isService = pcall(game.GetService, game, pathStr)
			if not isService then
				continue
			end

			baseDescendant = game:GetService(pathStr)

			if index == #pathSplit then
				return baseDescendant
			end
		end

		local foundInst = baseDescendant:FindFirstChild(pathStr)
		if foundInst ~= nil then
			baseDescendant = foundInst
			continue
		end
	end

	return baseDescendant
end

--[=[
	Creates and Instance based on the file's type.
	@param path string
	@param service string?
	@param parent Instance?
	@return `Instance?`

	```lua
	local path = "./code/ReplicatedStorage/Test.luau"
	local modScript = createInstanceBasedOnFile(path)
	
	local path2 = "./code/ServerScriptService/Test.server.luau"
	local serverScript = createInstanceBasedOnFile(path2)

	local path3 = "./code/StarterGui/Test.client.luau"
	local localScript = createInstanceBasedOnFile(path3)
	```
]=]
local function createInstanceBasedOnFile(path: string, service: string?, parent: roblox.Instance?): roblox.Instance?
	local split = string.split(path, "/")
	local pathSplit = string.split(split[#split], ".")
	local fileSuffix = "." .. table.concat(pathSplit, ".", 2, #pathSplit)
	local robloxClassName = robloxFileTypeEquivalent[fileSuffix]

	if not robloxClassName then
		Ignored[fileSuffix] = Ignored[fileSuffix] or {}
		table.insert(Ignored[fileSuffix], path)
		return nil
	end

	local newInst = Instance.new(robloxClassName)
	newInst.Parent = parent or game:GetService(tostring(service))
	newInst.Source = fs.readFile(path)

	return newInst
end

--[=[
	Checks for the keys within `robloxFileTypeEquivalent` for a match on the file's suffix.
	@param files { string }
	@return (boolean, string?)

	```lua
	local files = { "init.luau", "SomethingElse.lua" }
	local isInitFile = checkForInitFile(files) --> true, init.luau

	local files2 = { "notInit.luau", "SomethingElse.lua" }
	local isInitFile2 = checkForInitFile(files2) --> false, nil
	```
]=]
local function checkForInitFile(files: { string }): (boolean, string?)
	local Keys = Table.Keys(robloxFileTypeEquivalent)
	for _, file in files do
		local split = string.split(file, ".")
		local suffix = "." .. table.concat(split, ".", 2, #split)
		if string.lower(split[1]) ~= "init" then
			continue
		end

		if table.find(Keys, suffix) then
			return true, file
		end
	end

	return false
end

--[=[
	Traverses the code directory for .lua/.luau files then creates a Server/Local/Module script based on the suffix.
	@param path string
	@param service string?
	@param parent Instance?
	@return `Instance?`

	```lua
		local path = "./code"
		traverseCodeDirectories(path)
	```
]=]
local function traverseCodeDirectories(path: string, service: string?, parent: roblox.Instance?): roblox.Instance?
	local isDir = fs.isDir(path)
	local files = isDir and fs.readDir(path) or {}
	local includesInitFile, initFileName = checkForInitFile(files)
	local split = string.split(path, "/")

	if not service then
		local isOk = pcall(game.GetService, game, split[#split])

		if isOk then
			service = split[#split]
		end
	end

	if includesInitFile then
		if Settings.showDebugMessages then
			print("Generating '" .. tostring(initFileName) .. "' at path '" .. path .. "'")
		end

		local Inst = createInstanceBasedOnFile(path .. "/" .. tostring(initFileName), service, parent)
		if Inst then
			Inst.Name = split[#split] -- Make the script the name of the folder.
			parent = Inst
		end
	end

	if isDir then
		local deepestFolder = getDeepestInstance(path)

		if
			not includesInitFile
			and service ~= nil
			and (deepestFolder == nil or deepestFolder.Name ~= split[#split])
		then
			local newFolder = Instance.new("Folder")
			newFolder.Name = split[#split]
			newFolder.Parent = deepestFolder

			deepestFolder = newFolder
		end

		for _, v in ipairs(fs.readDir(path)) do
			-- Since we already handle the module script's initialization.
			if string.match(v, "init%.") ~= nil then
				continue
			end

			local tempInstance: any = traverseCodeDirectories(path .. `/{v}`, service, parent)
			if not tempInstance then
				continue
			end

			local nameSplit = string.split(v, ".")
			tempInstance.Name = nameSplit[1]
			tempInstance.Parent = parent or deepestFolder
		end

		-- Sanity check
		if parent and parent.Parent and parent.Parent.Name ~= split[#split - 1] then
			local tempPath = table.concat(split, "/", 1, #split - 1)
			local deepestInst = getDeepestInstance(tempPath)

			if deepestInst then
				parent.Parent = deepestInst
			end
		end

		return nil
	end

	if Settings.showDebugMessages then
		print("Generating '" .. split[#split] .. "' at path '" .. path .. "'")
	end

	return createInstanceBasedOnFile(path, service, parent)
end

local function handler(_Settings: quickTypes.settings)
	Settings = _Settings
	fileSuffix, fileName =
		Settings.output.xmlKind and ".rbxlx" or ".rbxl", Settings.output and Settings.output.fileName or "output"
	fullFileName = fileName .. fileSuffix

	traverseCodeDirectories("./assets/code")
	print(string.format("Generated '%s' at path '%s'...", fullFileName, "./output/" .. fullFileName))

	if Settings.showDebugMessages and Table.Count(Ignored) > 0 then
		local allowed = { ".json", ".yaml", ".toml" }

		Table.ForEach(Ignored, function(paths, fileSuffix)
			if table.find(allowed, fileSuffix) ~= nil then
				Table.ForEach(paths, function(currentPath: string)
					local tempSplit = string.split(currentPath, "/")
					local backtrace = table.concat(tempSplit, "/", 1, #tempSplit - 1)
					local parent = getDeepestInstance(backtrace) :: roblox.Instance
					local succeeded = syncWithRobloxFromConfigLanguage(parent, currentPath)

					if not succeeded and Settings.showDebugMessages then
						print(string.format("Ignored a '%s' file at path '%s'", fileSuffix, currentPath))
					end
				end)
			end
		end)
	end

	game = generateBasedOffMode(Settings, game)

	if not game then
		error("Error: Place binary failed to generate properly!", 0)
		return
	end

	-- File write
	local robloxBinary = roblox.serializePlace(game)
	fs.writeFile("./output/" .. fileName .. fileSuffix, robloxBinary)
end

return handler
