@ECHO OFF

set PYTHON=python

:: Determine the correct esptool command to use
where esptool >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "ESPTOOL_CMD=esptool"
) else (
    set "ESPTOOL_CMD=%PYTHON% -m esptool"
)

goto GETOPTS
:HELP
echo Usage: %~nx0 [-h] [-p ESPTOOL_PORT] [-P PYTHON] [-f FILENAME^|FILENAME]
echo Flash image file to device, but first erasing and writing system information
echo.
echo     -h               Display this help and exit
echo     -p ESPTOOL_PORT  Set the environment variable for ESPTOOL_PORT.  If not set, ESPTOOL iterates all ports (Dangerrous).
echo     -P PYTHON        Specify alternate python interpreter to use to invoke esptool. (Default: %PYTHON%)
echo     -f FILENAME      The .bin file to flash.  Custom to your device type and region.
goto EOF

:GETOPTS
if /I "%1"=="-h" goto HELP
if /I "%1"=="--help" goto HELP
if /I "%1"=="-F" set "FILENAME=%2" & SHIFT
if /I "%1"=="-p" set ESPTOOL_PORT=%2 & SHIFT
if /I "%1"=="-P" set PYTHON=%2 & SHIFT
SHIFT
IF NOT "__%1__"=="____" goto GETOPTS

IF "__%FILENAME%__" == "____" (
    echo "Missing FILENAME"
    goto HELP
)
IF EXIST %FILENAME% IF x%FILENAME:update=%==x%FILENAME% (
    echo Trying to flash update %FILENAME%, but first erasing and writing system information"
    %ESPTOOL_CMD% --baud 115200 erase_flash
    %ESPTOOL_CMD% --baud 115200 write_flash 0x00 %FILENAME%
    
    @REM Account for S3 and C3 board's different OTA partition
    IF x%FILENAME:s3=%==x%FILENAME% IF x%FILENAME:v3=%==x%FILENAME% IF x%FILENAME:t-deck=%==x%FILENAME% IF x%FILENAME:wireless-paper=%==x%FILENAME% IF x%FILENAME:wireless-tracker=%==x%FILENAME% IF x%FILENAME:station-g2=%==x%FILENAME% IF x%FILENAME:unphone=%==x%FILENAME% (
        IF x%FILENAME:esp32c3=%==x%FILENAME% (
            %ESPTOOL_CMD% --baud 115200 write_flash 0x260000 bleota.bin
        ) else (
            %ESPTOOL_CMD% --baud 115200 write_flash 0x260000 bleota-c3.bin
        )
    ) else (
        %ESPTOOL_CMD% --baud 115200 write_flash 0x260000 bleota-s3.bin
    )
    for %%f in (littlefs-*.bin) do (
        %ESPTOOL_CMD% --baud 115200 write_flash 0x300000 %%f
    )
) else (
    echo "Invalid file: %FILENAME%"
    goto HELP
) else (
    echo "Invalid file: %FILENAME%"
    goto HELP
)

:EOF
