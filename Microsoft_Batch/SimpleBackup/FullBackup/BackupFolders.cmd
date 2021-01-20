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

SET "varBackupSettingsFileRead=NO"
set varGeneralSettingsFile=..\Settings.ini
CALL ..\utility_functions :readBackupSettingsFile "%varGeneralSettingsFile%"

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

set varSettingsFile=BackupSettings.ini
CALL ..\utility_functions :readBackupSettingsFile "%varSettingsFile%"
SET "varBackupSettingsFileRead=YES"
CALL ..\Backup :Prepare

IF [%varMultipleBackups%]==[] (
  PAUSE
) ELSE (
  ECHO Continuing..
)
EXIT /B 0
