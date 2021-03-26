@echo off
REM Version and Github_upload date: 2.2.4 (26-03-2021)
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

REM Param_1: Path to backupFolder
REM Param_2: BackupFolderNameToKeep (varDate)
:deleteOldBackups
IF NOT EXIST "%~1" (
  CALL ..\logging :Append_To_Screen "Error: :deleteOldBackups: BackupFolder %1 does not exist. Return 1" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

IF NOT EXIST "%~1\%~2" (
  CALL ..\logging :Append_To_Screen "Error: :deleteOldBackups: BackupFolder\%~2 does not exist. Return 1" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

REM Must be current running configurationBackupfolder to work.
IF NOT "%~1"=="%varBackupLocation%" (
  CALL ..\logging :Append_To_Screen "Error: :deleteOldBackups: Param_1 must be varBackupLocation. Not folders deleted. Return 1" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "---------- Delete old backups starting ----------" "OUTPUT_TO_STDOUT" ""
FOR /f "tokens=*" %%x in ('DIR "%~1" /a:d /b') DO (    
  REM If the found folderName is NOT the same as the current targetBackupFolderName.
  IF NOT "%%x"=="%varDate%" (
    CALL :deleteFolderIfItIsAnOldBackup "%~1" "%%x"
  )
)
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Param_1: Path to backupFolder
REM Param_2: Folder to verify as valid backup.
:deleteFolderIfItIsAnOldBackup
setlocal enabledelayedexpansion
IF NOT EXIST "%~1" (
  CALL ..\logging :Append_To_Screen "Error: :deleteFolderIfItIsAnOldBackup: BackupFolder %1 does not exist. Return 1" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
REM Must be current running configurationBackupfolder to work.
IF NOT "%~1"=="%varBackupLocation%" (
  CALL ..\logging :Append_To_Screen "Error: :deleteFolderIfItIsAnOldBackup: Param_1 must be varBackupLocation. Not folders deleted. Return 1" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
IF NOT EXIST "%~1\%~2" (
  CALL ..\logging :Append_To_Screen "Error: :deleteFolderIfItIsAnOldBackup: Folder to delete not found. Return" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

SET "varResultStrLength2=NOT_DEFINED"
CALL ..\utility_functions :strLength2 "%varDate%" "varResultStrLength2"
REM The expected length is the length of varDate string, which is the name of the backupFolder-subfolder for a specific configuration backup.
SET "varExpectedFolderLength=%varResultStrLength2%"

REM Calculate the length of the folder to be verified.
SET "varResultStrLength2=NOT_DEFINED"
CALL ..\utility_functions :strLength2 "%~2" "varResultStrLength2"
IF "%varResultStrLength2%"=="NOT_DEFINED" (  
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "Error: :deleteFolderIfItIsAnOldBackup: Unexpected error in ..\utility_functions :strLength2. Exit" "OUTPUT_TO_STDOUT" ""
) ELSE IF %varResultStrLength2% NEQ %varExpectedFolderLength% (
  REM Folder does not have the expected length.
  EXIT /B 1
)

REM Check for directories. If any are found return and do not delete. The backup-script do not make subdirs.
FOR /f "tokens=*" %%a in ('DIR "%~1\%~2" /a:d /b') DO (      
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "FOUND UNEXPECTED FOLDER^(s^) in folder: %~1\%~2. Might be user folder. Do not delete folder. Return." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

SET "varIsValidFolder=NOT_DEFINED"
SET "varfolderStartSubStr=%~2"
REM 2021-03-17_15-20-backup.zip.001
SET "varSrcStr1=%varfolderStartSubStr%-backup.zip"
REM 2021-03-17_15-20-Checksum-SHA512.txt
SET "varSrcStr2=%varfolderStartSubStr%-Checksum-*"
REM 2021-03-17_15-20-logfile.txt
SET "varSrcStr3=%varfolderStartSubStr%-logfile.txt"
REM 2021-03-17_15-20-RoboCopyLogfile.txt"
SET "varSrcStr4=%varfolderStartSubStr%-RoboCopyLogfile.txt"
REM 2021-03-17_15-20-RoboCopyLogfile.txt"
SET "varSrcStr5=%varfolderStartSubStr%-UpdateArchive-logfile.txt"
REM 2021-03-17_15-20-RoboCopyLogfile.txt"
SET "varSrcStr6=%varfolderStartSubStr%-ExtractToFolder-logfile.txt"
REM 2021-03-17_15-20-RoboCopyLogfile.txt"
SET "varSrcStr7=%varfolderStartSubStr%-ExtractFullPath-logfile.txt"
REM 2021-03-17_15-20-RoboCopyLogfile.txt"
SET "varSrcStr8=%varfolderStartSubStr%-IntegrityTest-logfile.txt"
REM 2021-03-17_15-20-RoboCopyLogfile.txt"
SET "varSrcStr9=%varfolderStartSubStr%-VerifyChecksum-logfile.txt"
REM 2021-03-17_15-20-backup.exe"
SET "varSrcStr10=%varfolderStartSubStr%-backup.exe"

SET /A "varNoOfFilesInTotal=0"
SET /A "varNoOfExpectedFilesInTotal=0"
REM Shows only files in the directory %varDir% in simple output format.
for /f "delims=" %%F in ('dir "%~1\%~2" /b /a-d') do (
  SET /A "varNoOfFilesInTotal+=1"
  
  echo %%F|findstr /i /b "!varSrcStr1!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpBackupFile=%~1\%~2\%%F"
  )
  
  echo %%F|findstr /i /b "!varSrcStr2!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpChecksumFile=%~1\%~2\%%F"
  )
  
  echo %%F|findstr /i /b "!varSrcStr3!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpLogFile=%~1\%~2\%%F"
  )

  echo %%F|findstr /i /b "!varSrcStr4!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpRoboCopyLogFile=%~1\%~2\%%F"
  )

  echo %%F|findstr /i /b "!varSrcStr5!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpUpdateArchiveLogFile=%~1\%~2\%%F"
  )

  echo %%F|findstr /i /b "!varSrcStr6!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpExtractToFolderLogFile=%~1\%~2\%%F"
  )
  
  echo %%F|findstr /i /b "!varSrcStr7!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpExtractFullPathLogFile=%~1\%~2\%%F"
  )

  echo %%F|findstr /i /b "!varSrcStr8!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpIntegrityTestLogFile=%~1\%~2\%%F"
  )

  echo %%F|findstr /i /b "!varSrcStr9!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpVerifyChecksumLogFile=%~1\%~2\%%F"
  )
  
  echo %%F|findstr /i /b "!varSrcStr10!">nul
  IF !ERRORLEVEL!==0 (
    SET /A "varNoOfExpectedFilesInTotal+=1"
    SET "varTmpBackupSfxFile=%~1\%~2\%%F"
  )
)

