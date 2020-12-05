REM Version and Github_upload date: 1.0 (05-12-2020)
REM Author/Developer: Søren Madsen
REM Github url: https://github.com/MrSmadsen/Development/Microsoft_Batch/SimpleBackup
REM Desciption: This is a Microsoft Batch script to automate backup and archive functionality
REM             provided by standard archiving programs such as 7zip.
REM             It has been developed for my personal setup and my own use case.
REM Documentation: Checkout the file: Howto_Description.pdf
REM Test_Disclaimer: This script has been tested on: Microsoft Windows 10 64bit home (Danish).
REM                  Feel free to use this script/software at your own risk.
REM File Encoding: utf-8

@echo off
REM This file was added to be able to start the backup script as administrator without adding a "cd" command to the original script.
REM The "move folder" command doesn't work on my setup as a regular user and requires admin priviliges. Hence this change.
REM By adding this extra "startup batchfile" we can start the backup script as admin's without changing the original script.
REM Running the original script without "move folder options set to YES" should be working with normal priviliges.
REM Create a shortcut of this cmd file. Right-click -> then choose shortcut. Press advanced. Choose run as administrator.

set varGeneralSettingsFile=Settings.ini
CALL .\utility_functions :readBackupSettingsFile "%varGeneralSettingsFile%"

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

set "varMultipleBackups=YES"

REM  Enable this to backup the latest raspberry pi 3b+ image before the general backup.
REM This will generate the checksum file automatically.
REM cd ".\BackupRaspberry3B+ImageLatest"
REM call RaspberryBackup.cmd
REM TIMEOUT /T 2
REM cd ".."

cd ".\FullBackupNoPictures"
call BackupFolders.cmd
TIMEOUT /T 2
cd ".."

cd ".\BackupUser"
call BackupFolders.cmd

PAUSE
EXIT