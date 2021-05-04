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

REM Some variables are initialized both in ..\Multi_Backups.cmd and ind the BackupFolders.cmd.
REM This is to ensure correct program flow if the script is started using either of these cmd files.

@echo off
REM Some variables are initialized both in ..\Multi_Backups.cmd and ind the BackupFolders.cmd.
REM This is to ensure correct program flow if the script is started using either of these cmd files.

SET "varBackupSettingsFileRead=NO"
SET "varSettingsFile=BackupSettings.ini"
SET "varGeneralSettingsFile=..\Settings.ini"

REM Initialize counters.
SET /a "varGeneralSettingsRetrieved=0"
SET /a "varBackupSettingsRetrieved=0"
SET /a "varGeneralSettingsValidated=0"
SET /a "varBackupSettingsValidated=0"

REM Initializing the lists used for ini-file parameter validation.
CALL ..\ParameterValidation :initParameterListValues
CALL ..\utility_functions :readBackupSettingsFile "%varGeneralSettingsFile%"

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Path variables are normalized and checked for length as soon as they are read from the settingsfile.
CALL ..\utility_functions :readBackupSettingsFile "%varSettingsFile%"
SET "varBackupSettingsFileRead=YES"

ECHO Ini-file parameters read from ..\Settings.ini: %varGeneralSettingsRetrieved%
ECHO Ini-file parameters read from  .\BackupSettings.ini: %varBackupSettingsRetrieved%
ECHO Ini-file parameters from ..\Settings.ini validated OK: %varGeneralSettingsValidated%
ECHO Ini-file parameters from  .\BackupSettings.ini validated OK: %varBackupSettingsValidated%

IF %varGeneralSettingsValidated% LSS %varGeneralSettingsRetrieved% (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" "varGeneralSettingsValidated: Only validated %varGeneralSettingsValidated% parameters. %varGeneralSettingsRetrieved% parameters was read. Exit" "OUTPUT_TO_STDOUT" ""
)
IF %varBackupSettingsValidated% LSS %varBackupSettingsRetrieved% (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" "varBackupSettingsValidated: Only validated %varBackupSettingsValidated% parameters. %varBackupSettingsRetrieved% parameters was read. Exit" "OUTPUT_TO_STDOUT" ""
)

CALL ..\Backup :Prepare

IF "%varPreparationSucccesful%"=="YES" (
  CALL ..\Backup :ActivateApplicationFunction
)

IF [%varMultipleBackups%]==[] (
  IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
    CALL ..\utility_functions :shutdownDevice
  )
  PAUSE
) ELSE (
  ECHO Continuing..
)
EXIT /B 0
