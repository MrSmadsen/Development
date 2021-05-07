@echo off
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
REM Param_6: Function_Param_5
CALL %1 %2 %3 %4 %5 %6
EXIT /B 0

REM Just a dummy function that does nothing.
REM Always try to structure your logic to avoid using this function. It can be used for testing while developing,
REM but the finished algorithm should not use this function if it can be avoided.
:do_nothing
REM start at 1, steps by 1, until 2.
for /l %%x IN (1,1,2) do (
  REM Jump back to Callee.
  EXIT /B 0
  echo User should never see this on the console.
)

REM Alternetively
REM IF 0==1 (
REM   echo do everything!
REM )
EXIT /B 0

:reset_errorlevel
REM Echoes the windows version to device nul. This should work without error and without output hence setting errorlevel to 0.
REM STDERR is still being sent to stderr output to know is something weird with ver happens.
ver > nul
EXIT /B 0

REM If running as elevated admin, member of local and/or domain admin groups. Set relevant variables to NO/YES
:is_cmd_running_with_admin_priviligies_using_whoami
CALL :reset_errorlevel
SET "varElevatedAdminPriviligies=NO"
whoami /groups | find "S-1-16-12288" > nul 2>&1
IF "%ERRORLEVEL%"=="0" (
  SET "varElevatedAdminPriviligies=YES"
) ELSE IF "%ERRORLEVEL%"=="1" (
  SET "varElevatedAdminPriviligies=NO"
) ELSE (
  CALL :Exception_End "%varTargetLogFile%" "Unhandled exception in function :is_cmd_running_with_admin_priviligies_using_whoami - Elevations_Part" "OUTPUT_TO_STDOUT" "OUTPUT_DEBUG"
)

CALL :reset_errorlevel
SET "varUserInLocalAdministratorsGroup=NO"
whoami /groups | find "S-1-5-32-544" > nul 2>&1
IF "%ERRORLEVEL%"=="0" (
  SET "varUserInLocalAdministratorsGroup=YES"
) ELSE IF "%ERRORLEVEL%"=="1" (
  SET "varUserInLocalAdministratorsGroup=NO"
) ELSE (
  CALL :Exception_End "%varTargetLogFile%" "Unhandled exception in function :is_cmd_running_with_admin_priviligies_using_whoami - Local Admin Part" "OUTPUT_TO_STDOUT" "OUTPUT_DEBUG"
)

