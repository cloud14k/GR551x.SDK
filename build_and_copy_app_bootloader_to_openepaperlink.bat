@echo off
setlocal

rem Build Goodix GR551x SDK app_bootloader and copy the generated HEX into
rem the local OpenEPaperLink GR5xxx DFU directory.

set "SDK_ROOT=%~dp0"
set "BOOTLOADER_DIR=%SDK_ROOT%projects\ble\dfu\app_bootloader"
set "KEIL_PROJECT=%BOOTLOADER_DIR%\Keil_5\app_bootloader.uvprojx"
set "KEIL_TARGET=GRxx_Soc"
set "UV4=C:\Keil_v5\UV4\UV4.exe"
set "ARMCC_BIN=C:\Keil_v5\ARM\ARMCC\Bin"

rem Default destination is the sibling OpenEPaperLink checkout.
set "DEST_HEX=%SDK_ROOT%..\OpenEPaperLink\ARM_Tag_FW\Tag_FW_GR5xxx\dfu\bl-gr5515.hex"

if not "%~1"=="" (
    set "DEST_HEX=%~1"
)

if not exist "%UV4%" (
    echo Error: Keil UV4.exe not found: %UV4%
    exit /b 1
)

if not exist "%KEIL_PROJECT%" (
    echo Error: bootloader Keil project not found:
    echo   %KEIL_PROJECT%
    exit /b 1
)

set "PATH=%ARMCC_BIN%;%PATH%"

pushd "%BOOTLOADER_DIR%\Keil_5"
echo ===== Build GR551x app_bootloader =====
"%UV4%" -b "%KEIL_PROJECT%" -t "%KEIL_TARGET%" -o "%BOOTLOADER_DIR%\Keil_5\build_bootloader.log"
if errorlevel 1 (
    echo Error: bootloader build failed. See:
    echo   %BOOTLOADER_DIR%\Keil_5\build_bootloader.log
    popd
    exit /b 1
)
popd

rem Keil writes the fresh HEX to Keil_5\Objects. The build\ copy may be stale.
set "SRC_HEX=%BOOTLOADER_DIR%\Keil_5\Objects\app_bootloader.hex"
if not exist "%SRC_HEX%" (
    set "SRC_HEX=%BOOTLOADER_DIR%\build\app_bootloader.hex"
)

if not exist "%SRC_HEX%" (
    echo Error: built bootloader HEX not found.
    echo Tried:
    echo   %BOOTLOADER_DIR%\build\app_bootloader.hex
    echo   %BOOTLOADER_DIR%\Keil_5\Objects\app_bootloader.hex
    exit /b 1
)

for %%I in ("%DEST_HEX%") do (
    if not exist "%%~dpI" (
        echo Error: destination directory does not exist:
        echo   %%~dpI
        exit /b 1
    )
)

copy /Y "%SRC_HEX%" "%DEST_HEX%" >nul
if errorlevel 1 (
    echo Error: copy failed.
    exit /b 1
)

if not "%SRC_HEX%"=="%BOOTLOADER_DIR%\build\app_bootloader.hex" (
    if not exist "%BOOTLOADER_DIR%\build" mkdir "%BOOTLOADER_DIR%\build"
    copy /Y "%SRC_HEX%" "%BOOTLOADER_DIR%\build\app_bootloader.hex" >nul
)

echo.
echo Build and copy complete.
echo Source:
echo   %SRC_HEX%
echo Destination:
echo   %DEST_HEX%
echo.
echo Source timestamp:
for %%I in ("%SRC_HEX%") do echo   %%~tI  %%~zI bytes
echo Destination timestamp:
for %%I in ("%DEST_HEX%") do echo   %%~tI  %%~zI bytes
echo.
echo Next step in OpenEPaperLink dfu directory:
echo   flash_5515_i0nd.bat

endlocal