REM IF there are more files than expected we do not delete the folder. Might be user copied files they wish to keep.
IF %varNoOfFilesInTotal% GTR %varNoOfExpectedFilesInTotal% (  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "FOUND UNEXPECTED FILE^(s^) in folder: %~1\%~2. Might be user files. Do not delete folder. Return." "OUTPUT_TO_STDOUT" ""
  SET "varIsValidFolder=NO"
)

REM If expected no of files equal all files found the folder is valid.
IF %varNoOfFilesInTotal% EQU %varNoOfExpectedFilesInTotal% (
  SET "varIsValidFolder=YES"
)

REM Unexpected error. Exception.
IF "%varIsValidFolder%"=="NOT_DEFINED" (
  SET "varIsValidFolder=NO"
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":deleteFolderIfItIsAnOldBackup - Unexpected error. Params: %~1 - %~2. Exit" "OUTPUT_TO_STDOUT" ""
)

IF  "%varIsValidFolder%"=="NO" (
  setlocal disabledelayedexpansion
  EXIT /B 1
)

IF "%varIsValidFolder%"=="YES" (
REM Delete folder without user confirmation.
  IF NOT "%~1"=="%varBackupLocation%" (
    ECHO %~1 is not the current configuration backupfolder. Exit without deleting folder.
    Setlocal disabledelayedexpansion
    EXIT /B 1
  )
  rmdir /Q /S "%~1\%~2"    
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Deleted old backup: %~1\%~2" "OUTPUT_TO_STDOUT" ""
)
setlocal disabledelayedexpansion
EXIT /B 0

