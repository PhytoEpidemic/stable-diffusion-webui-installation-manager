@echo off
cd %~dp0
call environment.bat



set path_to_pull=%~dp0webui\extensions

for /D %%d in (%path_to_pull%\*) do (
  git -C "%%d" reset --hard
  git -C "%%d" pull
)

echo All git repositories have been pulled and reset.