CALL :reset_errorlevel
SET "varUserInDomainAdministratorsGroup=NO"
whoami /groups | find "-512" > nul 2>&1
IF "%ERRORLEVEL%"=="0" (
  SET "varUserInDomainAdministratorsGroup=YES"
) ELSE IF "%ERRORLEVEL%"=="1" (
  SET "varUserInDomainAdministratorsGroup=NO"
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

REM Param_1: Config mode. (NO (Default) | SleepOff | HibernationOff | SleepAndHibernationOff)
:windows_powercfg_DisablePowerDown
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_DisablePowerDown - Param_1: No config mode supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_DisablePowerDown - Param_1: Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
IF "%~1"=="NO" (
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
) ELSE IF "%~1"=="SleepOff" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Disabling Windows Sleep Mode. Setting timeouts -standby-timeout-ac and -standby-timeout-dc to 0 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -standby-timeout-ac 0
  powercfg -change -standby-timeout-dc 0
) ELSE IF "%~1"=="HibernationOff" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Disabling Windows Hibernation Mode. Setting timeouts -hibernate-timeout-ac and -hibernate-timeout-dc to 0 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -hibernate-timeout-ac 0
  powercfg -change -hibernate-timeout-dc 0
) ELSE IF "%~1"=="SleepAndHibernationOff" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Disabling Windows Sleep Mode. Setting timeouts -standby-timeout-ac and -standby-timeout-dc to 0 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -standby-timeout-ac 0
  powercfg -change -standby-timeout-dc 0
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Disabling Windows Hibernation Mode. Setting timeouts -hibernate-timeout-ac and -hibernate-timeout-dc to 0 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -hibernate-timeout-ac 0
  powercfg -change -hibernate-timeout-dc 0
) ELSE (
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_DisablePowerDown - Unsupported value detected. Value: %~1. Exit" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Param_1: Config mode. (NO (Default) | SleepOff | HibernationOff | SleepAndHibernationOff)
REM https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/powercfg-command-line-options
REM Param_2: varSleepTimeout. Sleep timeout in minutes. 0 = Turned off.
REM Param_3: varHibernationTimeout. Hibernation timeout in minutes. 0 = Turned off.
REM Param_4: varSleepTimeoutBattery. Sleep timeout in minutes on battery. 0 = Turned off.
REM Param_5: varHibernationTimeoutBattery. Hibernation timeout in minutes on battery. 0 = Turned off.
:windows_powercfg_EnablePowerDown
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - No config mode supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_2: No Sleep timeout supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_2: Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_3: No Hibernation timeout supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_3: Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_4: No Sleep timeout (battery) supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_4: Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%5]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_5: No Hibernation timeout (battery) supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%5]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Param_5: Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
IF "%~1"=="NO" (
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
) ELSE IF "%~1"=="SleepOff" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Enabling Windows Sleep Mode. Setting -standby-timeout-ac to %~2 minutes and -standby-timeout-dc to %~4 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -standby-timeout-ac %~2
  powercfg -change -standby-timeout-dc %~4
) ELSE IF "%~1"=="HibernationOff" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Enabling Windows Hibernation Mode. Setting -hibernate-timeout-ac to %~3 minutes and -hibernate-timeout-dc to %~5 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -hibernate-timeout-ac %~3
  powercfg -change -hibernate-timeout-dc %~5
) ELSE IF "%~1"=="SleepAndHibernationOff" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Enabling Windows Sleep Mode. Setting -standby-timeout-ac to %~2 minutes and -standby-timeout-dc to %~4 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -standby-timeout-ac %~2
  powercfg -change -standby-timeout-dc %~4
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Enabling Windows Hibernation Mode. Setting -hibernate-timeout-ac to %~3 minutes and -hibernate-timeout-dc to %~5 minutes" "OUTPUT_TO_STDOUT" ""
  powercfg -change -hibernate-timeout-ac %~3
  powercfg -change -hibernate-timeout-dc %~5
) ELSE (
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  CALL :Exception_End "%varTargetLogFile%" ":windows_powercfg_EnablePowerDown - Unsupported value detected. Value: %~1. Exit" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Param_1: Path to logFile.
REM Param_2: Name of the command to start.
:logTimeStampB4CommandStart
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampBeforeCommandStart - No path supplied to the logfile. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampBeforeCommandStart - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampBeforeCommandStart - Parameter 2 command/function name missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampBeforeCommandStart - Parameter 2 command/function name missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)

REM ECHO param_1 %~1
REM ECHO param_2 %~2

SET "varDate=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%"
SET "varDate=%varDate: =0%"

..\logging :Append_NewLine_To_LogFile "%~1" "OUTPUT_TO_STDOUT" ""
..\logging :Append_To_LogFile "%~1" "%~2 started at: %varDate%." "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Param_1: Path to logFile.
REM Param_2: Name of the command to start.
:logTimeStamp_CommandFinished
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampWhenCommandIsFinished - No path supplied to the logfile. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampWhenCommandIsFinished - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampWhenCommandIsFinished - Parameter 2 command/function name missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":logTimeStampWhenCommandIsFinished - Parameter 2 command/function name missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)

SET "varDate=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%"
SET "varDate=%varDate: =0%"

..\logging :Append_NewLine_To_LogFile "%~1" "OUTPUT_TO_STDOUT" ""
..\logging :Append_To_LogFile "%~1" "%~2 finished at: %varDate%." "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Param_1: Path to settingsfile.
:readBackupSettingsFile_Limits
IF NOT EXIST "%~f1" (
  CALL :Exception_End "%varTargetLogFile%" "Settings file %~f1 does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

ECHO Retriving limit values from file: %~f1
REM If the path argument %~1 in FOR /F is encapsulated in "" the for loop will tokenize the filename and not the file contents.
REM Therefore the relative path is used instead of the absolute path %~f1 to avoid problems with spaces.
FOR /f "eol=# tokens=1,2 delims==" %%i in (%~1) do (
  IF ["%%j"]==[""] (
    CALL :Exception_End "%varTargetLogFile%" "Empty variable found in file: %~f1. Exit." "OUTPUT_TO_STDOUT" ""
  )
  REM Only requirement for these variables is (currently) to NOT be empty.
  REM An improvement would be to validate the value as a digit number.
  IF "%%i"=="varFileNameLength" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "1-255"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  )
  IF "%%i"=="varFolderLength" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "1-255"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  )
  IF "%%i"=="varPathLength" (
    REM https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-fscc/ffb795f3-027d-4a3c-997d-3085f2332f6f
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "3-32760"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  )
)
EXIT /B 0

