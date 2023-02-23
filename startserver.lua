
lfs = require("lfs")
local script_dir = lfs.currentdir()
lfs.chdir(script_dir)
if lfs.attributes("instcomp") then
	os.execute([[powershell -window normal -command ""]])
	local settings = require("settingsget")
	lfs.chdir(settings.get("installLocation"))
	os.execute("title Stable Diffusion Local Server")
	os.execute("run.bat")
end

