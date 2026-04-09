@echo off
setlocal enabledelayedexpansion
title Hashcat WiFi Cracker - Thai Optimized Edition

:: ===================================================
:: INPUT VALIDATION
:: ===================================================
if "%1"=="" (
    echo [ERROR] Please drag and drop your .hc22000 file onto this batch file
    echo.
    echo Usage: %0 ^<hashfile.hc22000^>
    echo.
    pause
    exit /b
)

set HASHFILE=%1

:: Check file extension for .cap or .pcap
set "FILENAME=%~nx1"
set "EXTENSION=%~x1"

if /i "%EXTENSION%"==".cap" goto wrong_format
if /i "%EXTENSION%"==".pcap" goto wrong_format
goto format_ok

:wrong_format
echo.
echo ===================================================
echo   WRONG FILE FORMAT DETECTED
echo ===================================================
echo.
echo [ERROR] You provided a %EXTENSION% file: %FILENAME%
echo [INFO] Hashcat requires .hc22000 format
echo.
echo Please convert your file first at:
echo https://hashcat.net/cap2hashcat/
echo.
set /p OPEN_URL="Open conversion website now? (Y/N): "
if /i "!OPEN_URL!"=="Y" (
    start https://hashcat.net/cap2hashcat/
)
echo.
echo Press any key to exit...
pause >nul
exit /b

:format_ok

:: Check if file exists
if not exist "%HASHFILE%" (
    echo.
    echo [ERROR] File not found: %HASHFILE%
    echo.
    pause
    exit /b
)

set START_TIME=%time%

:: ===================================================
:: SETTINGS MENU
:: ===================================================
echo.
echo ===================================================
echo   HASHCAT WIFI CRACKER - THAI OPTIMIZED
echo ===================================================
echo   Target: %HASHFILE%
echo ===================================================

:: ===================================================
:: SETTINGS MENU
:: ===================================================
echo ===================================================
echo   QUICK START OR SETTINGS?
echo ===================================================
echo.
echo [1] START    - Quick start (Auto GPU, Standard mode)
echo [2] SETTINGS - Customize device and attack level
echo.
echo ===================================================
set /p START_CHOICE="Your choice (1 or 2): "
echo ===================================================
echo.

if "%START_CHOICE%"=="2" goto custom_settings

:: Quick Start - Auto detect GPU, Level 2 (Standard)
echo [+] Quick start selected
echo [+] Auto detecting device...
echo [+] Attack level: STANDARD
echo.
timeout /t 2 /nobreak >nul
set ATTACK_LEVEL=2
set OPTIMIZE=-O
goto auto_detect

:custom_settings
echo.
:: ===================================================
:: DEVICE SELECTION
:: ===================================================
echo ===================================================
echo   STEP 1/2: SELECT DEVICE
echo ===================================================
echo.
echo [1] AUTO - Let the script choose (Recommended)
echo [2] GPU  - Force GPU only (Fast but needs GPU)
echo [3] CPU  - Force CPU only (Very slow, may not work)
echo.
echo ===================================================
set /p DEVICE_CHOICE="Your choice (1, 2, or 3): "
echo ===================================================
echo.

if "%DEVICE_CHOICE%"=="2" (
    set DEVICE_PARAM=-D 2
    set MANUAL_DEVICE=1
    set OPTIMIZE=-O
    echo [+] GPU mode selected
    echo.
    timeout /t 1 /nobreak >nul
) else if "%DEVICE_CHOICE%"=="3" (
    set DEVICE_PARAM=-D 1
    set MANUAL_DEVICE=1
    set OPTIMIZE=
    echo [+] CPU mode selected
    echo [!] WARNING: This is 10-100x slower than GPU
    echo [!] WARNING: May not work on some CPUs
    echo.
    timeout /t 2 /nobreak >nul
) else (
    set MANUAL_DEVICE=0
    set OPTIMIZE=-O
    echo [+] Auto detect selected
    echo.
    timeout /t 1 /nobreak >nul
)

echo.
:: ===================================================
:: ATTACK LEVEL SELECTION
:: ===================================================
echo ===================================================
echo   STEP 2/2: SELECT ATTACK LEVEL
echo ===================================================
echo.
echo [1] FAST     - Quick and common patterns only
echo     Phases: Dictionary, Birthdate, 8 digits, Thai mobile
echo     Time: 5-15 min (GPU) / 1-3 hours (CPU)
echo.
echo [2] STANDARD - Recommended for most cases
echo     Everything in FAST + Rules, 9-digit numbers
echo     Time: 30-60 min (GPU) / 4-10 hours (CPU)
echo.
echo [3] EXTENDED - More thorough, takes longer
echo     Everything in STANDARD + 10-digit numbers
echo     Time: 2-4 hours (GPU) / 1-2 days (CPU)
echo.
echo [4] EXTREME  - Maximum coverage, very slow
echo     Everything in EXTENDED + 11-12 digit numbers
echo     Time: 15-40 hours (GPU) / weeks (CPU)
echo.
echo ===================================================
set /p ATTACK_LEVEL="Your choice (1, 2, 3, or 4): "
echo ===================================================
echo.

