@setlocal enableextensions enabledelayedexpansion
@echo off
REM ///Set 1 title...\\\
title Execute as admin

REM ///Check if its a 64 Bit or 32 Bit os and set folder...\\\
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS=32BIT || set OS=64BIT
if %OS% EQU 64BIT ( set osFolder=x64 )
if %OS% EQU 32BIT ( set osFolder=x32 )

REM ///Check if excuted as administrator, if not, execute as admin\\\
:AdminRightsRoutine
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
	>NUL 2>&1 "%SYSTEMROOT%\SysWOW64\caCLS.exe" "%SYSTEMROOT%\SysWOW64\config\system"
		) ELSE (
	>NUL 2>&1 "%SYSTEMROOT%\system32\caCLS.exe" "%SYSTEMROOT%\system32\config\system"
		)

IF '%ERRORLEVEL%' NEQ '0' (
    goto GetAdminRights
) ELSE ( GOTO GetAdminRightsSuccess )
:GetAdminRights
echo This script is not executed as administrator! Prompting for elevation now...
timeout 1 >nul /nobreak
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\GetAdminRights.vbs"
SET params = %*:"=""
ECHO UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\GetAdminRights.vbs"
"%temp%\GetAdminRights.vbs"
DEL "%temp%\GetAdminRights.vbs"
EXIT /B
:GetAdminRightsSuccess
pushd "%CD%"
CD /D "%~dp0"
title Windows Image Editing tool @ by Izakc SPC V: Alpha v0.1 & echo Administrative access given! & timeout 2 >nul /nobreak
goto startApplet

:startApplet
REM ///Setting workdirectory for later operations...\\\
set workDir=%CD%

REM ///Start of program and prompting for input directory...\\\
echo.
echo  ##################################
echo  # Windows Image mounting/editing #
echo  ##################################
echo.
echo Script Version: [Alpha v0.1]
echo.
echo You can exit at any time by pressing Ctrl + C [it may take sometimes a bit to process!]
echo WARNING: THIS SCRIPT IS FOR EDITING ONLY **ONE** IMAGE FOR ADDING THIS IMAGE TO ANOTHER, YOU HAVE TO DO IT YOURSELF WITH DISM!!!
echo.
echo Press any key to continue... & pause >nul
echo.
timeout 1 >nul /nobreak
echo Prompting for iso input directory...
echo.
:wrongDir
for /f "delims=" %%A in ('src\folderbrowse\folderbrowse.exe "Select the folder which contains the iso file(s):"') do set "ImageDir=%%A"
if /I %ImageDir% EQU \ (echo Select a directory!! & goto :wrongDir)
echo Selected directory: %ImageDir%
:reaskWIM
set /p dirRequ=Is the slected directory correct? (Y/N): 
if /I %dirRequ% EQU Y (goto skipSecQu)
if /I %dirRequ% EQU N (goto wrongDir) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM)
:skipSecQu

echo.
echo Prompting for extraction directory...
echo.
:wrongExctDir
for /f "delims=" %%A in ('src\folderbrowse\folderbrowse.exe "Select the folder where the iso gets extracted to:"') do set "ExctractionDir=%%A"
if /I %ExctractionDir% EQU \ (echo Select a directory!! & goto :wrongExctDir)
echo Selected directory: %ExctractionDir%
:reaskWIM2
set /p ExctdirRequ=Is the slected directory correct? (Y/N): 
if /I %ExctdirRequ% EQU Y (goto cont)
if /I %ExctdirRequ% EQU N (goto wrongExctDir) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM2)
:cont

