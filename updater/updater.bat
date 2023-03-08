@echo off
FOR /F "delims=" %%i IN ('"powershell -File .\updater.ps1"') DO SET VAL=%%i
if %VAL% EQU 0 (echo newest WIM-Editor version in directory! Starting WIM-Editor... & timeout 1 >nul /nobreak & start main.bat)
if %VAL% EQU 1 (goto upDateMain)

:upDateMain
echo There is an update available!
echo check out [https://github.com/izakc-spc/WIM-Editor]!
echo Update site will automatically open when exiting this script!
pause >nul & start https://github.com/izakc-spc/WIM-Editor
exit

:skipVer
echo Version skipped. Opening WIM-Editor... & timeout 1 >nul /nobreak & start main.bat
exit