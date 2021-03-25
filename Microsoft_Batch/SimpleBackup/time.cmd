REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Param_1: Function_To_Be_Called
REM Param_2: Function_Param_1
REM Param_3: Function_Param_2
REM Param_4: Function_Param_3
REM Param_5: Function_Param_4
CALL %1 %2 %3 %4 %5
EXIT /B 0

REM Param_1: Time 1 of type %TIME%
REM Param_2: Time 2
REM Param_3: Result in some unit I haven´t decided yet.
:calculateTimeDifference
ECHO 1
SETLOCAL
ECHO 2
SET /a tmp1=10
ECHO 3
ENDLOCAL&Set _result=%tmp1%
ECHO 4
EXIT /B 0

REM Time formatting tips: https://ss64.com/nt/time.html
REM From: https://ss64.com/nt/syntax-gettime.html
:getCurrentTime
SETLOCAL
REM FOR /F "TOKENS=3" %%D IN ('REG QUERY ^"HKEY_CURRENT_USER\Control Panel\International^" /v iCountry ^| find ^"REG_SZ^"') DO (
REM         SET _country_code=%%D)
REM Echo Country Code %_country_code%

REM FOR /F "TOKENS=3" %%D IN ('REG QUERY ^"HKEY_CURRENT_USER\Control Panel\International^" /v sTime ^| find ^"REG_SZ^"') DO (
REM         SET _time_sep=%%D)
REM Echo Separator %_time_sep%

REM FOR /F "TOKENS=3" %%D IN ('REG QUERY ^"HKEY_CURRENT_USER\Control Panel\International^" /v sTimeFormat ^| find ^"REG_SZ^"') DO (
REM         SET _time_format=%%D)
REM Echo Format %_time_format%

FOR /f "tokens=1-3 delims=1234567890 " %%a IN ("%time%") DO SET "delims=%%a%%b%%c"
FOR /f "tokens=1-4 delims=%delims%" %%G IN ("%time%") DO (
  SET _hh=%%G
  SET _min=%%H
  SET _ss=%%I
  SET _ms=%%J
)
:: Strip any leading spaces
SET _hh=%_hh: =%

:: Ensure the hours have a leading zero
IF 1%_hh% LSS 20 SET _hh=0%_hh%

REM SETLOCAL enabledelayedexpansion
REM SET vartmpvar="test"
REM SETLOCAL disabledelayedexpansion & SET _vartmpvar=%vartmpvar%
REM echo _vartmpvar: %_vartmpvar%

Echo The time is:   %_hh%:%_min%:%_ss%
REM ENDLOCAL&Set only seems to work if delayedexpansion IS NOT USED.
REM As soon as delayedexpansion has been used in the function the solution below results in an empt _time variable.
ENDLOCAL&Set _time=%_hh%:%_min%
EXIT /B 0