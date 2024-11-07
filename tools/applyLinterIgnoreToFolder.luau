local TO_ADD_TO_FILE = [[
--!nolint
--!nocheck

]]

local process = require("@lune/process")
local stdio = require("@lune/stdio")
local DateTime = require("@lune/DateTime")
local fs = require("@lune/fs")
local args = {}

if #process.args == 0 then
	table.insert(args, stdio.prompt("text", "Please specify the path you'd like to apply linter ignores to:"))
else
	table.insert(args, process.args[1])
end

local function applyLinterIgnores(path: string, isTop: boolean?)
	local start = DateTime.now().unixTimestampMillis
	local meta = fs.metadata(path)
	local pathSplit = string.split(path, ".")
	local suffix = table.concat(pathSplit, ".", 2, #pathSplit)

	assert(meta.exists, "Expected path to directory/file, received invalid path!")

	if meta.kind == "dir" then
		local files = fs.readDir(path)

		for _, file in files do
			applyLinterIgnores(string.format("%s/%s", path, file))
		end
	elseif meta.kind == "file" and string.match(suffix, "luau?") ~= nil then
		local data = fs.readFile(path)
		fs.writeFile(path, TO_ADD_TO_FILE .. data)
	end

	if isTop then
		print(
			"'applyLinterIgnoreToFolder' took "
				.. tostring((DateTime.now().unixTimestampMillis - start) / 1000)
				.. " seconds to complete."
		)
	end
end

applyLinterIgnores(args[1], true)
