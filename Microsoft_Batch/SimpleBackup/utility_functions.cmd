@echo off
REM Version and Github_upload date: 1.0 (05-12-2020)
REM Author/Developer: Søren Madsen
REM Github url: https://github.com/MrSmadsen/Development/tree/main/Microsoft_Batch/SimpleBackup
REM Desciption: This is a Microsoft Batch script to automate backup and archive functionality
REM             provided by standard archiving programs such as 7zip.
REM             It has been developed for my personal setup and my own use case.
REM Documentation: Checkout the file: Howto_Description.pdf
REM Test_Disclaimer: This script has been tested on: Microsoft Windows 10 64bit home (Danish).
REM                  Feel free to use this script/software at your own risk.
REM File Encoding: utf-8

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Param_1: Function_To_Be_Called
REM Param_2: Function_Param_1
REM Param_3: Function_Param_2
REM Param_4: Function_Param_3
REM Param_5: Function_Param_4
CALL %1 %2 %3 %4 %5
EXIT /B 0

:reset_errorlevel
REM Echoes the windows version to device nul. This should work without error and without output hence setting errorlevel to 0.
REM STDERR is still being sent to stderr output to know is something weird with ver happens.
ver > nul
EXIT /B 0

REM If running as elevated admin, member of local and/or domain admin groups. Set relevant variables to NO/YES
:is_cmd_running_with_admin_priviligies_using_whoami
CALL :reset_errorlevel
SET varElevatedAdminPriviligies=NO
whoami /groups | find "S-1-16-12288" > nul 2>&1
IF %ERRORLEVEL%==0 (
  SET varElevatedAdminPriviligies=YES
) ELSE IF %ERRORLEVEL%==1 (
  SET varElevatedAdminPriviligies=NO
) ELSE (
  CALL :Exception_End "%varTargetLogFile%" "Unhandled exception in function :is_cmd_running_with_admin_priviligies_using_whoami - Elevations_Part" "OUTPUT_TO_STDOUT" "OUTPUT_DEBUG"
)

CALL :reset_errorlevel
SET varUserInLocalAdministratorsGroup=NO
whoami /groups | find "S-1-5-32-544" > nul 2>&1
IF %ERRORLEVEL%==0 (
  SET varUserInLocalAdministratorsGroup=YES
) ELSE IF %ERRORLEVEL%==1 (
  SET varUserInLocalAdministratorsGroup=NO
) ELSE (
  CALL :Exception_End "%varTargetLogFile%" "Unhandled exception in function :is_cmd_running_with_admin_priviligies_using_whoami - Local Admin Part" "OUTPUT_TO_STDOUT" "OUTPUT_DEBUG"
)

CALL :reset_errorlevel
SET varUserInDomainAdministratorsGroup=NO
whoami /groups | find "-512" > nul 2>&1
IF %ERRORLEVEL%==0 (
  SET varUserInDomainAdministratorsGroup=YES
) ELSE IF %ERRORLEVEL%==1 (
  SET varUserInDomainAdministratorsGroup=NO
) ELSE (
  CALL :Exception_End "%varTargetLogFile%" "Unhandled exception in function :is_cmd_running_with_admin_priviligies_using_whoami - Domain Admin Part" "OUTPUT_TO_STDOUT" "OUTPUT_DEBUG"
)
CALL :reset_errorlevel
EXIT /B 0

REM This function tries to setup a windows services.msc service as requested by the params:
REM Param_1: Service name
REM PAram_2: Service mode
:set_windows_msc_service_start_mode
IF [%1]==[] (
  echo Error: No service name provided. Exitting function.
  EXIT /B 1
)
  
IF [%2]==[] (
  echo Error: No start mode provided. Exitting function.
  EXIT /B 1
)

echo Param1_Unmodified: %1   -   Param_1_No_Brackets: %~1
echo Param2_Unmodified: %2   -   Param_2_No_Brackets: %~2

sc config %~1 start= %~2
EXIT /B 0

REM This function tries to start a windows services.msc service as requested by the param:
REM Param_1: Service name
:start_windows_msc_service
IF [%1]==[] (
  echo Error: No service name provided. Exitting function.
  EXIT /B 1
)

echo Param1_Unmodified: %1   -   Param_1_No_Brackets: %~1

REM VisualSVN Background Job Service
sc start %~1
EXIT /B 0

REM This function tries to stop a windows services.msc service as requested by the param:
REM Param_1: Service name
:stop_windows_msc_service
IF [%1]==[] (
  echo Error: No service name provided. Exitting function.
  EXIT /B 1
)

echo Param1_Unmodified: %1   -   Param_1_No_Brackets: %~1

REM VisualSVN Background Job Service
sc stop %~1
EXIT /B 0

REM Param_1: Path to settingsfile.
:readBackupSettingsFile
IF EXIST "%~1" (
  ECHO Read settings from file: %~1
  REM You should only use a relative path to the settingsfile. Paths with spaces in them will probably fail.
  FOR /f "eol=# tokens=1,2 delims==" %%i in (%~1) do (
    SET %%i=%%j
    
    IF ["%%j"]==[""] (
      ECHO Empty variable found in file: %~1.
      ECHO Please enter a configuration value in variable: %%i.
      CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "" "" ""
    )
  )
) ELSE (
    ECHO Settings file %~1 does not exist.
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "" "" ""
)
EXIT /B 0

REM Exits the script and writes the error message provided.
REM Param_1: FileHandle
REM Param_2: Message
REM Param_3: OUTPUT_TO_STDOUT  -  The function will also echo the message to stdout.
REM Param_4: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Exception_End
SET varLogToSTDOUTOK=NOT_DEFINED

CALL ..\logging :Append_NewLine_To_LogFile "%~1" "%~3" "%~4"
CALL ..\logging :Append_To_LogFile "%~1" "Exception caught." "OUTPUT_TO_STDOUT" "%~4"
CALL ..\logging :Append_To_LogFile "%~1" "%~2" "%~3" "%~4"
CALL ..\logging :Append_NewLine_To_LogFile "%~1" "%~3" "%~4"

CALL :Cleanup
CALL ..\logging :Append_To_LogFile "%~1" "Exitting." "OUTPUT_TO_STDOUT" "%~4"
CALL ..\logging :Append_NewLine_To_LogFile "%~1" "%~3" "%~4"
PAUSE
EXIT

REM If this function is enabled with SET varCleanupEnabled=CLEANUP_ENABLED or SET varCleanupEnabled=CLEANUP_ASK
REM the folder defined in variable varTargetBackupfolder is deleted.
:Cleanup
IF EXIST "%varTargetBackupfolder%" (
  CALL ..\logging :Append_NewLine

  IF "%varCleanupEnabled%"=="CLEANUP_ENABLED" (
    rmdir /Q /S "%varTargetBackupfolder%"
    ECHO CLEANUP_ENABLED: Deleted folder %varTargetBackupfolder%
  )
  IF "%varCleanupEnabled%"=="CLEANUP_ASK" (
    rmdir /S "%varTargetBackupfolder%"
    ECHO CLEANUP_ASK: Deleted folder %varTargetBackupfolder%
  )
)
EXIT /B 0
