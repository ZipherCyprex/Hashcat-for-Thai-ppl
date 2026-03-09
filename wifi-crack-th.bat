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
set START_TIME=%time%
echo ===================================================
echo   HASHCAT WIFI CRACKER - THAI OPTIMIZED
echo   Target: %HASHFILE%
echo   Started: %date% %time%
echo ===================================================
echo.

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
:: FUNCTION: CHECK IF PASSWORD CRACKED
:: ===================================================
:check_cracked
:: Check with --show if password exists and has actual output
hashcat.exe -m 22000 --show %HASHFILE% > temp_result.txt 2>&1
set CHECK_OUTPUT=
for /f "delims=" %%i in (temp_result.txt) do set CHECK_OUTPUT=%%i

if not "!CHECK_OUTPUT!"=="" (
    findstr /C:":" temp_result.txt >nul 2>&1
    if !errorlevel! equ 0 (
        set END_TIME=%time%
        call :calculate_duration
        echo.
        echo ===================================================
        echo   PASSWORD FOUND - CRACKING SUCCESSFUL
        echo ===================================================
        echo.
        echo [RESULT] Password recovered:
        echo ------------------------------------------------
        type temp_result.txt
        echo ------------------------------------------------
        echo.
        echo ===================================================
        echo [SUCCESS] Password saved to hashcat.potfile
        echo [TIME] Total duration: !DURATION!
        echo [STARTED] %START_TIME%
        echo [FINISHED] %END_TIME%
        echo ===================================================
        echo.
        del temp_result.txt >nul 2>&1
        pause
        exit /b 0
    )
)
del temp_result.txt >nul 2>&1
goto :eof

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

:: ===================================================
:: CHECK IF ALREADY CRACKED
:: ===================================================
echo [*] Checking if password already cracked...
hashcat.exe -m 22000 --show %HASHFILE% > temp_check.txt 2>&1
set /p CHECK_RESULT=<temp_check.txt

if not "!CHECK_RESULT!"=="" (
    findstr /C:":" temp_check.txt >nul 2>&1
    if !errorlevel! equ 0 (
        echo.
        echo ===================================================
        echo   PASSWORD ALREADY CRACKED (Found in potfile)
        echo ===================================================
        echo.
        echo [RESULT] Password recovered:
        echo ------------------------------------------------
        type temp_check.txt
        echo ------------------------------------------------
        echo.
        echo [INFO] This hash was cracked in a previous session
        echo [INFO] No need to run cracking again
        echo.
        del temp_check.txt >nul 2>&1
        pause
        exit /b 0
    )
)
del temp_check.txt >nul 2>&1
echo [+] No previous results found - starting cracking sequence...
echo.

:: ===================================================
:: PHASE 1: DICTIONARY ATTACK (ROCKYOU)
:: ===================================================
echo.
echo ===================================================
echo PHASE 1: Dictionary Attack (rockyou.txt)
echo Priority: CRITICAL [*****]
echo ===================================================
echo [*] Testing common passwords from rockyou.txt wordlist
echo [*] Fastest method - catches weak/common passwords
echo [*] Attack Mode: Straight dictionary (-a 0)
echo [*] Estimated Time: 1-5 minutes (14M+ passwords)
echo.
if exist rockyou.txt (
    echo [*] Running Phase 1... (This may take 1-5 minutes)
    hashcat.exe -m 22000 -a 0 -O -w 4 --quiet --status --status-timer=15 %HASHFILE% rockyou.txt
    echo.
    call :check_cracked
) else (
    echo [!] rockyou.txt not found - skipping this phase
    echo [!] Download from: https://github.com/brannondorsey/naive-hashcat/releases
    echo.
)

:: ===================================================
:: PHASE 2: DICTIONARY + BEST64 RULES
:: ===================================================
echo.
echo ===================================================
echo PHASE 2: Dictionary + best64 Rules
echo Priority: CRITICAL [*****]
echo ===================================================
echo [*] Testing dictionary with mutations (case changes, leet speak, suffixes)
echo [*] Examples: Password123, admin@2024, Welcome!, p@ssw0rd
echo [*] Attack Mode: Dictionary with rules (-a 0 -r)
echo [*] Estimated Time: 5-15 minutes (14M x 64 rules = 896M+ combinations)
echo.
if exist rockyou.txt (
    if exist rules\best64.rule (
        echo [*] Running Phase 2... (This may take 5-15 minutes)
        hashcat.exe -m 22000 -a 0 -O -w 4 --quiet --status --status-timer=15 %HASHFILE% rockyou.txt -r rules\best64.rule
        echo.
        call :check_cracked
    ) else (
        echo [!] rules\best64.rule not found - skipping this phase
        echo [!] Usually located in hashcat installation: hashcat\rules\best64.rule
        echo.
    )
) else (
    echo [!] rockyou.txt not found - skipping this phase
    echo.
)

