@echo off


set "tempfolder=%~dp0\sdwebui\%RANDOM%"
cd %~dp0sdwebui
call environment.bat
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "%tempfolder%"
robocopy /E /NJH /NJS /NFL /NDL "%tempfolder%" %1
git -C %1 reset --hard
git -C %1 pull
rmdir /S /Q "%tempfolder%"