REM ///Listing of available iso files and selection...\\\
set file=%ImageDir%
FOR /F "delims=" %%i IN ("%file%") DO (
set driveLetterImg=%%~di
)
%driveLetterImg%
cd %ImageDir%
echo.
echo Listing available iso files...
dir /B *.iso
if %errorlevel% EQU 1 (echo. & echo no iso files could be found! & echo press any key to exit & pause >nul & exit) else (goto isoSel)
:isoSel
set isoSelection=
set /p isoSelection=Select ISO file: 
call %workDir%\src\getFileExt\getFileExt.bat
if /I %fileExtension% EQU .iso (goto reaskWIM3) else (echo This is not an iso file! & echo. & goto isoSel)
:reaskWIM3
set /p isoSecQu=Selected iso file is [%isoSelection%], is it correct? (Y/N): 
if /I %isoSecQu% == Y ( goto skpIsoReq )
if /I %isoSecQu% == N ( goto isoSel ) else ( echo. & echo Only Y and N can be used! & echo. & goto reaskWIM3 )
:skpIsoReq
echo.
echo ISO file will be renamed for automatic ISO creation, if not, you have to set the foldername later yourself or skip this process.
echo Let the file beeing renamed or skip?
echo    Y: Yes (Rename and create ISO)
echo    N: No (Skip rename and ISO creation)
echo    S: Skip (Don't create an ISO)
set /p isoCreate=(Y/N/S): 
if /I %isoCreate% EQU N (set renIso=0 & goto skipIsoCre) else (timeout 0 >nul /nobreak)
if /I %isoCreate% EQU Y (set renIso=1 & goto renameISO) else (timeout 0 >nul /nobreak)
if /I %isoCreate% EQU S (set renIso=2 & goto skipIsoCre) else (goto errIsoCreate)
:renameISO
rename %isoSelection% WINDOWS.ISO
set isoSelection=WINDOWS.ISO
:skipIsoCre

REM ///Extracting image file...\\\
set file=%ExctractionDir%
FOR /F "delims=" %%i IN ("%file%") DO (
set driveLetter=%%~di
)
echo.
echo Copying image, this may take a while...
echo.
if exist %ExctractionDir%\%isoSelection% (goto skipCopy & echo File already in directory, skipping copy process...) 
copy %isoSelection% %ExctractionDir%
:skipCopy
%driveLetter%
cd %ExctractionDir%
mkdir Extracted
cd Extracted
if %OS% EQU 64BIT ( goto 7z64 )
if %OS% EQU 32BIT ( goto 7z86 ) else ( goto err7z )
if exist %ExctractionDir%\Extracted ( rmdir %ExctractionDir%\Extracted /S /Q )
if exist %ExctractionDir%\*.iso ( del %ExctractionDir%\*.iso /F /Q)

:7z64
%workDir%\src\7zip\x64\7z.exe x "%ExctractionDir%\%isoSelection%"
goto strtMnt

:7z86
%workDir%\src\7zip\x32\7z.exe x "%ExctractionDir%\%isoSelection%"
goto strtMnt

REM ///Directory for mounting the image...\\\
:strtMnt
echo Prompting for mounting directory...
echo.
:wrongMntDir
for /f "delims=" %%A in ('%workDir%\src\folderbrowse\folderbrowse.exe "Select the directory where the image gets mounted:"') do set "MountDir=%%A"
if /I %MountDir% EQU \ (echo Select a directory!! & goto :wrongMntDir)
echo Selected directory: %MountDir%
:reaskWIM5
set /p MntdirRequ=Is the slected directory correct? (Y/N): 
if /I %MntdirRequ% EQU Y (goto contMnt)
if /I %MntdirRequ% EQU N (goto wrongMntDir) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM5)
:contMnt