:: ===================================================
:: PHASE 3: THAI BIRTHDATE PATTERNS (DDMMYYYY)
:: ===================================================
echo.
echo ===================================================
echo PHASE 3: Birthdate Patterns (DDMMYYYY)
echo Priority: HIGH [****]
echo ===================================================
echo [*] Testing birthdate patterns in Thai and Western formats
echo [*] Buddhist Era (B.E.): 2500-2599 (1957-2056 CE)
echo [*] Christian Era (C.E.): 1900-1999, 2000-2099
echo [*] Examples: 01012540, 15062550, 25121990, 01012000
echo [*] Attack Mode: Mask attack with year patterns (-a 3)
echo [*] Keyspace: 4 year ranges x ~3,650 dates = ~14,600 combinations per range
echo [*] Estimated Time: 5-10 minutes
echo.
if not exist birthdate_patterns.txt (
    echo [*] Creating birthdate_patterns.txt...
    (
        echo ?d?d?d?d25?d?d
        echo ?d?d?d?d26?d?d
        echo ?d?d?d?d19?d?d
        echo ?d?d?d?d20?d?d
    ) > birthdate_patterns.txt
)
echo [*] Running Phase 3... (This may take 5-10 minutes)
hashcat.exe -m 22000 -a 3 -O -w 4 --quiet --status --status-timer=15 %HASHFILE% birthdate_patterns.txt
echo.
call :check_cracked

:: ===================================================
:: PHASE 4: 8-DIGIT NUMBERS
:: ===================================================
echo.
echo ===================================================
echo PHASE 4: 8-Digit Numbers (00000000-99999999)
echo Priority: HIGH [****]
echo ===================================================
echo [*] Testing all 8-digit numeric combinations
echo [*] Common for: Simple numeric passwords, partial phone numbers, dates
echo [*] Attack Mode: Mask attack (-a 3)
echo [*] Keyspace: 100,000,000 combinations
echo [*] Estimated Time: 10-30 minutes (depends on GPU)
echo.
echo [*] Running Phase 4... (This may take 10-30 minutes)
hashcat.exe -m 22000 -a 3 -O -w 4 --quiet --status --status-timer=15 %HASHFILE% ?d?d?d?d?d?d?d?d
echo.
call :check_cracked

:: ===================================================
:: PHASE 5: THAI MOBILE NUMBERS (10 DIGITS)
:: ===================================================
echo.
echo ===================================================
echo PHASE 5: Thai Mobile Numbers (10 digits)
echo Priority: HIGH [****]
echo ===================================================
echo [*] Testing Thai mobile phone number patterns
echo [*] Prefixes: 061-069, 080-099 (AIS, DTAC, TrueMove H, True)
echo [*] Examples: 0812345678, 0987654321, 0612345678
echo [*] Attack Mode: Mask attack with prefix file (-a 3)
echo [*] Keyspace: 29 prefixes x 10,000,000 = 290,000,000 combinations
echo [*] Estimated Time: 30-60 minutes (depends on GPU)
echo.
echo [*] Running Phase 5... (This may take 30-60 minutes)
hashcat.exe -m 22000 -a 3 -O -w 4 --quiet --status --status-timer=15 %HASHFILE% thaiprefix.txt
echo.
call :check_cracked

:: ===================================================
:: PHASE 6: 9-DIGIT NUMBERS (LAST RESORT)
:: ===================================================
echo.
echo ===================================================
echo PHASE 6: 9-Digit Numbers (000000000-999999999)
echo Priority: LOW [**]
echo ===================================================
echo [*] Testing all 9-digit numeric combinations
echo [*] Last resort - exhaustive brute force
echo [*] Attack Mode: Mask attack (-a 3)
echo [*] Keyspace: 1,000,000,000 combinations
echo [*] Estimated Time: 2-8 hours (depends on GPU)
echo [!] WARNING: This is extremely time-consuming
echo [!] Consider stopping if previous phases failed
echo.
echo [*] Running Phase 6... (This may take 2-8 hours - VERY SLOW)
hashcat.exe -m 22000 -a 3 -O -w 4 --quiet --status --status-timer=30 %HASHFILE% ?d?d?d?d?d?d?d?d?d
echo.
call :check_cracked

:: ===================================================
:: COMPLETION SUMMARY
:: ===================================================
set END_TIME=%time%
call :calculate_duration

echo.
echo ===================================================
echo      ALL CRACKING PHASES COMPLETED
echo ===================================================
echo.
echo [TIME] Total duration: %DURATION%
echo [STARTED] %START_TIME%
echo [FINISHED] %END_TIME%
echo.

:: Final check with --show
hashcat.exe -m 22000 --show %HASHFILE% > temp_final.txt 2>&1
set FINAL_OUTPUT=
for /f "delims=" %%i in (temp_final.txt) do set FINAL_OUTPUT=%%i

if not "!FINAL_OUTPUT!"=="" (
    findstr /C:":" temp_final.txt >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Password(s) found:
        echo ------------------------------------------------
        type temp_final.txt
        echo ------------------------------------------------
        echo.
        echo The password has been saved and can be used to connect to the network.
        del temp_final.txt >nul 2>&1
        goto end_script
    )
)

del temp_final.txt >nul 2>&1
echo [FAILED] No passwords found in any phase
echo.
echo Recommendations:
echo - Verify the handshake capture is valid (use aircrack-ng to check)
echo - Try additional wordlists (Thai-specific, custom dictionaries)
echo - Use more specific masks based on target information
echo - Consider combinator attacks (wordlist1 + wordlist2)
echo - Try additional rule files (dive.rule, rockyou-30000.rule)
echo - Increase attack complexity (hybrid attacks, longer masks)
echo.
echo Common issues:
echo - Weak/incomplete handshake capture
echo - Password uses special characters or mixed alphanumeric
echo - Password length exceeds 9 characters
echo - Password uses Thai language characters

:end_script
echo.
echo ===================================================
echo STATISTICS
echo ===================================================
hashcat.exe --show %HASHFILE% 2>nul
echo.
pause
