@echo off
cd %~dp0
call environment.bat
git clone https://github.com/Mikubill/sd-webui-controlnet.git %~dp0webui\extensions\sd-webui-controlnet

git -C "%~dp0webui\extensions\sd-webui-controlnet" reset --hard
git -C "%~dp0webui\extensions\sd-webui-controlnet" pull
