os.execute("title Stable Diffusion Webui Updater")

lfs = require("lfs")

local function pause()
	os.execute("pause")
end

local function cls()
	os.execute("cls")
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

function string_findlast(str,pat)
	local sspot,lspot = str:find(pat)
	local lastsspot, lastlspot = sspot, lspot
	
	while sspot do
		lastsspot, lastlspot = sspot, lspot
		sspot, lspot = str:find(pat,lastlspot+1)
	end
	
	return lastsspot, lastlspot
end

function startswith(st,pat)
	return st:sub(1,#pat) == pat
end

function endswith(st,pat)
	return st:sub(#st-(#pat-1),#st) == pat
end

function folderUP(path,num)	
	num = num or 1
	local look = string_findlast(path,[[\]])
	
	if look then 
		local upafolder = path:sub(1,look-1)
		
		if num > 1 then
			return folderUP(upafolder,num-1)
		else
			return upafolder
		end
		
	else
		return ""
	end
	
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


local function updateOldInstallation(runFrom, installLocation)
	lfs.chdir(runFrom)
	
	local batCode = [[
@echo off
cd %~dp0
call environment.bat



git -C "]]..installLocation..[[" reset --hard
git -C "]]..installLocation..[[" pull

set path_to_pull="]]..installLocation..[[\extensions"

for /D %%d in (%path_to_pull%\*) do (
  git -C "%%d" reset --hard
  git -C "%%d" pull
)


]]
	local tmpbat = io.open("tmpbat.bat","w")
	
	tmpbat:write(batCode)
	tmpbat:close()
	os.execute("tmpbat.bat")
	os.remove("tmpbat.bat")
end
	

local function showwindow()
	os.execute([[powershell -window normal -command ""]])
end

local function hidewindow()
	os.execute([[powershell -window hidden -command ""]])
end

local settings = require("settingsget")

os.execute("powershell -ExecutionPolicy Bypass -File GUI.ps1")
cls()
if not lfs.attributes("GUI_output.txt") then
	return os.exit()
end

showwindow()

local oldInstallation = false
local script_dir = lfs.currentdir()

lfs.chdir(script_dir)

local config = loadOptions("GUI_output.txt")

if lfs.attributes(folderUP(config.installLocation) .. "\\webui\\webui-user.bat") and lfs.attributes(folderUP(config.installLocation) .. "\\system") then
	config.installLocation = folderUP(config.installLocation)
end

if lfs.attributes(config.installLocation .. "\\webui-user.bat") then
	--Detected raw git clone installation
	print("This installation is using 'venv', would you like to convert it to the new release structure? [y/n]")
	if io.read() == "y" then
		os.execute([[rmdir /S /Q "]]..config.installLocation.."\\venv"..[["]])
		lfs.mkdir(config.installLocation.."\\webui")
		for file in lfs.dir(config.installLocation) do
			if file ~= "." and file ~= ".." then
				if file ~= "webui" then
					os.rename(config.installLocation.."\\"..file,config.installLocation.."\\webui\\"..file)
				end
				
			end
			
		end
		
	else
		oldInstallation = true
	end
	
end

local SOURCE_DIR = "sdwebui"
local DEST_DIR = config.installLocation
local MODEL_DIR = DEST_DIR .. "\\webui\\models\\Stable-diffusion"
local VAE_DIR = DEST_DIR .. "\\webui\\models\\VAE"

os.execute("vcredist.bat")
os.execute("7za.exe x stable-diffusion-webui.7z")
os.execute("7za.exe x -osdwebui system.7z")
lfs.mkdir("dltmp")

if not oldInstallation then
	
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
		os.execute(DEST_DIR.."\\update_extensions.bat")
	end
	
else
	
	if config.GIT_PULL then
		updateOldInstallation(script_dir.."\\webui",config.installLocation)
	end
	
	MODEL_DIR = DEST_DIR .. "\\models\\Stable-diffusion"
	VAE_DIR = DEST_DIR .. "\\models\\VAE"
end

lfs.chdir(script_dir)
settings.set("installLocation",config.installLocation)
settings.set("COMMANDLINE_ARGS",config.COMMANDLINE_ARGS)
settings.set("GIT_PULL",config.GIT_PULL)
settings.set("OpenWindow",config.OpenWindow)




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
	["sd-vae-ft-mse"] = {
		DIR = VAE_DIR,
		link = "https://huggingface.co/stabilityai/sd-vae-ft-mse/resolve/main/diffusion_pytorch_model.safetensors",
		ext = "safetensors"
	},
	["sd-v1-5-inpainting"] = {
		DIR = MODEL_DIR,
		link = "https://huggingface.co/runwayml/stable-diffusion-inpainting/resolve/main/sd-v1-5-inpainting.ckpt",
		ext = "ckpt"
	},
	["512-inpainting-ema"] = {
		DIR = MODEL_DIR,
		link = "https://huggingface.co/stabilityai/stable-diffusion-2-inpainting/resolve/main/512-inpainting-ema.safetensors",
		ext = "safetensors"
		
	},
	["v2-1_768-nonema-pruned"] = {
		DIR = MODEL_DIR,
		link = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-nonema-pruned.safetensors",
		ext = "safetensors",
		extra_downloads = {
			MODEL_DIR,
			"v2-1_768-nonema-pruned.yaml",
			"https://raw.githubusercontent.com/Stability-AI/stablediffusion/main/configs/stable-diffusion/v2-inference-v.yaml",
		}
	},
	["v2-1_768-ema-pruned"] = {
		DIR = MODEL_DIR,
		link = "https://huggingface.co/stabilityai/stable-diffusion-2-1/resolve/main/v2-1_768-ema-pruned.safetensors",
		ext = "safetensors",
		extra_downloads = {
			MODEL_DIR,
			"v2-1_768-ema-pruned.yaml",
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

local function downloadFile(file_name, download_link, download_dir)
	print("Downloading: " .. file_name)
	lfs.chdir(script_dir .. "\\dltmp")
	os.execute([[curl -L -o "]] .. file_name .. [[" "]] .. download_link .. [["]])
	os.execute([[move /Y "]] .. file_name .. [[" "]] .. download_dir .. "\\" .. file_name .. [["]])
end

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
			if info.pre_install then
				for _,prereq in ipairs(info.pre_install) do
					lfs.chdir(prereq.start_in)
					os.execute(prereq.installer)
				end
				
			end
			
			if info.link then
				downloadFile(model.."."..(info.ext),info.link,info.DIR)
				
				if info.extra_downloads then
					for i=1, #info.extra_downloads, 3 do
						local existing_file = lfs.attributes(info.extra_downloads[i] .. "\\"..info.extra_downloads[i+1])
						
						if (not existing_file) or (existing_file and existing_file.size < 1024*10) or config.OverwriteModels then
							downloadFile(info.extra_downloads[i+1],info.extra_downloads[i+2],info.extra_downloads[i])
						end
						
					end
					
				end
				
			else
				if info.extra_downloads then
					for i=1, #info.extra_downloads, 2 do
						local existing_file = lfs.attributes(info.DIR .. "\\"..info.extra_downloads[i])
						
						if (not existing_file) or (existing_file and existing_file.size < 1024*10) or config.OverwriteModels then
							downloadFile(info.extra_downloads[i],info.extra_downloads[i+1],info.DIR)
						end
						
					end
					
				end
				
			end
			
		end
		
	end
	
end

lfs.chdir(script_dir)

if config.OpenWindow then
	io.popen([["C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --app=http://127.0.0.1:7860 2>&1]])
end

io.open("instcomp","w"):close()




