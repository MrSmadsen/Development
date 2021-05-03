@echo off
REM Version 2.6 (Github_upload date:3th of May 2021)
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

REM Param_1: Path and fileName to the logfile to create on the filesystem.
REM Param_2: Verbose_Mode - "V"
:createLogFile
REM Create empty file.
IF "%varEnableFileLogging%"=="NO" (
  IF "%~2"=="V" ( ECHO Skipping file creation: varEnableFileLogging - %varEnableFileLogging%. )
  IF "%~2"=="v" ( ECHO Skipping file creation: varEnableFileLogging - %varEnableFileLogging%. )
) ELSE IF "%varEnableFileLogging%"=="YES" (
  REM This is done to avoid overwriting existing archive logfiles. Instead we append to the existing logfile if it is found.
  IF "%~2"=="v" ( ECHO :createLogFile existence check )
  IF EXIST "%~1" (
    IF "%~2"=="V" ( ECHO Using existing logfile: %~1. )
    IF "%~2"=="v" ( ECHO Using existing logfile: %~1. )
    CALL :Append_NewLine_To_LogFile "%~1" "" ""
    CALL :Append_NewLine_To_LogFile "%~1" "" ""
    CALL :Append_To_LogFile "%~1" "##########################################" "" ""
    CALL :Append_To_LogFile "%~1" "## %varDate%: %~1" "" ""
    CALL :Append_To_LogFile "%~1" "##########################################" "" ""
    EXIT /B 0
  )
  IF NOT EXIST "%~1" (
   CALL ..\fileSystem :createFile "%~1" "USE_EXISTING_FILE" "%~2"
  )
) ELSE (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "createLogfile: Unexpected error. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Write a newLine to STD_OUT.
:Append_NewLine
ECHO.
Exit /B 0

REM Messages for screen should be suppplied in "Message 1" brackets.
REM Param_1: Message
REM Param_2: OUTPUT_TO_STDOUT  -  The function will also echo the message to stdout.
REM Param_3: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Append_To_Screen
SET "varLogToSTDOUTOK=NOT_DEFINED"
IF ["%~1"]==[""] (
  IF ["%~3"]==["OUTPUT_DEBUG"] ECHO No message provided for STD_OUT.
  SET "varLogToSTDOUTOK=NO"
)
IF "%varLogToSTDOUTOK%"=="NOT_DEFINED" IF ["%~2"]==["OUTPUT_TO_STDOUT"] (
  SET "varLogToSTDOUTOK=YES"
)

REM if %1 has double quotes around it, %~1 will strip the quote signs.
REM "%~1" ensures we always echo to a quoted filePath.
IF "%varLogToSTDOUTOK%"=="YES"  (
  ECHO %~1
)
Exit /B 0

REM Messages for screen should be suppplied in "Message 1" brackets.
REM Param_1: Message
REM Param_2: OUTPUT_TO_STDOUT  -  The function will also echo the message to stdout.
REM Param_3: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Append_To_Screen_With_TimeStamp
CALL ..\utility_functions :CurrentTimeSimpleBackupFormat "varAppend_To_Screen_With_TimeStamp_CurrentTime"
REM ECHO :Append_To_Screen_With_TimeStamp_Time: %varAppend_To_Screen_With_TimeStamp_CurrentTime%
CALL :Append_To_Screen "[%varAppend_To_Screen_With_TimeStamp_CurrentTime%]: %~1" "%~2" "%~3"
Exit /B 0

REM Param_1: FileHandle
REM Param_2: OUTPUT_TO_STDOUT  - The function will also echo the 'New_Line' to stdout.
REM Param_3: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Append_NewLine_To_LogFile
SET "varLogToFileOK=NOT_DEFINED"
IF [%1]==[] (
  SET "varLogToFileOK=NO"
  IF ["%~3"]==["OUTPUT_DEBUG"] ECHO LogFile has not been defined yet.
)
REM Empty parameters in the parameter lists are bad. Batch seems to shift the parameters if an empty slot is found.
REM Instead use a dummy parameter that do not exist if logToFile is not wanted.
IF [%1]==[""] (
  SET "varLogToFileOK=NO"
  IF ["%~3"]==["OUTPUT_DEBUG"] ECHO LogFile has not been defined yet.
)
IF not exist "%~1" (
  SET "varLogToFileOK=NO"
  IF ["%~3"]==["OUTPUT_DEBUG"] ECHO LogFile does not exist.
)
IF ["%~2"]==["OUTPUT_TO_STDOUT"] (
  SET "varLogToSTDOUTOK=YES"
) ELSE (
  SET "varLogToSTDOUTOK=NO"
)

REM If we haven't read the settings ini-file we haven't declared the variable varEnableFileLogging.
IF "%varBackupSettingsFileRead%"=="NO" (
  SET "varEnableFileLogging=NO"
)

IF "%varLogToFileOK%"=="NOT_DEFINED" (
  IF "%varEnableFileLogging%"=="NO" (
    SET "varLogToFileOK=NO"
  ) ELSE IF "%varEnableFileLogging%"=="YES" (
    SET "varLogToFileOK=YES"
  ) ELSE (
    SET "varLogToFileOK=NO"
    ECHO varEnableLogging is configured incorrectly, varEnableFileLogging: %varEnableFileLogging%.
  )
)

REM if %1 has double quotes around it, %~1 will strip the quote signs.
REM "%~1" ensures we always echo to a quoted filePath.
IF "%varLogToSTDOUTOK%"=="YES" ECHO.
IF "%varLogToFileOK%"=="YES"   ECHO.>>"%~1"
Exit /B 0

REM Messages for logfile Should be suppplied in "Message 1" brackets.
REM ECHO Message >> File    This will append to the file.
REM ECHO Message >  File    This will overwrite content in the file. (From current cursor position?).
REM Param_1: FileHandle
REM Param_2: Message
REM Param_3: OUTPUT_TO_STDOUT  -  The function will also echo the message to stdout.
REM Param_4: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Append_To_LogFile
SET "varLogToFileOK=NOT_DEFINED"
SET "varLogToSTDOUTOK=NOT_DEFINED"

IF [%1]==[] (
  IF ["%~4"]==["OUTPUT_DEBUG"] ECHO LogFile has not been defined yet. Message not logged to file.
  SET "varLogToFileOK=NO"
)
REM Empty parameters in the parameter lists are bad. Batch seems to shift the parameters if an empty slot is found.
REM Instead use a dummy parameter that do not exist if logToFile is not wanted.
IF [%1]==[""] (
  IF ["%~4"]==["OUTPUT_DEBUG"] ECHO LogFile has not been defined yet. Message not logged to file.
  SET "varLogToFileOK=NO"
)
IF not exist "%~1" (
  IF ["%~4"]==["OUTPUT_DEBUG"] ECHO LogFile does not exist. Message not logged.
  SET "varLogToFileOK=NO"
)
IF [%2]==[] (
  IF ["%~4"]==["OUTPUT_DEBUG"] ECHO No message provided for logfile or STD_OUT.
  SET "varLogToFileOK=NO"
  SET "varLogToSTDOUTOK=NO"
)
IF [%2]==[""] (
  IF ["%~4"]==["OUTPUT_DEBUG"] ECHO No message provided for logfile or STD_OUT.
  SET "varLogToFileOK=NO"
  SET "varLogToSTDOUTOK=NO"
)

REM If we haven't read the settings ini-file we haven't declared the variable varEnableFileLogging.
IF "%varBackupSettingsFileRead%"=="NO" (
  SET "varEnableFileLogging=NO"
)

IF "%varLogToFileOK%"=="NOT_DEFINED" (
  IF "%varEnableFileLogging%"=="NO" (
    SET "varLogToFileOK=NO"
  ) ELSE IF "%varEnableFileLogging%"=="YES" (
    SET "varLogToFileOK=YES"
  ) ELSE (
    SET "varLogToFileOK=NO"
    ECHO varEnableLogging is configured incorrectly, varEnableFileLogging: %varEnableFileLogging%.
  )
)
IF "%varLogToSTDOUTOK%"=="NOT_DEFINED" IF ["%~3"]==["OUTPUT_TO_STDOUT"] (
  SET "varLogToSTDOUTOK=YES"
)

REM if %1 has double quotes around it, %~1 will strip the quote signs.
REM "%~1" ensures we always echo to a quoted filePath.
IF "%varLogToSTDOUTOK%"=="YES" ECHO %~2
IF "%varLogToFileOK%"=="YES"   ECHO %~2>>"%~1"
Exit /B 0

REM Messages for logfile Should be suppplied in "Message 1" brackets.
REM Param_1: FileHandle
REM Param_2: Message
REM Param_3: OUTPUT_TO_STDOUT  -  The function will also echo the message to stdout.
REM Param_4: OUTPUT_DEBUG      - Outputs the error messages in this function.
:Append_To_LogFile_With_TimeStamp
CALL ..\utility_functions :CurrentTimeSimpleBackupFormat "varAppend_To_LogFile_With_TimeStamp_CurrentTime"
REM ECHO :Append_To_LogFile_With_TimeStamp_Time: %varAppend_To_LogFile_With_TimeStamp_CurrentTime%
CALL :Append_To_LogFile "%~1" "[%varAppend_To_LogFile_With_TimeStamp_CurrentTime%]: %~2" "%~3" "%~4"
Exit /B 0



