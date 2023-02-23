@echo off
cd %~dp0
call environment.bat



git -C "%~dp0webui" reset --hard
git -C "%~dp0webui" pull