REM If EXIST fileName will check for existence of a folder or a file.
REM Param_1: Path
REM Param_2: Ini-file option name.
REM Param_3: returnValue. (YES | NO)
REM Param_4: Create the folder if it does not exist. (CREATE_DIR | CREATE_FILE)
REM Param_5: Throw an exception if the folder does not exist. (EXCEPTION_YES)
:checkIfFileOrFolderExist
SET "varCheckIfFileOrFolderExistResult="
IF [%1]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfFileOrFolderExist - No path supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfFileOrFolderExist - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL ..\logging :Append_To_Screen  ":checkIfFileOrFolderExist - Parameter 2 missing ini-file option name. Exit" "" "OUTPUT_DEBUG"
)
IF [%2]==[""] (
  CALL ..\logging :Append_To_Screen  ":checkIfFileOrFolderExist - Parameter 2 missing ini-file option name. Exit" "" "OUTPUT_DEBUG"
)
IF [%3]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfFileOrFolderExist - Parameter 3 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfFileOrFolderExist - Parameter 3 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[] (
  CALL ..\logging :Append_To_Screen  ":checkIfFileOrFolderExist - Parameter 4 missing. Create - CREATE_YES. Empty = NO. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[""] (
  CALL ..\logging :Append_To_Screen  ":checkIfFileOrFolderExist - Parameter 4 missing. Create - CREATE_YES. Empty = NO. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%5]==[] (
  CALL ..\logging :Append_To_Screen  ":checkIfFileOrFolderExist - Parameter 5 missing. Create - EXCEPTION_YES. Empty = NO. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%5]==[""] (
  CALL ..\logging :Append_To_Screen  ":checkIfFileOrFolderExist - Parameter 5 missing. Create - EXCEPTION_YES. Empty = NO. Exit" "OUTPUT_TO_STDOUT" ""
)

IF EXIST "%~1" (
  SET "varCheckIfFileOrFolderExistResult=YES"
) ELSE (
  SET "varCheckIfFileOrFolderExistResult=NO"
  IF "%~4"=="CREATE_DIR" (
    REM Folder
    mkdir "%~1"
    IF EXIST "%~1" (
      SET "varCheckIfFileOrFolderExistResult=YES"
    )    
  ) ELSE IF "%~4"=="CREATE_FILE" (
    REM File
    type nul > "%~1"
    IF EXIST "%~1" (
      SET "varCheckIfFileOrFolderExistResult=YES"
    )
  )
)

IF "%varCheckIfFileOrFolderExistResult%"=="NO" IF "%~5"=="EXCEPTION_YES" (
    CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfFileOrFolderExist - Path in %varSettingsFile% %~2 not found. Exit" "OUTPUT_TO_STDOUT" ""
)
SET "%~3=%varCheckIfFileOrFolderExistResult%"
EXIT /B 0

REM Param_1: FilePath to normalize 
REM Param_2: returnValue
:NormalizeFilePath
IF [%1]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":NormalizeFilePath - No path supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":NormalizeFilePath - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":NormalizeFilePath - No returnValue variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":NormalizeFilePath - Empty returnValue variable name supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)

set "%~2=%~f1"
EXIT /B 0

REM Param_1: Path
REM Param_2: Check variable used to verify url-type.
:CheckIfParamIsUrl
set "varParam1=%~1"
set "varParam1=%varParam1:~0,7%"
set "varParam1_2=%~1"
set "varParam1_2=%varParam1_2:~0,8%"

REM ECHO varParam1: %varParam_1%
IF "%varParam1%"=="http://" (
  REM ECHO SET TO YES
  set "%~2=YES"
) ELSE IF "%varParam1%"=="HTTP://" (
  REM ECHO SET TO YES
  set "%~2=YES"
) ELSE IF "%varParam1_2%"=="https://" (
REM ECHO SET TO YES
set "%~2=YES"
) ELSE IF "%varParam1_2%"=="HTTPS://" (
  REM ECHO SET TO YES
  set "%~2=YES"
) ELSE (
  REM ECHO SET TO NO
  set "%~2=NO"
)
REM Idea: Implement a regular expression to test all elements of the supplied parameter.
REM       This will also be a good solution for svn, ftp or other path protocols.
EXIT /B 0

REM Param_1: Path
REM Param_2: Allow url. (YES | NO). If the path is an url and allow == NO the function will call Exception_End.
:CheckIfParamIsUrl_2
set "varIsUrl=NOT_VERIFIED"
set "varParam1=%~1"
set "varParam1=%varParam1:~0,7%"
set "varParam1_2=%~1"
set "varParam1_2=%varParam1_2:~0,8%"