REM Param_1: Path to settingsfile.
:readBackupSettingsFile
IF NOT EXIST "%~f1" (
  CALL :Exception_End "%varTargetLogFile%" "Settings file %~f1 does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

IF "%~1"=="..\Settings.ini" (
  CALL ..\utility_functions :readBackupSettingsFile_Limits "%~1"
)

SET /a "varUnvalidatedParametersCounter=0"

ECHO Read settings from file: %~f1
REM If the path argument %~1 in FOR /F is encapsulated in "" the for loop will tokenize the filename and not the file contents.
REM Therefore the relative path is used instead of the absolute path %~f1 to avoid problems with spaces.
FOR /f "eol=# tokens=1,2 delims==" %%i in (%~1) do (
  IF ["%%j"]==[""] (
    CALL :Exception_End "%varTargetLogFile%" ":readBackupSettingsFile. Empty variable found in file: %~f1. Exit." "OUTPUT_TO_STDOUT" ""
  )
  
  REM The counters must be initialized outside this functions scope to work properly.
  REM They are initialized to 0 in Multiple_Backups.cmd and BackupFolders.cmd.
  REM Increment counters.
  Rem This incrementation also includes the 3 values explicitly set in function: :readBackupSettingsFile_Limits
  IF "%~1"=="..\Settings.ini" (    
    SET /a "varGeneralSettingsRetrieved+=1"
  )
  IF "%~1"=="BackupSettings.ini" (
    SET /a "varBackupSettingsRetrieved+=1"
  )

  IF "%%i"=="varBackupLocation" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSyncFolderLocation" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varExistingArchivePath" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varExtractionLocation" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSrcPathFolder01" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSrcPathFolder02" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varDstPathFolder01" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varDstPathFolder02" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSimpleBackupCheckoutPath" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varRepositoryLocation" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varRepositoryDumpLocation" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSvnPath" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSvnadminPath" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varArchiveProgram" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varRasperryPi3BPlusSha512Path" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varSvnWorkingCopy01" (
    CALL :strLength "%%j" %varPathLength% "YES" ""
    CALL ..\filesystem :CheckIfParamIsFileSystemPath_RegEx "%%j" "YES" "varCheck" "EXCEPTION_ON_ERR_YES"
    CALL ..\fileSystem :NormalizeFilePath "%%j\." "%%i"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
  ) ELSE IF "%%i"=="varAppFunctionBackupFiles" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varAppFunctionIntegrityCheck" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varAppFunctionUpdateArchive" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varAppFunctionExtractFilestoFolder" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varAppFunctionExtractFilesWithFullFilePath" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varAppFunctionValidateChecksum" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varPassword" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSplitArchiveFile" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varEnableFileLogging" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varGenerateSfxArchive" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varMoveFolders" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varMoveFoldersBack" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varZipUtcMode" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varIntegrityTest" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varChecksumValidation" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varCheckWorkingCopyChanges" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varExportSvn" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSolidMode" (    
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varDeleteOldBackupFolders" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varEnableDebugLoggingOutput" (
    CALL ..\ParameterValidation.cmd :validateParameter_YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varOverWriteFiles" (
    CALL ..\ParameterValidation.cmd :validateParameter_WriteMode "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varAppFunctionSyncBackupFolder" (
    CALL ..\ParameterValidation.cmd :validate_YES_PURGE_DST-YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varBackupSynchronization" (
    CALL ..\ParameterValidation.cmd :validate_YES_PURGE_DST-YES-NO "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSplitVolumesize" (
    CALL ..\ParameterValidation.cmd :validateParameter_SplitVolumesize "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varCompressionLvl" (
    CALL ..\ParameterValidation.cmd :validateParameter_SplitCompressionLvl "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varFormat" (
    CALL ..\ParameterValidation.cmd :validateParameter_Format "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSyncFolder_DCOPY_FLAGS" (
    CALL ..\ParameterValidation.cmd :validateParameter_COPY_FLAGS "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSyncFolder_COPY_FLAGS" (
    CALL ..\ParameterValidation.cmd :validateParameter_COPY_FLAGS "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varMoveFolder_DCOPY_FLAGS" (
    CALL ..\ParameterValidation.cmd :validateParameter_COPY_FLAGS "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varMoveFolder_COPY_FLAGS" (
    CALL ..\ParameterValidation.cmd :validateParameter_COPY_FLAGS "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varCopyFolder_DCOPY_FLAGS" (
    CALL ..\ParameterValidation.cmd :validateParameter_COPY_FLAGS "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varCopyFolder_COPY_FLAGS" (
    CALL ..\ParameterValidation.cmd :validateParameter_COPY_FLAGS "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varChecksumBitlength" (
    CALL ..\ParameterValidation.cmd :validateParameter_ChecksumBitlength "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varShutdownDeviceWhenDone" (
    CALL ..\ParameterValidation.cmd :validateParameter_ShutdownDeviceWhenDone "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varTemporarilyDisablePowerDown" (
    CALL ..\ParameterValidation.cmd :validateParameter_TemporarilyDisablePowerDown "%~1" "%%j" "%%i"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varFileList" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varUpdateMode" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSecretPassword" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varThreadAffinity" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"   
  ) ELSE IF "%%i"=="varExistingArchiveFileName" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varExistingChecksumFile" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSvnRepo1" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSvnRepo2" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varOutputFormat" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varCodePage" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "1-99999"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varFileNameLength" (
    REM This variable is already handled and counterIncremented in function: :readBackupSettingsFile_Limits
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varFolderLength" (
    REM This variable is already handled and counterIncremented in function: :readBackupSettingsFile_Limits
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varPathLength" (
    REM This variable is already handled and counterIncremented in function: :readBackupSettingsFile_Limits
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSleepTimeout" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "0-300"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varHibernationTimeout" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "0-300"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varSleepTimeoutBattery" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "0-300"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varHibernationTimeoutBattery" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "0-300"
    CALL ..\ParameterValidation.cmd :incrementValidationCounters "%~1"
    SET "%%i=%%j"
  ) ELSE (
    SET /a "varUnvalidatedParametersCounter+=1"
    ECHO UNVERIFIED PARAMETER: %%i in file %~1.
    SET "%%i=%%j"
  )
  
  IF %varUnvalidatedParametersCounter% GTR 0 (
   CALL :Exception_End "%varTargetLogFile%" ":readBackupSettingsFile - No of unvalidated parameters is %varUnvalidatedParametersCounter%. Exit" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varEnableDebugLoggingOutput%"=="YES" (
    ECHO [DEBUG: ..utility_functions ReadSettingsFile] Value: %%j
  )
)
EXIT /B 0

REM Param_1: Path to Version.info file.
:readVersionInfo
IF NOT EXIST "%~f1" (
  CALL :Exception_End "%varTargetLogFile%" "File %~f1 does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

SET /a "varUnvalidatedVersionParametersCounter=0"

ECHO Read settings from file: %~f1
REM If the path argument %~1 in FOR /F is encapsulated in "" the for loop will tokenize the filename and not the file contents.
REM Therefore the relative path is used instead of the absolute path %~f1 to avoid problems with spaces.
FOR /f "eol=# tokens=1,2 delims==" %%i in (%~1) do (
  IF ["%%j"]==[""] (
    CALL :Exception_End "%varTargetLogFile%" ":readVersionInfo. Empty variable found in file: %~f1. Exit." "OUTPUT_TO_STDOUT" ""
  )
  
  REM The counters must be initialized outside this functions scope to work properly.
  REM They are initialized to 0 in Multiple_Backups.cmd and BackupFolders.cmd.
  REM Increment counters.
  SET /a "varVersionParametersCounter+=1"
  IF "%%i"=="varMayorVersion" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "1-9999"
    CALL ..\ParameterValidation.cmd :incrementVersionInfoCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varMinorVersion" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "1-12"
    CALL ..\ParameterValidation.cmd :incrementVersionInfoCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varRevisionNumber" (
    CALL ..\ParameterValidation.cmd :validateParameter_NumericRange "%~1" "%%j" "%%i" "1-2147483647"
    CALL ..\ParameterValidation.cmd :incrementVersionInfoCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varReleaseVersion" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementVersionInfoCounters "%~1"
    SET "%%i=%%j"
  ) ELSE IF "%%i"=="varLastChangedAuthor" (
    REM Only requirement for this variable is (currently) to NOT be empty.
    CALL ..\ParameterValidation.cmd :incrementVersionInfoCounters "%~1"
    SET "%%i=%%j"
  ) ELSE (
    SET /a "varUnvalidatedVersionParametersCounter+=1"
    ECHO UNVERIFIED PARAMETER: %%i in file %~1.
    SET "%%i=%%j"
  )
  
  IF %varUnvalidatedVersionParametersCounter% GTR 0 (
   CALL :Exception_End "%varTargetLogFile%" ":readVersionInfo - No of unvalidated parameters is %varUnvalidatedParametersCounter%. Exit" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varEnableDebugLoggingOutput%"=="YES" (
    ECHO [DEBUG: ..utility_functions readVersionInfo] Value: %%j
  )
)
EXIT /B 0

REM Inspiration from: https://ss64.com/nt/syntax-strlen.html
REM Default cmd.exe only supports 8192 characters on the commandline. So Max string lenght is aprox 8k.
REM Cmd.exe might crash if bigger strings are supplied to the function.
REM Param_1 The string which require length calculation.
REM Param_2 Max_Length allowed. 
REM Param_3 Exception on error.
REM Param_4: Verbose_Mode - "V"
:strLength
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_1 No value supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_1 Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_2 No value supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_2 Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

IF [%3]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_3 No value supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_3 Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

Setlocal EnableDelayedExpansion
Set "s=#%~1"
Set "len=0"
For %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
  if "!s:~%%N,1!" neq "" (
    set /a "len+=%%N"
    set "s=!s:~%%N!"
  )
)

IF !len! gtr %~2 (
  ECHO Param_1 value:      %~1
  ECHO Calculated length:  !len!
  ECHO Max_Length allowed: %~2
  IF "%~3"=="YES" ( 
    ECHO :strLength - Calculated length !len! exceeds Max_Length of %~2. Exit.
    PAUSE
    EXIT 1
  )
)

IF "%~4"=="V" ( ECHO Calculated length !len! exceeds Max_Length of %~2. Return to caller. )
IF "%~4"=="v" ( ECHO Calculated length !len! exceeds Max_Length of %~2. Return to caller. )
Setlocal DisableDelayedExpansion
EXIT /B 0

REM Inspiration from: https://ss64.com/nt/syntax-strlen.html
REM Functionality: The function is meant to work as follows:
REM Default cmd.exe only supports 8192 characters on the commandline. So Max string lenght is aprox 8k.
REM Cmd.exe might crash if bigger strings are supplied to the function.
REM If "Calculated length" Condition "Length Limitation" ( OK ) ELSE ( NOT OK )
REM Param_1 The string which require length calculation.
REM Param_2 Condition. If condition is not met return errorlevel 1. If condition is met return 0.
REM EQU : Equal, NEQ : Not equal, LSS : Less than <, LEQ : Less than or Equal <=, GTR : Greater than >, GEQ : Greater than or equal >=
REM Param_3 Length Limitation
REM Param_4: Verbose_Mode - "V"
:strLengthConditionalCheck
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_1 No value supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_1 Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_2 No value supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_2 Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

IF [%3]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_3 No value supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":strLength - Param_3 Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

Setlocal EnableDelayedExpansion
Set "s=#%~1"
Set "len=0"
For %%N in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
  if "!s:~%%N,1!" neq "" (
    set /a "len+=%%N"
    set "s=!s:~%%N!"
  )
)

REM EQU : Equal, NEQ : Not equal, LSS : Less than <, LEQ : Less than or Equal <=, GTR : Greater than >, GEQ : Greater than or equal >=
REM If "Calculated length" Condition "Length Limitation" ( OK ) ELSE ( NOT OK )
IF !len! %~2 %~3 (
  IF "%~4"=="V" (
    ECHO !len! %~2 %~3 evaluated to: OK.
  )
  IF "%~4"=="v" (
    ECHO !len! %~2 %~3 evaluated to: OK.
  )
) ELSE (
  IF "%~4"=="V" (
    ECHO !len! %~2 %~3 evaluated to: NOT OK.
  )
  IF "%~4"=="v" (
    ECHO !len! %~2 %~3 evaluated to: NOT OK.
  )
  
  CALL :Exception_End "%varTargetLogFile%" ":strLengthConditionalCheck - Calculated length !len! exceeds Max_Length of %~2. Exit." "OUTPUT_TO_STDOUT" ""
)

Setlocal DisableDelayedExpansion
EXIT /B 0

REM This function consists of 2 functions - :strLength2 and :CheckNextLetter.
REM I am trying to make a strlength calculation without using delayedexpansion to be able to return the value.
REM Default cmd.exe only supports 8192 characters on the commandline. So Max string lenght is aprox 8k.
REM Cmd.exe might crash if bigger strings are supplied to the function.
REM Param_1 The string which require length calculation.
REM Param_2 Return value.
:strLength2
SET "varStringToCount=%~1"
SET /A varStrLength2=0

IF "%varStringToCount:~4096%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~4096%"
  SET /A "varStrLength2+=4096"
)
IF "%varStringToCount:~2048%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~2048%"
  SET /A "varStrLength2+=2048"
)
IF "%varStringToCount:~1024%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~1024%"
  SET /A "varStrLength2+=1024"
)
IF "%varStringToCount:~512%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~512%"
  SET /A "varStrLength2+=512"
)
IF "%varStringToCount:~256%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~256%"
  SET /A "varStrLength2+=256"
)
IF "%varStringToCount:~128%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~128%"
  SET /A "varStrLength2+=128"
)
IF "%varStringToCount:~64%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~64%"
  SET /A "varStrLength2+=64"
)
IF "%varStringToCount:~32%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~32%"
  SET /A "varStrLength2+=32"
)
IF "%varStringToCount:~16%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~16%"
  SET /A "varStrLength2+=16"
)
IF "%varStringToCount:~8%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~8%"
  SET /A "varStrLength2+=8"
)
IF "%varStringToCount:~4%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~4%"
  SET /A "varStrLength2+=4"
)
IF "%varStringToCount:~2%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~2%"
  SET /A "varStrLength2+=2"
)
IF "%varStringToCount:~1%" NEQ "" (
  SET "varStringToCount=%varStringToCount:~1%"
  SET /A "varStrLength2+=1"
)
IF "%varStringToCount%" NEQ "" (  
  GOTO :CheckNextLetter "%varStringToCount%" "%~2"
) ELSE (
  REM ECHO There is %varStrLength2% character^(s^) in the string.
  EXIT /B 0
)

