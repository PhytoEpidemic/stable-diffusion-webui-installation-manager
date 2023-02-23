os.execute("title Stable Diffusion webui updater")
lfs = require("lfs")
local function pause()
	os.execute("pause")
end
local function copy_recursive(source_dir, dest_dir)
    for file in lfs.dir(source_dir) do
        if file ~= "." and file ~= ".." then
            local source_path = source_dir .. "\\" .. file
            local dest_path = dest_dir .. "\\" .. file
            local source_attrs = lfs.attributes(source_path)
            if source_attrs.mode == "directory" then
                if lfs.attributes(dest_path, "mode") == "file" then
                    os.remove(dest_path)
                end
                lfs.mkdir(dest_path)
                local copy_success, copy_err = copy_recursive(source_path, dest_path)
				if not copy_success then
					return false, copy_err
				end
            elseif source_attrs.mode == "file" then
                local dest_attrs = lfs.attributes(dest_path)
                if dest_attrs and dest_attrs.mode == "directory" then
                    os.execute([[rmdir /S /Q "]]..dest_path..[["]])
                end
                if dest_attrs and dest_attrs.mode == "file" then
                    if source_attrs.modification > dest_attrs.modification then
                        print("Update: "..dest_path)
                        local source_OK, source_file = pcall(io.open, source_path, "rb")
                        local dest_OK, dest_file = pcall(io.open, dest_path, "wb")
                        if not (source_OK and dest_OK) then
                            if source_file then
							source_file:close()
							end
							if dest_file then
								dest_file:close()
							end
							return false, source_err or dest_err
                        end
                        dest_file:write(source_file:read("*all"))
                        source_file:close()
                        dest_file:close()
                    end
                else
                    print("New: "..dest_path)
                    local source_OK, source_file = pcall(io.open, source_path, "rb")
                    local dest_OK, dest_file = pcall(io.open, dest_path, "wb")
					if not (source_OK and dest_OK) then
                        if source_file then
							source_file:close()
						end
						if dest_file then
							dest_file:close()
						end
						return false, source_file or dest_file
                    end
                    dest_file:write(source_file:read("*all"))
                    source_file:close()
                    dest_file:close()
					lfs.touch(dest_path,lfs.attributes(source_path).modification)
                end
            end
        end
    end
    return true
end



function loadOptions(filename)
    local options = {}

    for line in io.lines(filename) do
        local label, value = line:match("^(.-)=(.-)$")
		if label then
			if value:lower() == "true" or value:lower() == "false" then
				value = value:lower() == "true"
			end
			options[label] = value
		end
		
    end
    return options
end



local function showwindow()
	os.execute([[powershell -window normal -command ""]])
end

local function hidewindow()
	os.execute([[powershell -window hidden -command ""]])
end

local settings = require("settingsget")
os.execute("powershell -File GUI.ps1")
-- -ExecutionPolicy Bypass

