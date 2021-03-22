@echo off
REM Version and Github_upload date: 2.12.2 (22-03-2021)
REM Author/Developer: Søren Madsen
REM Github url: https://github.com/MrSmadsen/Development/tree/main/Microsoft_Batch/SimpleBackup
REM Desciption: This is a Microsoft Batch script to automate backup and archive functionality
REM             provided by standard archiving programs such as 7zip.
REM             It has been developed for my personal setup and my own use case.
REM Documentation: Checkout the file: Howto_Description.pdf
REM Test_Disclaimer: This script has been tested on: Microsoft Windows 10 64bit home (Danish).
REM                  Feel free to use this script/software at your own risk.
REM File Encoding: utf-8

@echo off
REM Some variables are initialized both in ..\Multi_Backups.cmd and ind the BackupFolders.cmd.
REM This is to ensure correct program flow if the script is started using either of these cmd files.

SET "varBackupSettingsFileRead=NO"
SET "varSettingsFile=BackupSettings.ini"
SET "varGeneralSettingsFile=..\Settings.ini"

REM Initialize counters.
SET /a "varGeneralSettingsRetrieved=0"
SET /a "varBackupSettingsRetrieved=0"
SET /a "varGeneralSettingsVerified=0"
SET /a "varBackupSettingsVerified=0"

REM Initializing the lists used for ini-file parameter verification.
CALL ..\parameterVerification.cmd :initParameterListValues
CALL ..\utility_functions :readBackupSettingsFile "%varGeneralSettingsFile%"

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Path variables are normalized and checked for length as soon as they are read from the settingsfile.
CALL ..\utility_functions :readBackupSettingsFile "%varSettingsFile%"
SET "varBackupSettingsFileRead=YES"

ECHO Ini-file parameters read from ..\Settings.ini: %varGeneralSettingsRetrieved%
ECHO Ini-file parameters read from  .\BackupSettings.ini: %varBackupSettingsRetrieved%
ECHO Ini-file parameters from ..\Settings.ini verified OK: %varGeneralSettingsVerified%
ECHO Ini-file parameters from  .\BackupSettings.ini verified OK: %varBackupSettingsVerified%

IF %varGeneralSettingsVerified% LSS %varGeneralSettingsRetrieved% (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" "varGeneralSettingsVerified: Only verified %varGeneralSettingsVerified% parameters. %varGeneralSettingsRetrieved% parameters was read. Exit" "OUTPUT_TO_STDOUT" ""
)
IF %varBackupSettingsVerified% LSS %varBackupSettingsRetrieved% (    
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" "varBackupSettingsVerified: Only verified %varBackupSettingsVerified% parameters. %varBackupSettingsRetrieved% parameters was read. Exit" "OUTPUT_TO_STDOUT" ""
)

CALL ..\Backup :Prepare

IF "%varDeleteOldBackupFolders%"=="YES" (
  CALL ..\fileSystem :deleteOldBackups "%varBackupLocation%" "%varDate%"
)

IF "%varBackupSynchronizationDuringBackup%"=="YES" (
  ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_DISABLED"
)
IF "%varBackupSynchronizationDuringBackup%"=="YES_PURGE_DST" (
  ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_ENABLED"
)

CALL ..\Backup :End

IF [%varMultipleBackups%]==[] (
  PAUSE
) ELSE (
  ECHO Continuing..
)
EXIT /B 0