REM This function is a sub-function to :strLength2. 
:CheckNextLetter 
IF "%varStringToCount%" NEQ "" (
    SET varStringToCount=%varStringToCount:~1%
    SET /A varStrLength2=%varStrLength2%+1
    GOTO :CheckNextLetter
) ELSE (
    REM ECHO There is %varStrLength2% character^(s^) in the string.
    SET "%~2=%varStrLength2%"
    EXIT /B 0
)
REM ECHO There is %varStrLength2% character^(s^) in the string.
SET "%~2=%varStrLength2%"
EXIT /B 0

REM An example of hot to set the codepage without setting it each time a file is called.
REM This however relies on the output from chcp.exe always being 4 tokens wide and the last token is the codepage value.
:setCodePage
REM CODEPAGE___________________________________________________________________________________
REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
REM If the "logic" used in the codepage code fails use the simpel solution instead - chcp %varCodePage% > nul
REM The logic avoids setting the same chcp value each time a file is called.
REM chcp %varCodePage% > nul

REM Change to the codepage from Settings.ini.
IF DEFINED varCodePage (
  for /F "tokens=4 delims= " %%a in ('chcp') do (
    set varChcpResult=%%a
  )  
  ECHO %varChcpResult%
  IF NOT "%varChcpResult%"=="%varCodePage%" (  
    REM ECHO Setting codepage! a: "%varChcpResult%"  - "%varCodePage%"
    chcp %varCodePage% > nul
  )
)
REM ___________________________________________________________________________________________
EXIT /B 0