REM ///Listing available images in the wim/esd file...\\\
:errorInstallfileBACK
if exist %ExctractionDir%\Extracted\sources\install.wim (goto dismWIM)
if exist %ExctractionDir%\Extracted\sources\install.esd (goto dismESD) else (goto errorInstallfile)
:dismWIM
echo.
SETLOCAL
set file=%ExctractionDir%
FOR /F "delims=" %%i IN ("%file%") DO (
set driveLetterWIM=%%~di
)
%driveLetterWIM%
cd %ExctractionDir%\Extracted\sources
%workDir%\src\dism\dism.exe /Get-ImageInfo /ImageFile:install.wim
echo.
:indexSelWIM
set INDEX=
set /p INDEX=Select index: 
:reaskWIM6
set /p indexSecQu=Selected index [%INDEX%], is it correct? (Y/N): 
if /I %indexSecQu% EQU Y (goto extImgWIM)
if /I %indexSecQu% EQU N (goto indexSelWIM) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM6)

:dismESD
echo.
SETLOCAL
set file=%ExctractionDir%
FOR /F "delims=" %%i IN ("%file%") DO (
set driveLetterESD=%%~di
)
%driveLetterESD%
cd %ExctractionDir%\Extracted\sources
%workDir%\src\dism\dism.exe /Get-ImageInfo /ImageFile:install.esd
echo.
:indexSelESD
set INDEX=
set /p INDEX=Select index: 
:reaskWIM7
set /p indexSecQu=Selected index [%INDEX%], is it correct? (Y/N): 
if /I %indexSecQu% EQU Y (goto extImgESD)
if /I %indexSecQu% EQU N (goto indexSelESD) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM7)

REM ///Mounting extracted image...\\\
:extImgWIM
%workDir%\src\dism\dism.exe /Mount-Image /ImageFile:install.wim /Index:%INDEX% /MountDir:%MountDir%
if %errorlevel% GTR 1 (goto errorMnt) else (goto sucMnt)
echo.
:sucMnt
echo Success The image is successfully exported and mounted, you can edit the image now, but ONLY with administrative permissions!
echo.
:secBack
echo When you are done editing, press any key... & pause >nul
:reaskWIM8
set /p endEdit=Are you done editing? (Y/N): 
if /I %endEdit% EQU Y (goto securityQuestion)
if %endEdit% EQU N (goto secBack & echo.) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM8)
:securityQuestion
:reaskWIM9
set /p securityQuestionVar=Are you really done editing [safety question]? (Y/N): 
if /I %securityQuestionVar% EQU Y (goto unmountWIM & echo.)
if /I %securityQuestionVar% EQU N (goto secBack) else (echo. & echo Only Y and N can be used! & echo. & goto reaskWIM9)

REM ///Unmounting the image and saving or discharding changes...\\\
:unmountWIM
echo Want to save changes to the image?
echo    S: Save changes
echo    D: discard changes
set /p saveDisc=(S/D): 
if /I %saveDisc% EQU S (goto saveChange)
if /I %saveDisc% EQU D (goto discardChange) else (goto helpDISMWIM)
:saveChange
%workDir%\src\dism\dism.exe /Commit-Image /MountDir:%MountDir% /CheckIntegrity /append
%workDir%\src\dism\dism.exe /Unmount-Image /MountDir:%MountDir% /discard
%workDir%\src\dism\dism.exe /Delete-Image /ImageFile:install.wim /Index:%INDEX%
cd.. & cd..
goto isoCreCheck

:discardChange
%workDir%\src\dism\dism.exe /Unmount-Image /MountDir:%MountDir% /discard
goto isoCreCheck

REM ///Creating ISO file from folder...\\\
:isoCreCheck
if %renIso% EQU 1 ( echo Creating ISO file from folder with image and export image to input image directory... )
if %renIso% EQU 0 (goto cleanUpWIM)
if %renIso% EQU 2 (goto cleanUpWIM)
set /p imgLabel=Label for the Image:  
%workDir%\src\oscdimg\oscdimg.exe -nt -m -b%ExctractionDir%\Extracted\boot\etfsboot.com %ExctractionDir%\Extracted "%ImageDir%\%imgLabel%.iso"
if %errorlevel% NEQ 1 (echo Iso was saved to [%ImageDir%]. & timeout 2 >nul /nobreak & goto cleanUpWIM) else (echo. & echo Error, see message above for more information. Press any key to start Imgburn... & pause & exit)