if "%ATTACK_LEVEL%"=="1" (
    echo [+] FAST attack selected
    echo [+] Quick scan for common passwords
    echo.
    timeout /t 1 /nobreak >nul
) else if "%ATTACK_LEVEL%"=="2" (
    echo [+] STANDARD attack selected
    echo [+] Good choice for most passwords
    echo.
    timeout /t 1 /nobreak >nul
) else if "%ATTACK_LEVEL%"=="3" (
    echo [+] EXTENDED attack selected
    echo [!] This will take 2-4 hours on GPU
    echo.
    timeout /t 2 /nobreak >nul
) else if "%ATTACK_LEVEL%"=="4" (
    echo [+] EXTREME attack selected
    echo [!] WARNING: This will take 15-40 hours on GPU
    echo [!] WARNING: May take WEEKS on CPU
    echo.
    timeout /t 3 /nobreak >nul
) else (
    set ATTACK_LEVEL=2
    echo [+] Invalid choice, using STANDARD attack
    echo.
    timeout /t 1 /nobreak >nul
)

if "%MANUAL_DEVICE%"=="1" goto start_cracking

:auto_detect

:: ===================================================
:: AUTO DEVICE DETECTION
:: ===================================================
echo [*] Detecting available devices...
echo.

:: Get device info and save to temp file
hashcat.exe -I > temp_devices.txt 2>&1

:: Check for GPU (look for "Type" line containing "GPU")
findstr /C:"Type" temp_devices.txt | findstr /C:"GPU" >nul 2>&1
set GPU_FOUND=%errorlevel%

if %GPU_FOUND%==0 (
    set DEVICE_PARAM=-D 2
    set OPTIMIZE=-O
    echo ===================================================
    echo   AUTO-SELECTED: GPU MODE
    echo ===================================================
    echo.
    echo [+] GPU detected - Using GPU acceleration
    echo [+] This will be FAST (10-100x faster than CPU^)
    echo.
    echo [*] Device specifications:
    type temp_devices.txt | findstr /C:"Name" /C:"Type" /C:"Processor" /C:"Memory"
    echo.
) else (
    set DEVICE_PARAM=-D 1
    set OPTIMIZE=
    echo ===================================================
    echo   AUTO-SELECTED: CPU MODE
    echo ===================================================
    echo.
    echo [!] No GPU detected - Using CPU mode
    echo [!] WARNING: CPU mode is 10-100x slower than GPU
    echo [!] Some phases may take hours or days to complete
    echo.
)

:: Cleanup temp file
del temp_devices.txt >nul 2>&1

:: ===================================================
:: CREATE THAI MOBILE PREFIX FILE
:: ===================================================
if not exist thaiprefix.txt (
    echo [*] Creating thaiprefix.txt with Thai mobile patterns...
    (
        echo 099?d?d?d?d?d?d?d
        echo 098?d?d?d?d?d?d?d
        echo 097?d?d?d?d?d?d?d
        echo 096?d?d?d?d?d?d?d
        echo 095?d?d?d?d?d?d?d
        echo 094?d?d?d?d?d?d?d
        echo 093?d?d?d?d?d?d?d
        echo 092?d?d?d?d?d?d?d
        echo 091?d?d?d?d?d?d?d
        echo 090?d?d?d?d?d?d?d
        echo 089?d?d?d?d?d?d?d
        echo 088?d?d?d?d?d?d?d
        echo 087?d?d?d?d?d?d?d
        echo 086?d?d?d?d?d?d?d
        echo 085?d?d?d?d?d?d?d
        echo 084?d?d?d?d?d?d?d
        echo 083?d?d?d?d?d?d?d
        echo 082?d?d?d?d?d?d?d
        echo 081?d?d?d?d?d?d?d
        echo 080?d?d?d?d?d?d?d
        echo 069?d?d?d?d?d?d?d
        echo 068?d?d?d?d?d?d?d
        echo 067?d?d?d?d?d?d?d
        echo 066?d?d?d?d?d?d?d
        echo 065?d?d?d?d?d?d?d
        echo 064?d?d?d?d?d?d?d
        echo 063?d?d?d?d?d?d?d
        echo 062?d?d?d?d?d?d?d
        echo 061?d?d?d?d?d?d?d
    ) > thaiprefix.txt
    echo [+] File created successfully
    echo.
) else (
    echo [+] thaiprefix.txt ready
    echo.
)

