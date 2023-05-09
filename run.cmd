SET scriptpath=%~dp0
echo %scriptpath:~0,-1%
powershell -ExecutionPolicy Bypass -File %scriptpath:~0,-1%\Apply-Tweaks.ps1
