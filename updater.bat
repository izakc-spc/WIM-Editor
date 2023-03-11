@echo off
FOR /F "delims=" %%i IN ('"powershell -File .\src\getHash\getHash.ps1"') DO SET VAL=%%i
if %VAL% EQU 0 (echo newest WIM-Editor version in directory! Starting WIM-Editor... & timeout 3 >nul /nobreak & start main.bat & exit)
if %VAL% EQU 1 (goto upDateMain)

:upDateMain
echo There is an update available!
echo check out [https://github.com/izakc-spc/WIM-Editor]!
echo Update site will automatically open when leaving this script!
pause >nul & start https://github.com/izakc-spc/WIM-Editor
exit
