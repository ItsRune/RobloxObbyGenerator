local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local generateBasedOffMode = require("generateBasedOffMode")
local Table = require("table-util")

local quickTypes = require("quickTypes")
local Settings: quickTypes.settings

local fileSuffix, fileName, fullFileName

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
		Ignored[fileSuffix] = Ignored[fileSuffix] or 0
		Ignored[fileSuffix] += 1
		-- print("Ignored: Expected .lua or .luau file suffix, received '" .. fileSuffix .. "'!")
		return nil
	end

	local newInst = Instance.new(robloxClassName)
	newInst.Parent = parent or game:GetService(tostring(service))
	newInst.Source = fs.readFile(path)

	return newInst
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
	local includesInitFile = (table.find(files, "init.lua") or table.find(files, "init.luau"))
	local split = string.split(path, "/")

	if not service then
		local isOk = pcall(game.GetService, game, split[#split])

		if isOk then
			service = split[#split]
		end
	end

	if includesInitFile then
		local suffix = table.find(files, "init.luau") and ".luau" or ".lua"

		if Settings.showDebugMessages then
			print("Generating 'init." .. suffix .. "' at path '" .. path .. "'")
		end

		local Inst = createInstanceBasedOnFile(path .. "/init" .. suffix, service, parent)

		if Inst then
			Inst.Name = split[#split] -- Make the script the name of the folder.
		end

		parent = Inst
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
		print("Generating lua file at path '" .. path .. "'")
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
		Table.ForEach(Ignored, function(count, index)
			print(string.format("Ignored %d files ending in '%s'.", count, index))
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
