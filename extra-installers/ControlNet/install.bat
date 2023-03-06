@echo off
call environment.bat
cd %~dp0
git clone https://github.com/Mikubill/sd-webui-controlnet.git "%~dp0temp"
robocopy /E /NJH /NJS /NFL /NDL "%~dp0temp" "%1"
git -C "%1" reset --hard
git -C "%1" pull