:: ===================================================
:: START CRACKING SEQUENCE
:: ===================================================
goto start_cracking

:: ===================================================
:: FUNCTION: CALCULATE DURATION
:: ===================================================
:calculate_duration
set start_h=%START_TIME:~0,2%
set start_m=%START_TIME:~3,2%
set start_s=%START_TIME:~6,2%
set end_h=%END_TIME:~0,2%
set end_m=%END_TIME:~3,2%
set end_s=%END_TIME:~6,2%

:: Remove leading zeros
if "%start_h:~0,1%"=="0" set start_h=%start_h:~1%
if "%start_m:~0,1%"=="0" set start_m=%start_m:~1%
if "%start_s:~0,1%"=="0" set start_s=%start_s:~1%
if "%end_h:~0,1%"=="0" set end_h=%end_h:~1%
if "%end_m:~0,1%"=="0" set end_m=%end_m:~1%
if "%end_s:~0,1%"=="0" set end_s=%end_s:~1%

:: Handle empty values
if "%start_h%"=="" set start_h=0
if "%start_m%"=="" set start_m=0
if "%start_s%"=="" set start_s=0
if "%end_h%"=="" set end_h=0
if "%end_m%"=="" set end_m=0
if "%end_s%"=="" set end_s=0

:: Convert to seconds
set /a start_total=(%start_h%*3600)+(%start_m%*60)+%start_s%
set /a end_total=(%end_h%*3600)+(%end_m%*60)+%end_s%

:: Calculate difference
set /a duration_sec=%end_total%-%start_total%

:: Handle negative (crossed midnight)
if %duration_sec% lss 0 set /a duration_sec+=86400

:: Convert back to hours, minutes, seconds
set /a dur_h=%duration_sec%/3600
set /a dur_m=(%duration_sec%%%3600)/60
set /a dur_s=%duration_sec%%%60

set DURATION=%dur_h%h %dur_m%m %dur_s%s
goto :eof

:start_cracking
echo.
echo ===================================================
echo   STARTING CRACKING PROCESS
echo ===================================================
echo   Target: %HASHFILE%
echo   Started: %date% %time%
echo ===================================================
echo.
echo [*] Preparing attack files...
echo.

:: ===================================================
:: PHASE 1: DICTIONARY ATTACK (ROCKYOU)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 1/4: DICTIONARY ATTACK
echo ===================================================
echo [*] Testing common passwords from rockyou.txt
echo [*] This is the fastest method
echo [*] Estimated: 1-5 minutes
echo ===================================================
echo.
if exist rockyou.txt (
    echo [*] Running Phase 1...
    echo.
    echo ===================================================
    echo   KEYBOARD SHORTCUTS
    echo ===================================================
    echo   [S] = Show Status    [P] = Pause
    echo   [B] = Bypass Phase   [Q] = Quit
    echo ===================================================
    echo.
    hashcat.exe -m 22000 -a 0 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% rockyou.txt
    echo.
) else (
    echo [!] rockyou.txt not found - downloading...
    powershell -Command "Invoke-WebRequest -Uri 'https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt' -OutFile 'rockyou.txt'"
    if exist rockyou.txt (
        echo [+] Download complete
        echo [*] Running Phase 1...
        hashcat.exe -m 22000 -a 0 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% rockyou.txt
        echo.
    ) else (
        echo [!] Download failed - skipping
        echo.
    )
)



:: ===================================================
:: PHASE 2: THAI BIRTHDATE PATTERNS (DDMMYYYY)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 2/4: BIRTHDATE PATTERNS
echo ===================================================
echo [*] Testing Thai birthdate formats (DDMMYYYY)
echo [*] Buddhist Era: 2500-2599, Christian Era: 1900-2099
echo [*] Estimated: 5-10 minutes
echo ===================================================
echo.
if not exist birthdate_patterns.txt (
    (
        echo ?d?d?d?d25?d?d
        echo ?d?d?d?d26?d?d
        echo ?d?d?d?d19?d?d
        echo ?d?d?d?d20?d?d
    ) > birthdate_patterns.txt
)
echo [*] Running Phase 2...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% birthdate_patterns.txt
echo.

:: ===================================================
:: PHASE 3: 8-DIGIT NUMBERS
:: ===================================================
echo.
echo ===================================================
echo   PHASE 3/4: 8-DIGIT NUMBERS
echo ===================================================
echo [*] Testing 00000000 to 99999999
echo [*] Common for simple numeric passwords
echo [*] Estimated: 10-30 minutes
echo ===================================================
echo.
echo [*] Running Phase 3...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% ?d?d?d?d?d?d?d?d
echo.