REM ECHO varParam_1: %varParam_1%
IF "%varParam1%"=="http://" (
  REM ECHO SET TO YES
  set "varIsUrl=YES"
) ELSE IF "%varParam1%"=="HTTP://" (
  REM ECHO SET TO YES
  set "varIsUrl=YES"
) ELSE IF "%varParam1_2%"=="https://" (
  REM ECHO SET TO YES
  set "varIsUrl=YES"
) ELSE IF "%varParam1_2%"=="HTTPS://" (
  REM ECHO SET TO YES
  set "varIsUrl=YES"
) ELSE (
  REM ECHO SET TO NO
  set "varIsUrl=NO"
)

IF "varIsUrl"=="NOT_VERIFIED" (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":CheckIfParamIsUrl - Error-1 in the function implementation. Exit" "OUTPUT_TO_STDOUT" ""
)

REM If allow url:
IF "%~2"=="NO" (
  IF "%varIsUrl%"=="YES" (
    REM Do not accept url - Default behaviour.
    CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "%~1 is an URL. Urls are not accepted as paths. Exit" "OUTPUT_TO_STDOUT" ""
  )
  IF "%varIsUrl%"=="NO" (
    ECHO.
    REM PASSTHROUGH - Allow all paths that are not urls.
  )
  IF "%varIsUrl%"=="NOT_VERIFIED" (
    CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":CheckIfParamIsUrl - Error-2 in the function implementation. Exit" "OUTPUT_TO_STDOUT" ""
  )
) ELSE IF "%~2"=="YES" (

  IF "%varIsUrl%"=="YES" (
    ECHO.
    REM PASSTHROUGH - Allow urls.
  )
  IF "%varIsUrl%"=="NO" (
    ECHO.
    REM PASSTHROUGH - Allow urls.
  )
  IF "%varIsUrl%"=="NOT_VERIFIED" (
    CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":CheckIfParamIsUrl - Error-3 in the function implementation. Exit" "OUTPUT_TO_STDOUT" ""
  )
) ELSE (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "Param_2 is incorrect. Use either value "YES" or value "NO". Exit" "OUTPUT_TO_STDOUT" ""
)

REM Idea: Implement a regular expression to test all elements of the supplied parameter.
REM       This will also be a good solution for svn, ftp or other path protocols.
EXIT /B 0

REM Param_1: Path and fileName to the file to create on the filesystem.
REM Param_2: If file exists. "USE_EXISTING_FILE" OR "OVERWRITE_EXISTING_FILE"
REM Param_3: Verbose_Mode - "V"
:createFile
REM The function :CheckIfParamIsUrl exits if path is an url
CALL :CheckIfParamIsUrl_2 "%~1" "NO"

REM Use existing file
IF EXIST "%~1" (
  IF "%~2"=="USE_EXISTING_FILE" (
    IF "%~3"=="V" ( ECHO Using existing file: %~1. )
    IF "%~3"=="v" ( ECHO Using existing file: %~1. )
    EXIT /B 0
  ) ELSE IF "%~2"=="OVERWRITE_EXISTING_FILE" (
    IF "%~3"=="V" ( ECHO OVER_WRITE_FILE: deleting file: %~1. )
    IF "%~3"=="v" ( ECHO OVER_WRITE_FILE: deleting file: %~1. )
    CALL :deleteFile "%~1" "" "%~3"
    REM Proceed through the code to reach fil creation.
  ) ELSE (
    CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "createFile: Please specify Param_2: REM Param_2: "USE_EXISTING_FILE" OR "OVERWRITE_EXISTING_FILE. Exit" "OUTPUT_TO_STDOUT" ""
  )
)
IF NOT EXIST "%~1" (
  REM Create empty file.
  REM fsutil file createnew "%~1" 0
  REM copy "test" > "%~1"
  TYPE NUL > "%~1"
  IF %ERRORLEVEL% NEQ 0 (
    CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "createFile: Could not create file. Exit" "OUTPUT_TO_STDOUT" ""
  )
  IF "%~3"=="V" ( ECHO Created File:  %~1. )
  IF "%~3"=="v" ( ECHO Created File:  %~1. )
)
EXIT /B 0

