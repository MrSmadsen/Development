@echo off
REM Version 2.5.1 (Github_upload date:16th of April 2021)
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
SET /a "varGeneralSettingsVerified=0"
SET /a "varBackupSettingsVerified=0"

REM Initializing the lists used for ini-file parameter verification.
CALL ..\ParameterVerification :initParameterListValues
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

IF "%varPreparationSucccesful%"=="YES" (
  CALL ..\Backup :ActivateApplicationFunction
)

CALL :PostBackupProcedures

IF [%varMultipleBackups%]==[] (
  IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
    CALL ..\utility_functions :shutdownDevice
  )
  PAUSE
) ELSE (
  ECHO Continuing..
)
EXIT /B 0

REM Copy the SHA file to repo and do a commit.
:PostBackupProcedures

REM Only perform PostBackupProcedures if varmode == a.
IF NOT "%varMode%"=="a" (
  EXIT /B 0
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "------------ Performing PostBackup user functions ------------" "OUTPUT_TO_STDOUT" ""

CALL :copyChecksumFile
IF "%ERRORLEVEL%"=="1" (
  EXIT /B 1
)
CALL :CommitChecksumFileToSvn
IF "%ERRORLEVEL%"=="1" (
  EXIT /B 1
)
CALL :CleanupImagefolder
EXIT /B 0

:copyChecksumFile
SET "varPathNotFound=FALSE"
SET "varCopyFileOk=FALSE"
SET "varDir=%varBackupLocation%\%varDate%"
SET "varDestination=%varRasperryPi3BPlusSha512Path%\%varDate%"

mkdir "%varDestination%"
IF NOT EXIST "%varDestination%" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "RaspberryBackup-copyChecksumFile. mkdir failed. Exitting." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

set "varCurrentDir=%CD%"
ECHO Currentdir: %CD%
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

cd /d "%varDir%"
REM Shows only files in the directory %varDir% in simple output format.
for /f "delims=" %%F in ('dir "%varDir%" /b /a-d') do (
  REM Command - If successful proceed to && clause, if Unsuccessful proceed to || clause.
  ECHO.%%F | FIND /I "SHA512.txt">nul && ( SET "varSrcFileName=%%F" ) || ( SET "varSrcFile=" )
)
SET "varSrcFile=%varDir%\%varSrcFileName%"
cd /d "%varCurrentDir%"

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Copying file %varSrcFileName%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Source folder: %varSrcFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Destination folder: %varDestination%" "OUTPUT_TO_STDOUT" ""

IF "%varSrcFile%"=="" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Finding checksumFile failed." "OUT_TO_STDOUT" ""
)

copy "%varSrcFile%" "%varDestination%"
IF %ERRORLEVEL% NEQ 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Copying varSrcFile failed. varSrcFile: %varSrcFile%" "OUT_TO_STDOUT" ""
)
SET "varCopyFileOk=TRUE"
EXIT /B 0

:CommitChecksumFileToSvn
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
IF "%varCopyFileOk%"=="TRUE" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "------------ Committing %varSrcFileName% to Svn repository: %varSvnWorkingCopy01% ------------" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "------------ Committing %varSrcFileName% to Svn repository: %varSvnWorkingCopy01% ------------" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "FileCopy not verified. Exit without committing checksumFile." "OUTPUT_TO_STDOUT" "" 
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
)

REM SET "varToSvnUpdate=%varSvnWorkingCopy01%\Device_Backup"
SET "varToSvnUpdate=%varSvnWorkingCopy01%\."

IF EXIST .\test.txt (
  del .\test.txt
)
CALL ..\svnRepoFunctions :svnUpdate "%varToSvnUpdate%"
CALL ..\svnRepoFunctions :svnStatus "%varToSvnUpdate%" "--no-ignore" "NO" > .\test.txt

SET /a "varLineCnt=0"
FOR /f "usebackq delims=" %%x in (".\test.txt") do (
  SET /a "varLineCnt+=1"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Following changes are found in the working copy:" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%%x" "OUTPUT_TO_STDOUT" ""
)

REM If Copy==OK and linecnt == 1 we have a rather high probability that the folder
REM is be the folder containing the checksum file. -> Commit it then. Not 100% confirmation of the right file. But close.
IF %varLineCnt% EQU 1 (
  CALL ..\svnRepoFunctions :svnAdd "%varDestination%" "%varSrcFileName%" "--parents"
  CALL ..\svnRepoFunctions :svnCommitAlreadyAddedContent "%varDestination%" "- Added %varDate%\%varSrcFileName%." ""
) ELSE (
  ECHO NOT OK: varLineCnt - %varLineCnt%. Svn Commit failed.
  EXIT /B 1
)

IF EXIST .\test.txt (
  del .\test.txt
)
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

:CleanupImagefolder
CALL :GetImagefolder
IF %ERRORLEVEL% NEQ 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Cleaning folder failed. Exit." "OUT_TO_STDOUT" ""
)

REM Shows only directories in the directory %varFoundfolder% in simple output format.
for /f "delims=" %%F in ('dir "%varFoundfolder%" /b /a:d') do (
  REM Command - If successful proceed to && clause, if Unsuccessful proceed to || clause.
  ECHO.%%F | FIND /I "PixelDesktop_MumbleServer_Vnc_Ufw_Cron_Update_Shutdown">nul && ( SET "varImgFileFolder=%%F" )
)

SET "varTmpDir=%CD%
cd /d "%varFoundfolder%"

IF exist "%varImgFileFolder%" (
  rmdir /Q /S "%varImgFileFolder%"
  IF %ERRORLEVEL% NEQ 0 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Deleting folder %varImgFileFolder% failed. Exit." "OUT_TO_STDOUT" ""
  )
)

REM Shows only files in the directory %varFoundfolder% in simple output format.
for /f "delims=" %%F in ('dir "%varFoundfolder%" /b /a-d') do (
  REM Command - If successful proceed to && clause, if Unsuccessful proceed to || clause.
  ECHO.%%F | FIND /I "PixelDesktop_MumbleServer_Vnc_Ufw_Cron_Update_Shutdown.img">nul && ( SET "varImgFile=%%F" )
  ECHO.%%F | FIND /I "login and relevant info.txt">nul && ( SET "varTxtFile=%%F" )
)
IF exist "%varImgFile%" (
  del "%varImgFile%"
  IF %ERRORLEVEL% NEQ 0 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Deleting image file %varImgFile% failed. Exit." "OUT_TO_STDOUT" ""
  )
)

IF exist "%varTxtFile%" (
  del "%varTxtFile%"
  IF %ERRORLEVEL% NEQ 0 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Deleting image file %varTxtFile% failed. Exit." "OUT_TO_STDOUT" ""
  )
)
cd /d "%varTmpDir%"
EXIT /B 0

:GetImagefolder
SET /a "varFolderCnt=0"
SET "varFoundfolder="
FOR /f "usebackq delims=" %%x in ("%varFileList%") do (
  SET /a "varFolderCnt+=1"
  ECHO Folder From backup.txt: %%x
  REM CALL ..\fileSystem :getDataFromPath "%%x" "FULLY_QUALIFIED_PATH" ""
  REM SET "varFoundfolder=%varGetDataFromPathResult%"
  SET "varFoundfolder=%%x"
)

IF %varFolderCnt% EQU 1 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Found folder: %varFoundfolder%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Only expected 1 folder. Found %varFolderCnt% folders. Exit." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
EXIT /B 0