if lfs.attributes("GUI_output.txt") then
	
	showwindow()
	
	local script_dir = lfs.currentdir()
	-- Change the working directory to the directory containing this script
	lfs.chdir(script_dir)
	local config = loadOptions("GUI_output.txt")
	local SOURCE_DIR = "sdwebui"
	local DEST_DIR = config.installLocation
	local MODEL_DIR = DEST_DIR .. "\\webui\\models\\Stable-diffusion"
	--os.remove("GUI_output.txt")
	
	-- Install vcredist
	os.execute("vcredist.bat")
	-- Extract the files
	os.execute("7za.exe x stable-diffusion-webui.7z")
	os.execute("7za.exe x -osdwebui system.7z")
	
	-- Update the files
	
	
	if lfs.mkdir(DEST_DIR) then
		os.execute([[robocopy /E /MT /NFL /NJS /NJH "]]..SOURCE_DIR..[[" "]]..DEST_DIR..[["]])
	else
		local copy_success, copy_err = copy_recursive(SOURCE_DIR, DEST_DIR)
		if copy_success then
		
		end
	end
	lfs.chdir(DEST_DIR)
	if not lfs.attributes(DEST_DIR.."\\webui") then
		os.execute(DEST_DIR.."\\install.bat")
	elseif config.GIT_PULL then
		os.execute(DEST_DIR.."\\update.bat")
	end
	
	
	lfs.chdir(script_dir)
	settings.set("installLocation",config.installLocation)
	settings.set("COMMANDLINE_ARGS",config.COMMANDLINE_ARGS)
	settings.set("GIT_PULL",config.GIT_PULL)
	
	
	
	
	local MODEL_LINKS = {
		["sd-v1-4"] = {
			DIR = MODEL_DIR,
			link = "https://huggingface.co/CompVis/stable-diffusion-v-1-4-original/resolve/main/sd-v1-4.ckpt",
			ext = "ckpt"
		},
		["v1-5-pruned-emaonly"] = {
			DIR = MODEL_DIR,
			link = "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors",
			ext = "safetensors"
		},
		["wd-v1-3-full"] = {
			DIR = MODEL_DIR,
			link = "https://huggingface.co/hakurei/waifu-diffusion-v1-3/resolve/main/wd-v1-3-full.ckpt",
			ext = "ckpt"
		},
		["protogenX53Photorealism_10"] = {
			DIR = MODEL_DIR,
			link = "https://civitai.com/api/download/models/4229?type=Model&format=PickleTensor",
			ext = "ckpt"
		},
		["protogenV22Anime_22"] = {
			DIR = MODEL_DIR,
			link = "https://civitai.com/api/download/models/4007?type=Model&format=PickleTensor",
			ext = "ckpt"
			
		},
		["v2-1_768-nonema-pruned"] = {
			DIR = MODEL_DIR,
			link = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-nonema-pruned.ckpt",
			ext = "ckpt",
			extra_downloads = {
				MODEL_DIR,
				"v2-1_768-nonema-pruned.yaml",
				"https://raw.githubusercontent.com/Stability-AI/stablediffusion/main/configs/stable-diffusion/v2-inference-v.yaml",
			}
		},
		["ControlNet"] = {
			DIR = DEST_DIR .. "\\webui\\extensions\\sd-webui-controlnet\\models",
			pre_install = {[1] = {["start_in"] = DEST_DIR, ["installer"] = script_dir.."\\extra-installers\\ControlNet"}},
			extra_downloads = {
				"cldm_v15.yaml",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/raw/main/cldm_v15.yaml",
				"control_canny-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_canny-fp16.safetensors",
				"control_depth-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_depth-fp16.safetensors",
				"control_hed-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_hed-fp16.safetensors",
				"control_mlsd-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_mlsd-fp16.safetensors",
				"control_normal-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_normal-fp16.safetensors",
				"control_openpose-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_openpose-fp16.safetensors",
				"control_scribble-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_scribble-fp16.safetensors",
				"control_seg-fp16.safetensors",
				"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/control_seg-fp16.safetensors",
				--"t2iadapter_keypose-fp16.safetensors",
				--"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/t2iadapter_keypose-fp16.safetensors",
				--"t2iadapter_seg-fp16.safetensors",
				--"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/t2iadapter_seg-fp16.safetensors",
				--"t2iadapter_sketch-fp16.safetensors",
				--"https://huggingface.co/webui/ControlNet-modules-safetensors/resolve/main/t2iadapter_sketch-fp16.safetensors",
			}
		},
		["instruct-pix2pix"] = {
			DIR = MODEL_DIR,
			link = "https://huggingface.co/timbrooks/instruct-pix2pix/resolve/main/instruct-pix2pix-00-22000.safetensors",
			ext = "safetensors"
			
		},
		
	}
	
	
	
	
	for model,download in pairs(loadOptions("models_download.txt")) do
		if download then
			local info = MODEL_LINKS[model]
			if not lfs.attributes(info.DIR) then
				os.execute([[mkdir "]]..info.DIR..[["]])
			end
			if info.link and (not config.OverwriteModels) and lfs.attributes(info.DIR .. "\\"..model.."."..(info.ext)) then
				print("Model file already found.")
				print("Skipping download of model: "..model)
			else
				
				print("Downloading: "..model)
				if info.pre_install then
					for _,prereq in ipairs(info.pre_install) do
						lfs.chdir(prereq.start_in)
						os.execute(prereq.installer)
					end
				end
				if info.link then
					os.execute("curl -L -o \"" .. info.DIR .. "\\"..model.."."..(info.ext).."\" \"" .. (info.link) .. "\"")
					if info.extra_downloads then
						for i=1, #info.extra_downloads, 3 do
							local existing_file = lfs.attributes(info.extra_downloads[i] .. "\\"..info.extra_downloads[i+1])
							if (not existing_file) or (existing_file and existing_file.size < 1024*10) or config.OverwriteModels then
								print("Downloading: "..info.extra_downloads[i+1])
								os.execute("curl -L -o \"" .. info.extra_downloads[i] .. "\\"..info.extra_downloads[i+1].."\" \"" .. (info.extra_downloads[i+2]) .. "\"")
							end
						end
					end
				else
					if info.extra_downloads then
						for i=1, #info.extra_downloads, 2 do
							local existing_file = lfs.attributes(info.DIR .. "\\"..info.extra_downloads[i])
							if (not existing_file) or (existing_file and existing_file.size < 1024*10) or config.OverwriteModels then
								print("Downloading: "..info.extra_downloads[i])
								os.execute("curl -L -o \"" .. info.DIR .. "\\"..info.extra_downloads[i].."\" \"" .. (info.extra_downloads[i+1]) .. "\"")
							end
							
						end
					end
				end
				
				
				
			end
		end
	end
	lfs.chdir(script_dir)
	io.open("instcomp","w"):close()
end