:shutdownDevice
REM If you change the timeout (/t seconds)) also remember to change the timeoutMessage to match the timeout.
SET "varShutdownDeviceTimeout=/t 120"
SET "varShutdownDeviceTimeoutMessage=2 minutes"

REM User message.
IF "%varShutdownDeviceWhenDone%"=="Hybrid" (
  SET "varshutdownDeviceMessage=SimpleBackup: You will be logged off in %varShutdownDeviceTimeoutMessage%. Please save your work now! Logoff mode: Shutdown (Hybrid mode)."
ELSE IF "%varShutdownDeviceWhenDone%"=="Hybrid_F" (
  SET "varshutdownDeviceMessage=SimpleBackup: You will be logged off in %varShutdownDeviceTimeoutMessage%. Please save your work now! Logoff mode: Shutdown (Hybrid_F mode)."
) ELSE (
  SET "varshutdownDeviceMessage=SimpleBackup: You will be logged off in %varShutdownDeviceTimeoutMessage%. Please save your work now! Logoff mode: %varShutdownDeviceWhenDone%."
)

REM (PowerOff | PowerOff_F | Hibernate | Restart | Restart_F | Hybrid | Hybrid_F)
IF "%varShutdownDeviceWhenDone%"=="PowerOff" (
  shutdown.exe /s %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"
) ELSE IF "%varShutdownDeviceWhenDone%"=="PowerOff_F" (
  shutdown.exe /s /f %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"
) ELSE IF "%varShutdownDeviceWhenDone%"=="Hibernate" (
  shutdown.exe /h /f %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"
) ELSE IF "%varShutdownDeviceWhenDone%"=="Restart" (
  shutdown.exe /r %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"
) ELSE IF "%varShutdownDeviceWhenDone%"=="Restart_F" (
  shutdown.exe /r /f %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"  
) ELSE IF "%varShutdownDeviceWhenDone%"=="Hybrid" (
  shutdown.exe /s /hybrid %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"
) ELSE IF "%varShutdownDeviceWhenDone%"=="Hybrid_F" (
  shutdown.exe /s /hybrid /f %varShutdownDeviceTimeout% /c "%varshutdownDeviceMessage%"
) ELSE (
  CALL :Exception_End "%varTargetLogFile%" ":shutdownDevice - Unsupported option chosen. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Return value
:CurrentTimeSimpleBackupFormat
SET "varCurrentTimeSimpleBackupFormat=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%"
SET "%~1=%varCurrentTimeSimpleBackupFormat: =0%"
EXIT /B 0

REM Exits the script and writes the error message provided.
REM Param_1: FileHandle
REM Param_2: Message
REM Param_3: OUTPUT_TO_STDOUT  -  The function will also echo the message to stdout.
REM Param_4: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Exception_End
SET "varLogToSTDOUTOK=NOT_DEFINED"

CALL ..\logging :Append_NewLine_To_LogFile "%~1" "%~3" "%~4"
CALL ..\logging :Append_To_LogFile "%~1" "Exception caught." "OUTPUT_TO_STDOUT" "%~4"
CALL ..\logging :Append_To_LogFile "%~1" "%~2" "%~3" "%~4"
CALL ..\logging :Append_NewLine_To_LogFile "%~1" "%~3" "%~4"

CALL :Cleanup "CLEANUP_DISABLED"
CALL ..\logging :Append_To_LogFile "%~1" "Exitting." "OUTPUT_TO_STDOUT" "%~4"
CALL ..\logging :Append_NewLine_To_LogFile "%~1" "%~3" "%~4"
PAUSE
EXIT

REM Param_1: SrcString. The string that requires to be validated.
REM Param_2: SearchPattern. This is the regular expression used as the string filter. Must be a valid findStr regular expression
REM          WITHOUT beginning char (^) and END char (&). This function will add those chars.
REM          Example: c:\    -    SET "varFilePathSearchString=c:\\.*". Then use findstr /i /r /c:"^%2$"
REM Param_3: Ignore case sensitivity? (IGNORE_CASE_SENSITIVITY_YES | IGNORE_CASE_SENSITIVITY_NO). Default is IGNORE_CASE_SENSITIVITY_YES.
REM Param_4: Returnvalue. Does the srcString match the searchPattern in Param_2. (YES | NO).
:ValidateString_RegEx
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - No srcString supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - No searchPattern supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - Empty searchPattern supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - No ignore case variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - Empty ignore case variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - No returnValue variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateString_RegEx - Empty returnValue variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

IF "%~3"=="IGNORE_CASE_SENSITIVITY_NO" (
  SET "varIgnoreCaseSensitivity= "
) ELSE (
  SET "varIgnoreCaseSensitivity=/i"
)

REM /R /C:"Search string" - This will perform a Regex match, but will also accept spaces in the search string. (https://ss64.com/nt/findstr.html)
echo %~1|findstr %varIgnoreCaseSensitivity% /r /c:"^%~2$">nul
IF "%ERRORLEVEL%"=="0" (
  SET "%~4=YES"
) ELSE (
  SET "%~4=NO"
)
EXIT /B 0

REM Param_1: SrcString. The string that requires to be validated.
REM Param_2: SearchPattern. This is the regular expression used as the string filter. Must be a valid findStr regular expression
REM          WITHOUT beginning char (^) and END char (&). This function will add those chars.
REM          Example: c:\    -    SET "varFilePathSearchString=c:\\.*". Then use findstr /i /r /c:"^%2$"
REM Param_3: Ignore case sensitivity? (IGNORE_CASE_SENSITIVITY_YES | IGNORE_CASE_SENSITIVITY_NO). Default is IGNORE_CASE_SENSITIVITY_YES.
REM Param_4: Returnvalue. Does the srcString match the searchPattern in Param_2. (YES | NO).
:ValidateNumeric_RegEx
IF [%1]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - No srcString supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - No searchPattern supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - Empty searchPattern supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - No ignore case variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - Empty ignore case variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - No returnValue variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[""] (
  CALL :Exception_End "%varTargetLogFile%" ":ValidateNumeric_RegEx - Empty returnValue variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

IF "%~3"=="IGNORE_CASE_SENSITIVITY_NO" (
  SET "varIgnoreCaseSensitivity= "
) ELSE (
  SET "varIgnoreCaseSensitivity=/i"
)

REM ECHO "%2"
REM ECHO "^%~2$"
REM ECHO "^^%~2$"
REM PAUSE

REM /R /C:"Search string" - This will perform a Regex match, but will also accept spaces in the search string. (https://ss64.com/nt/findstr.html)
echo %~1|findstr %varIgnoreCaseSensitivity% /r /c:"^%~2$">nul
IF "%ERRORLEVEL%"=="0" (
  SET "%~4=YES"
) ELSE (
  SET "%~4=NO"
)
EXIT /B 0

REM PARAM_1 Enable the cleanup function. Values: "CLEANUP_ENABLED", "CLEANUP_DISABLED" or "CLEANUP_ASK"
:Cleanup
IF EXIST "%varTargetBackupfolder%" (
  CALL ..\logging :Append_NewLine

  IF "%~1"=="CLEANUP_ENABLED" (
    rmdir /Q /S "%varTargetBackupfolder%"
    IF "%ERRORLEVEL%"=="0" (
      CALL ..\logging :Append_To_Screen "CLEANUP_ENABLED: Deleted folder %varTargetBackupfolder%" "OUTPUT_TO_STDOUT" ""
    )
  ) ELSE IF "%~1%"=="CLEANUP_DISABLED" (
      CALL ..\logging :Append_To_Screen "CLEANUP_DISABLED: No cleanup done." "OUTPUT_TO_STDOUT" ""
  ) ELSE IF "%~1%"=="CLEANUP_ASK" (
    CALL ..\logging :Append_To_Screen "Delete folder %varTargetBackupfolder%?" "OUTPUT_TO_STDOUT" ""
    rmdir /S "%varTargetBackupfolder%"
    IF "%ERRORLEVEL%"=="0" (
      CALL ..\logging :Append_To_Screen "CLEANUP_ASK: Cleanup done on folder %varTargetBackupfolder%." "OUTPUT_TO_STDOUT" ""
    )
  ) ELSE (
    CALL ..\logging :Append_To_Screen "CLEANUP: No cleanup done." "OUTPUT_TO_STDOUT" ""
  )
)
EXIT /B 0