REM ///Prompting for cleanup...\\\
:cleanUpWIM
echo.
set /p WClean=Want to clean up the extraction? (Y/N): 
if /I %WClean% EQU Y ( goto cleanExt )
if /I %WClean% EQU N ( goto exitScript ) 
:cleanExt
echo Cleaning up behind me...
rmdir %ExctractionDir%\Extracted /S /Q
rmdir %ExctractionDir%\Extracted\sources /S /Q
del %ExctractionDir%\*.iso /F /Q >nul
if %errorlevel% GEQ 1 (echo Error, couldn't delete directory, you have to do this yourself! & timeout 2 >nul) else (goto exitScript)
exit
:exitScript
echo Thanks for using this tool :)
timeout 2 >nul
exit

REM ///Exporting selected image...\\\
:extImgESD
echo Extracting slected edition from [ESD], this can take a long time...
echo.
%workDir%\src\dism\dism.exe /Export-Image /SourceImageFile:install.esd /SourceIndex:%INDEX% /DestinationImageFile:install.wim /Compress:Max /CheckIntegrity
if %errorlevel% GTR 1 (goto errorExport)

REM ///Mounting extracted image...\\\
echo.
%workDir%\src\dism\dism.exe /Mount-Image /ImageFile:install.wim /Index:1 /MountDir:%MountDir%
if %errorlevel% GTR 1 (goto errorMnt) else (goto sucMntESD)
echo.
:sucMntESD
echo Success! The image is successfully exported and mounted, you can edit the image now, but ONLY with administrative permissions!
echo.
:secBackESD
echo When you are done editing, press any key... & pause >nul
:reaskESD1
set /p endEdit=Are you done editing? (Y/N): 
if /I %endEdit% EQU Y (goto securityQuestionESD)
if %endEdit% EQU N (goto secBack & echo.) else (echo. & echo Only Y and N can be used! & echo. & goto reasESD1)
:securityQuestionESD
:reaskESD2
set /p securityQuestionVar=Are you really done editing [safety question]? (Y/N): 
if /I %securityQuestionVar% EQU Y (goto unmountESD & echo.)
if /I %securityQuestionVar% EQU N (goto secBackESD) else (echo. & echo Only Y and N can be used! & echo. & goto reaskESD2)

REM ///Unmounting the image and saving or discharding changes...\\\
:unmountESD
echo Want to save changes to the image?
echo    S: Save changes
echo    D: discard changes
set /p saveDisc=(S/D): 
if /I %saveDisc% EQU S (goto saveChangeESD)
if /I %saveDisc% EQU D (goto discardChangeESD) else (goto helpDISMESD)
:saveChangeESD
%workDir%\src\dism\dism.exe /Commit-Image /MountDir:%MountDir% /CheckIntegrity /append
%workDir%\src\dism\dism.exe /Unmount-Image /MountDir:%MountDir% /discard
%workDir%\src\dism\dism.exe /Delete-Image /ImageFile:install.wim /Index:%INDEX%
%workDir%\src\dism\dism.exe /Export-Image /SourceImageFile:install.wim /SourceIndex:1 /DestinationImageFile:install.esd
timeout 1 >nul
del install.wim
cd.. & cd..
goto isoCreCheckESD

:discardChangeESD
%workDir%\src\dism\dism.exe /Unmount-Image /MountDir:%MountDir% /discard
%workDir%\src\dism\dism.exe /Export-Image /SourceImageFile:install.wim /SourceIndex:1 /DestinationImageFile:install.esd
timeout 3 >nul
del install.wim
goto isoCreCheckESD