:: ===================================================
:: PHASE 4: THAI MOBILE NUMBERS (10 DIGITS)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 4/4: THAI MOBILE NUMBERS
echo ===================================================
echo [*] Testing 10-digit Thai phone numbers
echo [*] Prefixes: 061-069, 080-099 (AIS, DTAC, True)
echo [*] Estimated: 30-60 minutes
echo ===================================================
echo.
echo [*] Running Phase 4...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% thaiprefix.txt
echo.

:: Check attack level for Phase 5 (best66 rules)
if "%ATTACK_LEVEL%"=="1" goto phase6

:: ===================================================
:: PHASE 5: DICTIONARY + BEST66 RULES
:: ===================================================
echo.
echo ===================================================
echo   PHASE 5/6: DICTIONARY WITH RULES
echo ===================================================
echo [*] Testing dictionary with advanced mutations
echo [*] Examples: Password123, admin@2024, p@ssw0rd
echo [*] Estimated: 30-60 minutes
echo ===================================================
echo.
if exist rockyou.txt (
    if exist rules\best66.rule (
        echo [*] Running Phase 5...
        echo.
        echo ===================================================
        echo   KEYBOARD SHORTCUTS
        echo ===================================================
        echo   [S] = Show Status    [P] = Pause
        echo   [B] = Bypass Phase   [Q] = Quit
        echo ===================================================
        echo.
        hashcat.exe -m 22000 -a 0 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% rockyou.txt -r rules\best66.rule
        echo.
    ) else (
        echo [!] rules\best66.rule not found - skipping
        echo.
    )
) else (
    echo [!] rockyou.txt not found - skipping
    echo.
)

:phase6

:: Check attack level for Phase 6 (9-digit)
if "%ATTACK_LEVEL%"=="1" goto completion_summary

:: ===================================================
:: PHASE 6: 9-DIGIT NUMBERS (LAST RESORT)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 6/6: 9-DIGIT NUMBERS
echo ===================================================
echo [*] Testing 000000000 to 999999999
echo [*] Last resort - exhaustive brute force
echo [*] Estimated: 2-8 hours
echo ===================================================
echo.
echo [*] Running Phase 6...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% ?d?d?d?d?d?d?d?d?d
echo.

:: Check attack level for extended phases
if "%ATTACK_LEVEL%"=="2" goto completion_summary

:: ===================================================
:: PHASE 7: 10-DIGIT NUMBERS (LEVEL 3+)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 7: 10-DIGIT NUMBERS (EXTENDED MODE)
echo ===================================================
echo [*] Testing 0000000000 to 9999999999
echo [*] Estimated: 20-80 hours
echo ===================================================
echo.
echo [*] Running Phase 7...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% ?d?d?d?d?d?d?d?d?d?d
echo.

if "%ATTACK_LEVEL%"=="3" goto completion_summary
echo [*] Running Phase 7...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% ?d?d?d?d?d?d?d?d?d?d
echo.

if "%ATTACK_LEVEL%"=="2" goto completion_summary

:: ===================================================
:: PHASE 8: 11-DIGIT NUMBERS (LEVEL 3)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 8: 11-DIGIT NUMBERS (EXTREME MODE)
echo ===================================================
echo [*] Testing 00000000000 to 99999999999
echo [*] Estimated: 8-33 days
echo ===================================================
echo.
echo [*] Running Phase 8...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% ?d?d?d?d?d?d?d?d?d?d?d
echo.

:: ===================================================
:: PHASE 9: 12-DIGIT NUMBERS (LEVEL 3)
:: ===================================================
echo.
echo ===================================================
echo   PHASE 9: 12-DIGIT NUMBERS (EXTREME MODE)
echo ===================================================
echo [*] Testing 000000000000 to 999999999999
echo [*] Estimated: 83-333 days
echo ===================================================
echo.
echo [*] Running Phase 9...
echo.
echo ===================================================
echo   KEYBOARD SHORTCUTS
echo ===================================================
echo   [S] = Show Status    [P] = Pause
echo   [B] = Bypass Phase   [Q] = Quit
echo ===================================================
echo.
hashcat.exe -m 22000 -a 3 %OPTIMIZE% -w 4 --quiet %DEVICE_PARAM% %HASHFILE% ?d?d?d?d?d?d?d?d?d?d?d?d
echo.

:: ===================================================
:: COMPLETION SUMMARY
:: ===================================================
:completion_summary
set END_TIME=%time%
call :calculate_duration

echo.
echo ===================================================
echo   ALL PHASES COMPLETED
echo ===================================================
echo.
echo [TIME] Duration: %DURATION%
echo [STARTED] %START_TIME%
echo [FINISHED] %END_TIME%
echo.
echo ===================================================
echo   CHECKING RESULTS...
echo ===================================================
echo.
hashcat.exe -m 22000 --show %HASHFILE%
echo.
echo ===================================================
echo   DONE - Press any key to exit
echo ===================================================
pause >nul
