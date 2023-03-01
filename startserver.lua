
lfs = require("lfs")
local script_dir = lfs.currentdir()
lfs.chdir(script_dir)
if lfs.attributes("instcomp") then
	os.execute([[powershell -window normal -command ""]])
	
	local settings = require("settingsget")
	
	lfs.chdir(settings.get("installLocation"))
	os.execute("title Stable Diffusion Webui Server")
	
	if lfs.attributes("webui-user.bat") then
		os.execute("webui-user.bat")
	elseif lfs.attributes("run.bat") then
		os.execute("run.bat")	
	end
	
end

