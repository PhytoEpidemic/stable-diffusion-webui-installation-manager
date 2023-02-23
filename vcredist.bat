@echo off
cd %~dp0
if exist "%windir%\SysWOW64\vcruntime140.dll" (
  echo VC++ Redistributable is installed
) else (
  echo Downloading VC++ Redistributable
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://aka.ms/vs/16/release/vc_redist.x64.exe', 'vc_redist.x64.exe')"
  echo Installing VC++ Redistributable
  start vc_redist.x64.exe /install /norestart
)