REM Param_1: Path and fileName to the file to delete on the filesystem.
REM Param_2: RegularMode "" or QuietMode: "USE_QUIET_MODE".
REM Param_3: Verbose_Mode - "V"
:deleteFile
IF "%~2"=="USE_QUIET_MODE" (
  SET "varDeleteMode=/Q"
)
del %varDeleteMode% "%~1"
IF %ERRORLEVEL% NEQ 0 (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" "deleteFile: Could not delete file. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~3"=="V" ( CALL  ..\logging :Append_To_Screen "Deleted file %1." "OUTPUT_TO_STDOUT" "" )
IF "%~3"=="v" ( CALL  ..\logging :Append_To_Screen "Deleted file %1." "OUTPUT_TO_STDOUT" "" )
EXIT /B 0

REM Param_1: Path
REM Param_2: file name.
:createRobocopyLogFile
  IF "%varEnableFileLogging%"=="NO" (
    CALL  ..\logging :Append_To_Screen ":createRobocopyLogFile FileLogging is disabled." "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  REM IF EXIST "%varTargetRoboCopyLogFile%" (
  IF EXIST "%~1\%~2" (
    REM ensure flags are set.
    CALL :setRobocopyLogFileFlags "%~1\%~2"
    EXIT /B 1
  )

  REM Create robocopy logfile.
  SET "varTargetRoboCopyLogFileName=%~2"
  SET "varTargetRoboCopyLogFile=%~1\%~2"
  
  CALL ..\logging :createLogFile "%varTargetRoboCopyLogFile%" ""
  CALL :setRobocopyLogFileFlags "%~1\%~2"
) 
EXIT /B 0

REM Param_1: Full path to file. You must use double brackets "" to encapsulate the parameter.
:setRobocopyLogFileFlags
IF %varCodePage% NEQ 65001 (
  SET "varRoboCopyLogFlags=/tee /log+:%1"
) ELSE IF %varCodePage% EQU 65001 (
  SET "varRoboCopyLogFlags=/tee /unilog+:%1"
) ELSE (
  SET "varRoboCopyLogFlags="
)
EXIT /B 0

:setRobocopyGenericFlags
SET "varRobocopyGenericFlags="
IF "%varCodePage%"=="65001" (
  SET "varRobocopyGenericFlags=/unicode"
)

IF %varThreadAffinity:~2,5% GTR 1 (
  SET "varRoboCopyThreadAffinity=/MT"
) ELSE (
  SET "varRoboCopyThreadAffinity="
)
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:DestinationPath
REM Param_3: Destinationfolder purge ("PURGE_ENABLED" | "PURGE_DISABLED").
:synchronizeFolder
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  IF NOT EXIST "%~2" (
    mkdir "%~2"
    IF NOT EXIST "%~2" (
      CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" :Append_To_Screen "Error: :synchronizeFolder: Destination-Path %2 does not exist.Return" "OUTPUT_TO_STDOUT" ""
      EXIT /B 1
    )
  )
  IF NOT EXIST "%~1" (    
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error: :synchronizeFolder: Source-Path %1 does not exist.Return" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "---------- Synchronization to external storage ----------" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronizing folder from: %~1" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "                       to: %~2" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "               Purge Mode: %~3" "OUTPUT_TO_STDOUT" ""
  
  REM /mir  Mirrors a directory tree (equivalent to /e plus /purge). Using this option with the /e option and a destination directory,
  REM overwrites the destination directory security settings.
  REM /xx - https://ss64.com/nt/robocopy.html eXclude "eXtra" files and dirs (present in destination but not source)
  
  CALL :setRobocopyGenericFlags
  
  SET "varSyncFlags= "
  IF "%~3"=="PURGE_ENABLED" (
    SET "varSyncFlags= /DCOPY:%varSyncFolder_DCOPY_FLAGS% /COPY:%varSyncFolder_COPY_FLAGS% /e /mir"
  ) ELSE (
    SET "varSyncFlags= /DCOPY:%varSyncFolder_DCOPY_FLAGS% /COPY:%varSyncFolder_COPY_FLAGS% /e"
  )

  REM /copy:DATS - file properties:       D:Data, A:Attributes, T:Time stamps, S:NTFS access control list (ACL)
  REM /dcopy:DAT - directory  properties: D:Data, A:Attributes, T:Time stamps
  REM /zb   Uses restartable mode. If access is denied, this option uses Backup mode. (Requires: Backup and Restore Files user rights)
  
  REM /xf <filename>[ ...]  Excludes files that match the specified names or paths. Wildcard characters (* and ?) are supported.
  REM /xd <directory>[ ...] Excludes directories that match the specified names and paths.
  REM /xc   Excludes changed files.
  REM /xn   Excludes newer files.
  REM /xo   Excludes older files.
  REM /xx   Excludes extra files and directories.
  REM /xl   Excludes "lonely" files and directories.
  REM /is   Includes the same files.
  REM /it   Includes modified files.
  
  REM /xa:[RASHCNETO]   Excludes files for which any of the specified attributes are set. The valid values for this option are:
  REM R - Read only
  REM A - Archive
  REM S - System
  REM H - Hidden
  REM C - Compressed
  REM N - Not content indexed
  REM E - Encrypted
  REM T - Temporary
  REM O - Offline
  
  REM Exclude google backup and sync folder: /xd "%~1\.tmp.drivedownload"

  IF %varElevatedAdminPriviligies%==YES (
    robocopy "%~1" "%~2" %varOutputFormat% /xd "%~1\.tmp.drivedownload" /xa:SHT %varSyncFlags% %varRoboCopyThreadAffinity% %varRobocopyGenericFlags% %varRoboCopyLogFlags% /zb /r:2 /w:10
  ) ELSE (
    robocopy "%~1" "%~2" %varOutputFormat% /xd "%~1\.tmp.drivedownload" /xa:SHT %varSyncFlags% %varRoboCopyThreadAffinity% %varRobocopyGenericFlags% %varRoboCopyLogFlags% /r:2 /w:10    
  )

  REM https://ss64.com/nt/robocopy-exit.html (An Exit Code of 0-7 is success and any value >= 8 indicates that there was at least one failure during the copy operation.)
  IF %ERRORLEVEL% GEQ 8 (
    if %ERRORLEVEL% EQU 16 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: ***FATAL ERROR***. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 15 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: OKCOPY + FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 14 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 13 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: OKCOPY + FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 12 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 11 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: OKCOPY + FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 10 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 9  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :synchronizeFolder: OKCOPY + FAIL. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
  )  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronizing to external storage done." "OUTPUT_TO_STDOUT" ""    
  ECHO.
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:Filename of the file to be copied.
REM Param_3:DestinationPath
:copyFile
  IF NOT EXIST "%~3" (
    mkdir "%~3"
    IF NOT EXIST "%~3" (
      CALL ..\logging :Append_To_Screen "Error: :copyFile: Destination-Path %3 does not exist.Return" "OUTPUT_TO_STDOUT" ""
      EXIT /B 1
    )
  )

  IF NOT EXIST "%~1\%~2" (
    CALL ..\logging :Append_To_Screen "Error: :copyFile: Source-File %2 does not exist.Return" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  CALL :setRobocopyGenericFlags
  
  ECHO Copying file: %~1\%~2
  ECHO           to: %~3

  SET "varCopyFlags= /DCOPY:%varCopyFolder_DCOPY_FLAGS% /COPY:%varCopyFolder_COPY_FLAGS% /e"
  robocopy "%~1" "%~3" "%~2" %varOutputFormat% %varCopyFlags% %varRoboCopyThreadAffinity% %varRobocopyGenericFlags% %varRoboCopyLogFlags% /r:2 /w:10
  
  REM https://ss64.com/nt/robocopy-exit.html (An Exit Code of 0-7 is success and any value >= 8 indicates that there was at least one failure during the copy operation.)
  IF %ERRORLEVEL% GEQ 8 (
    if %ERRORLEVEL% EQU 16 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: ***FATAL ERROR***. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 15 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 14 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 13 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 12 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 11 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 10 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 9  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
  )  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Copying file is done.. ERRORLEVEL: %ERRORLEVEL%" "OUTPUT_TO_STDOUT" ""
  ECHO.
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:DestinationPath
:moveFolder
  SET "varMoveFolder=NOT_VERIFIED"
  
  IF NOT EXIST "%~2" (
    mkdir "%~2"
    IF NOT EXIST "%~2" (
      SET "varMoveFolder=NO"
      CALL ..\logging :Append_To_Screen "Error: :moveFolder: Destination-Path %2 does not exist.Return" "OUTPUT_TO_STDOUT" ""
      EXIT /B 1
    )
  )

  IF NOT EXIST "%~1" (
    SET "varMoveFolder=NO"
    CALL ..\logging :Append_To_Screen "Error: :moveFolder: Source-Path %1 does not exist.Return" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  set "varMoveFolder=YES"
  
  IF [%varMoveFolder%]==[YES] (
    ECHO Moving folder from: %~1
    ECHO                 to: %~2

    CALL :setRobocopyGenericFlags
    
    SET "varMoveFlags= /DCOPY:%varMoveFolder_DCOPY_FLAGS% /COPY:%varMoveFolder_COPY_FLAGS% /e"
    robocopy "%~1" "%~2" %varOutputFormat% %varMoveFlags% %varRoboCopyThreadAffinity% %varRobocopyGenericFlags% %varRoboCopyLogFlags% /MOVE /r:2 /w:10

    REM https://ss64.com/nt/robocopy-exit.html (An Exit Code of 0-7 is success and any value >= 8 indicates that there was at least one failure during the copy operation.)
    IF %ERRORLEVEL% GEQ 8 ( 
      if %ERRORLEVEL% EQU 16 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: ***FATAL ERROR***. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 15 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 14 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 13 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 12 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 11 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 10 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 9  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    )  
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Copying folder is done.. ERRORLEVEL: %ERRORLEVEL%" "OUTPUT_TO_STDOUT" ""
    ECHO.    
  ) ELSE IF [%varMoveFolder%]==[NO] (
    ECHO varMoveFolder == NO. 
    EXIT /B 1
  ) ELSE (
    CALL ..\logging :Append_To_Screen "Error: :moveFolder: varMoveFolder (%varMoveFolder%)" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  ECHO.
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:DestinationPath
:copyFolder
  IF NOT EXIST "%~2" (
    mkdir "%~2"
    IF NOT EXIST "%~2" (
      CALL ..\logging :Append_To_Screen "Error: :copyFolder: Destination-Path %2 does not exist.Return" "OUTPUT_TO_STDOUT" ""
      EXIT /B 1
    )
  )

  IF NOT EXIST "%~1" (    
    CALL ..\logging :Append_To_Screen "Error: :copyFolder: Source-Path %1 does not exist.Return" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  ECHO Copying folder from: %~1
  ECHO                  to: %~2

  CALL :setRobocopyGenericFlags

  SET "varCopyFlags= /DCOPY:%varCopyFolder_DCOPY_FLAGS% /COPY:%varCopyFolder_COPY_FLAGS% /e"
  robocopy "%~1" "%~2" %varOutputFormat% %varCopyFlags% %varRoboCopyThreadAffinity% %varRobocopyGenericFlags% %varRoboCopyLogFlags% /r:2 /w:10

  REM https://ss64.com/nt/robocopy-exit.html (An Exit Code of 0-7 is success and any value >= 8 indicates that there was at least one failure during the copy operation.)
  IF %ERRORLEVEL% GEQ 8 (
    if %ERRORLEVEL% EQU 16 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: ***FATAL ERROR***. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 15 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 14 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 13 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 12 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 11 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 10 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    if %ERRORLEVEL% EQU 9  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
  )  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Copying folder is done.. ERRORLEVEL: %ERRORLEVEL%" "OUTPUT_TO_STDOUT" ""
  ECHO.
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:DestinationPath
:moveFolder
  SET "varMoveFolder=NOT_VERIFIED"
  
  IF NOT EXIST "%~2" (
    mkdir "%~2"
    IF NOT EXIST "%~2" (
      SET "varMoveFolder=NO"
      CALL ..\logging :Append_To_Screen "Error: :moveFolder: Destination-Path %2 does not exist.Return" "OUTPUT_TO_STDOUT" ""
      EXIT /B 1
    )
  )

  IF NOT EXIST "%~1" (
    SET "varMoveFolder=NO"
    CALL ..\logging :Append_To_Screen "Error: :moveFolder: Source-Path %1 does not exist.Return" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  set "varMoveFolder=YES"
  
  IF [%varMoveFolder%]==[YES] (
    CALL :setRobocopyGenericFlags

    ECHO Moving folder from: %~1
    ECHO                 to: %~2
    
    SET "varMoveFlags= /DCOPY:%varMoveFolder_DCOPY_FLAGS% /COPY:%varMoveFolder_COPY_FLAGS% /e"
    robocopy "%~1" "%~2" %varOutputFormat% %varMoveFlags% %varRoboCopyThreadAffinity% %varRobocopyGenericFlags% %varRoboCopyLogFlags% /MOVE /r:2 /w:10

      REM https://ss64.com/nt/robocopy-exit.html (An Exit Code of 0-7 is success and any value >= 8 indicates that there was at least one failure during the copy operation.)
    IF %ERRORLEVEL% GEQ 8 (
      if %ERRORLEVEL% EQU 16 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: ***FATAL ERROR***. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 15 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 14 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 13 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 12 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + MISMATCHES. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 11 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 10 CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: FAIL + XTRA. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
      if %ERRORLEVEL% EQU 9  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Fatal_Error: :copyFolder: OKCOPY + FAIL. ERRORLEVEL: %ERRORLEVEL%.Exit" "OUTPUT_TO_STDOUT" ""
    )  
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Copying folder is done.. ERRORLEVEL: %ERRORLEVEL%" "OUTPUT_TO_STDOUT" ""
    ECHO.    
  ) ELSE IF [%varMoveFolder%]==[NO] (
    ECHO varMoveFolder == NO. 
    EXIT /B 1
  ) ELSE (
    CALL ..\logging :Append_To_Screen "Error: :moveFolder: varMoveFolder (%varMoveFolder%)" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  ECHO.
EXIT /B 0

REM Param_1: Path
REM Param_2: VALUE_DEFINE - the result is stored in variable: varGetDataFromPathResult
  REM POSSIBLE VALUES: "REMOVE_QUOTE_SIGNS", "FULLY_QUALIFIED_PATH","DRIVE_LETTER_ONLY"
  REM POSSIBLE VALUES: "PATH_ONLY","FILE_NAME_ONLY","FILE_EXTENSION_ONLY","SHORT_NAME_ONLY"
  REM POSSIBLE VALUES: "FILE_ATTRIBUTES","DATE-TIME_OF_FILE","SIZE_OF_FILE"
REM Param_3: Verbose_Mode - "v"
:getDataFromPath
SET "varGetDataFromPathResult="
IF "%~2"=="REMOVE_QUOTE_SIGNS" (
  SET "varGetDataFromPathResult=%~1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FULLY_QUALIFIED_PATH" (
  SET "varGetDataFromPathResult=%~f1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="DRIVE_LETTER_ONLY" (
  SET "varGetDataFromPathResult=%~d1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="PATH_ONLY" (
  SET "varGetDataFromPathResult=%~p1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FILE_NAME_ONLY" (
  SET "varGetDataFromPathResult=%~n1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FILE_EXTENSION_ONLY" (
  SET "varGetDataFromPathResult=%~x1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="SHORT_NAME_ONLY" (
  SET "varGetDataFromPathResult=%~s1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FILE_ATTRIBUTES" (
  SET "varGetDataFromPathResult=%~a1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="DATE-TIME_OF_FILE" (
  SET "varGetDataFromPathResult=%~t1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="SIZE_OF_FILE" (
  SET "varGetDataFromPathResult=%~z1"
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
  IF "%~3"== "v" ( ECHO "%varGetDataFromPathResult%" )
)
REM IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
REM Documentation
REM %~1         - expands %1 removing any surrounding quotes (")
REM %~f1        - expands %1 to a fully qualified path name
REM %~d1        - expands %1 to a drive letter only
REM %~p1        - expands %1 to a path only
REM %~n1        - expands %1 to a file name only
REM %~x1        - expands %1 to a file extension only
REM %~s1        - expanded path contains short names only
REM %~a1        - expands %1 to file attributes
REM %~t1        - expands %1 to date/time of file
REM %~z1        - expands %1 to size of file
EXIT /B 0

REM Test function for :GetDataFromPath
REM This function does not use asserts and relies on visual inspection.
:TEST_GetDataFromPath
SET "varDstPath=C:\MyFolder\\\My----TestFolder\.\test-file.txt"
CALL :getDataFromPath "%varDstPath%" "REMOVE_QUOTE_SIGNS" "V"
CALL :getDataFromPath "%varDstPath%" "FULLY_QUALIFIED_PATH" "V"
CALL :getDataFromPath "%varDstPath%" "DRIVE_LETTER_ONLY" "V"
CALL :getDataFromPath "%varDstPath%" "PATH_ONLY" "V"
CALL :getDataFromPath "%varDstPath%" "FILE_NAME_ONLY" "V"
CALL :getDataFromPath "%varDstPath%" "FILE_EXTENSION_ONLY" "V"
CALL :getDataFromPath "%varDstPath%" "SHORT_NAME_ONLY" "V"
CALL :getDataFromPath "%varDstPath%" "FILE_ATTRIBUTES" "V"
CALL :getDataFromPath "%varDstPath%" "DATE-TIME_OF_FILE" "V"
CALL :getDataFromPath "%varDstPath%" "SIZE_OF_FILE" "V"
EXIT /B 0
