@echo off

SET "varMultipleBackups=YES"
SET "varGeneralSettingsFile=..\Settings.ini"
SET "varSettingsFileRead=NO"
SET "varBackupSettingsFileRead=NO"

REM Initialize counters.
SET /a "varGeneralSettingsRetrieved=0"
SET /a "varBackupSettingsRetrieved=0"
SET /a "varGeneralSettingsValidated=0"
SET /a "varBackupSettingsValidated=0"

REM Initializing the lists used for ini-file parameter validation.
CALL .\ParameterValidation :initParameterListValues

REM  Enable this to backup the latest raspberry pi 3b+ image before the general backup.
REM CALL :backupRaspberryPiImage

REM  Enable this to backup everything except big binary blop folders.
CALL :fullBackupNoPictures

REM  Enable this to backup my user folder.
CALL :backupUser

REM  Enable this to backup pictures from current year.
REM CALL :backupBilleder_CurrentYear_and_various_folders

REM  Most complete backup I have defined.
REM CALL :fullBackup

IF "%varMultipleBackups%"=="YES" (
  IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
    CALL .\utility_functions :shutdownDevice
  )
)
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

:fullBackupNoPictures
cd ".\FullBackupNoPictures"
IF "%varSettingsFileRead%"=="NO" (
  CALL :readGeneralSettingsFile
)
call BackupFolders.cmd
TIMEOUT /T 2
cd ".."
EXIT /B 0

:backupUser
cd ".\BackupUser"
IF "%varSettingsFileRead%"=="NO" (
  CALL :readGeneralSettingsFile
)
call BackupFolders.cmd
TIMEOUT /T 2
cd ".."
EXIT /B 0

:backupBilleder_CurrentYear_and_various_folders
cd ".\BackupBilleder_CurrentYear_and_various_folders"
IF "%varSettingsFileRead%"=="NO" (
  CALL :readGeneralSettingsFile
)
call BackupFolders.cmd
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