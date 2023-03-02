lfs = require("lfs")
local argument = arg[1]
local SettingsFolder = os.getenv("APPDATA").."\\stable-diffusion-webui"
local settingsFileLocation = SettingsFolder.."\\launchersettings.txt"
local defaultSettings = {
	["installLocation"] = SettingsFolder,
	["COMMANDLINE_ARGS"] = "",
	["GIT_PULL"] = true,
	["OpenWindow"] = false,
}
local result = false

local function split_string(input_string)
	local words = {}
	
	for word in input_string:gmatch("%S+") do
		table.insert(words, word)
	end
	
	return words
end

local function get_nested_value(input_table, nested_table)
	local current_value = nested_table
	
	for i, key in ipairs(input_table) do
		current_value = current_value[key]
		
		if not current_value then
			return nil
		end
		
	end
	
	return current_value
end

local function get_value_from_file(filename, tag)
	local file = io.open(filename, "r")
	
	if file == nil then return false end
	
	for line in file:lines() do
		local s, e = string.find(line, tag .. "=")
		
		if s ~= nil then
			file:close()
			
			local value = string.sub(line, e + 1)
			
			if value:lower() == "true" or value:lower() == "false" then
				value = value:lower() == "true"
			end
			
			return value
		end
		
	end
	
	file:close()
	file = io.open(filename,"a")
	file:write("\n"..tag.."="..tostring(defaultSettings[tag]))
	file:close()
	
	return defaultSettings[tag]
end

local function update_value_in_file(filename, tag, new_text)
	local old_value = get_value_from_file(filename,tag)
	
	if old_value == new_text then
		return true
	end
	
	local file = io.open(filename, "r")
	
	if file == nil then return false end
	
	local file_lines = {}
	
	for line in file:lines() do
		local s, e = string.find(line, tag .. "=")
		
		if s ~= nil then
			table.insert(file_lines, (line:sub(1,e)) .. tostring(new_text))
		else
			table.insert(file_lines, line)
		end
		
	end
	
	file:close()
	
	file = io.open(filename, "w")
	
	if file == nil then return false end
	
	for i, line in ipairs(file_lines) do
		file:write(line, "\n")
	end
	
	file:close()
	
	return true
end

local function getWebui_user_bat(installLocation)
	local webui_user_bat = installLocation.."\\webui\\webui-user.bat"
	
	if not lfs.attributes(webui_user_bat) then
		if lfs.attributes(installLocation.."\\webui-user.bat") then
			webui_user_bat = installLocation.."\\webui-user.bat"
		end
	end
	
	return webui_user_bat
end

local function make_settings_file()
	if not lfs.attributes(settingsFileLocation) then
		local settingsFileHandle = io.open(settingsFileLocation,"w")
		
		if settingsFileHandle then
			settingsFileHandle:close()
			
			return true
		else
			--error
			return false
		end	
		
	end
	
end

local function setSetting(param, value)
	local equals = param:find("=")
	
	if equals then
		value = param:sub(equals+1,#param)
		param = param:sub(1,equals-1)
	end
	
	if param:sub(1,#"COMMANDLINE_ARGS") == "COMMANDLINE_ARGS" then
		
		local installLocation = get_value_from_file(settingsFileLocation,"installLocation")
		
		if installLocation then	
			update_value_in_file(getWebui_user_bat(installLocation),param,value)
		end
		
	else
		update_value_in_file(settingsFileLocation,param,value)
	end
	
end

if not lfs.attributes(SettingsFolder) then
	
	if not lfs.mkdir(SettingsFolder) then
		--error
	end
	
end

make_settings_file()

local function getSetting(param)
	if param:sub(1,#"COMMANDLINE_ARGS") == "COMMANDLINE_ARGS" then
		local installLocation = get_value_from_file(settingsFileLocation,"installLocation")
		
		if installLocation then
			return get_value_from_file(getWebui_user_bat(installLocation),param)
		end
		
	else
		return get_value_from_file(settingsFileLocation,param)
	end
	
	return false
end

if argument then
	if defaultSettings[argument] == nil then
		setSetting(argument)
	else
		print(tostring(getSetting(argument)))
	end
	
else
	local settings = {}
	settings.get = getSetting
	settings.set = setSetting
	
	return settings
end

