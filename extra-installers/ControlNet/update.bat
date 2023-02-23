@echo off
cd %~dp0
call environment.bat

git -C "%~dp0webui\extensions\sd-webui-controlnet" reset --hard
git -C "%~dp0webui\extensions\sd-webui-controlnet" pull


