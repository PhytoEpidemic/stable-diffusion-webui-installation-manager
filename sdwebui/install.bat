@echo off
cd %~dp0
call environment.bat
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git %~dp0webui

