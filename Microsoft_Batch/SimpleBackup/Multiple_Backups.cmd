@echo off
REM Version and Github_upload date: 2.12.3 (22-03-2021)
REM Author/Developer: Søren Madsen
REM Github url: https://github.com/MrSmadsen/Development/tree/main/Microsoft_Batch/SimpleBackup
REM Desciption: This is a Microsoft Batch script to automate backup and archive functionality
REM             provided by standard archiving programs such as 7zip.
REM             It has been developed for my personal setup and my own use case.
REM Documentation: Checkout the file: Howto_Description.pdf
REM Test_Disclaimer: This script has been tested on: Microsoft Windows 10 64bit home (Danish).
REM                  Feel free to use this script/software at your own risk.
REM File Encoding: utf-8

SET "varMultipleBackups=YES"
SET "varGeneralSettingsFile=..\Settings.ini"
SET "varSettingsFileRead=NO"
SET "varBackupSettingsFileRead=NO"

REM Initialize counters.
SET /a "varGeneralSettingsRetrieved=0"
SET /a "varBackupSettingsRetrieved=0"
SET /a "varGeneralSettingsVerified=0"
SET /a "varBackupSettingsVerified=0"

REM  Enable this to backup the latest raspberry pi 3b+ image before the general backup.
CALL :backupRaspberryPiImage
REM  Most complete backup I have defined.
CALL :fullBackup
PAUSE
EXIT

REM Because the function :readBackupSettingsFile calls ..\fileSystem NormalizePath with a
REM one-step navigation backtrack we have to %CD% before calling it.
:readGeneralSettingsFile
CALL ..\utility_functions :readBackupSettingsFile "%varGeneralSettingsFile%"
SET "varSettingsFileRead=YES"

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul
EXIT /B 0

:backupRaspberryPiImage
cd ".\BackupRaspberry3B+ImageLatest"
IF "%varSettingsFileRead%"=="NO" (
  CALL :readGeneralSettingsFile
)
call RaspberryBackup.cmd
TIMEOUT /T 2
cd ".."
EXIT /B 0

:fullBackup
cd ".\FullBackup"
IF "%varSettingsFileRead%"=="NO" (
  CALL :readGeneralSettingsFile
)
call BackupFolders.cmd
TIMEOUT /T 2
cd ".."
EXIT /B 0