REM ///Creating ISO file from folder...\\\
:isoCreCheckESD
if %renIso% EQU 1 ( echo Creating ISO file from folder with image and export image to input image directory... )
if %renIso% EQU 0 (goto cleanUpESD)
if %renIso% EQU 2 (goto cleanUpESD)
set /p imgLabel=Label for the Image:  
%workDir%\src\oscdimg\oscdimg.exe -nt -m -b%workDir%\src\oscdimg\etfsboot.com %ExctractionDir%\Extracted "%ImageDir%\%imgLabel%"
if %errorlevel% NEQ 1 (echo Iso was saved to [%ImageDir%]. & timeout 1 >nul /nobreak & goto cleanUpESD) else (echo. & pause & goto errIsoCreate)

REM ///Prompting for cleanup...\\\
:cleanUpESD
echo.
set /p WClean=Want to clean up the extraction? (Y/N): 
if /I %WClean% EQU Y ( goto cleanExtESD )
if /I %WClean% EQU N ( goto exitScriptESD ) 
:cleanExtESD
echo Cleaning up behind me...
rmdir %ExctractionDir%\Extracted /S /Q
rmdir %ExctractionDir%\Extracted\sources /S /Q
del %ExctractionDir%\*.iso /F /Q >nul
if %errorlevel% GEQ 1 (echo Error, couldn't delete directory, does it still exist? & timeout 2 >nul) else (goto exitScriptESD)
exit
:exitScriptESD
echo Thanks for using this tool :) & timeout 2 >nul
exit

REM ///Help and error stuff...\\\
:errorInstallfile
echo Install file couldn't be found, maybe it has a different name then install.*? If so, rename it to install AND KEEP THE FILE EXTENSION!!!
pause >nul & echo press any key to return...
goto errorInstallfileBACK

:errorExport
echo Image couldn't be exportet, maybe the file is corrupted?
echo press any key to exit and cleanup... & pause >nul
echo.
set /p WClean=Want to clean up the extraction? (Y/N): 
if /I %WClean% EQU Y ( goto cleanExtERR )
if /I %WClean% EQU N ( goto exitScriptERR ) 
:cleanExtERR
echo Cleaning up behind me...
rmdir %ExctractionDir%\Extracted /S
if %errorlevel% GEQ 1 (echo Error, couldn't delete directory, you have to do this yourself! & timeout 2 >nul)
exit
:exitScriptERR
echo leaving...
timeout 1 >nul
exit

:errIsoCreate
echo Iso couldn't be created, see above message for details, starting ImgBurn...
start "%workDir%\src\imgBurn\ImgBurn.exe" /MODE BUILD & echo press any key to exit (if you have selected automatic cleanup, this won't work here, you have to do it yourself later!) & pause >nul
exit

:errorMnt
echo Image couldn't be mounted, see DISM output log for more information!
echo press any key to exit and cleanup... & pause >nul
echo.
set /p WClean=Want to clean up the extraction? (Y/N): 
if /I %WClean% EQU Y ( goto cleanExtERRMnt )
if /I %WClean% EQU N ( goto exitScriptERRMnt ) 
:cleanExtERRMnt
echo Cleaning up behind me...
rmdir %ExctractionDir%\Extracted /S
if %errorlevel% GEQ 1 (echo Error, couldn't delete directory, you have to do this yourself! & timeout 2 >nul)
exit
:exitScriptERRMnt
echo leaving...
timeout 1 >nul
exit

:helpDISMWIM
echo You can ONLY use S vor saving changes or D for discarding changes!
echo press any key to return... & pause >nul
goto unmountWIM

:helpDISMESD
echo You can ONLY use S vor saving changes or D for discarding changes!
echo press any key to return... & pause >nul
goto unmountESD

:err7z
echo Error, the specific 7z.exe and 7z.dll aren't existing for this type of windows!
echo ARM64 editions aren't implemented yet!
echo.
echo press any key to exit... & pause

:errFileExt
echo.
echo Error: File must be an  *.iso, please select an Iso file!
timeout 2 >nul
goto isoSel