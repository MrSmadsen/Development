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

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Param_1: Function_To_Be_Called
REM Param_2: Function_Param_1
REM Param_3: Function_Param_2
REM Param_4: Function_Param_3
REM Param_5: Function_Param_4
CALL %1 %2 %3 %4 %5
EXIT /B 0

REM Untested: Check attributes if the path is a folder/directory
REM Param_1: Path
REM Param_2: returnValue. (YES | NO)
REM Param_3: Exception on error. (YES | NO)
:checkIfIsFolder
SETLOCAL
SET "_result=NOT_DEFINED"
IF [%1]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - No path supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 2 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 2 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 3 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 3 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)

SET "varFileAttribs=%~a1"
IF "%varFileAttribs:~0,1%"=="d" (
  ECHO %varFileAttribs% %1 is a folder.
  SET "_result=YES"
) ELSE (
  ECHO %varFileAttribs% %1 is not a folder.
  SET "_result=NO"
  IF "%~3"=="NO" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path %~1 is not a folder." "OUTPUT_TO_STDOUT" ""
  )
  IF "%~3"=="YES" (
    CALL  ..\utility_functions :Exception_End "%varTargetLogFile%" "Path %~1 is not a folder." "OUTPUT_TO_STDOUT" ""
  ) 
)
ENDLOCAL & Set "%~2=%_result%"
EXIT /B 0

REM If EXIST fileName will check for existence of a folder or a file.
REM Param_1: Path
REM Param_2: returnValue. (YES | NO)
REM Param_3: Exception on error. (YES | NO)
:checkIfFileOrFolderExist
IF [%1]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - No path supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 2 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 2 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 3 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 3 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)

IF EXIST "%~1" (
  set "%~2=YES"
) ELSE (
  set "%~2=NO"
  IF "%~3"=="NO" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path %~1 does not exist." "OUTPUT_TO_STDOUT" ""
  )
  IF "%~3"=="YES" (
    CALL  ..\utility_functions :Exception_End "%varTargetLogFile%" "Path %~1 does not exist. Exit" "OUTPUT_TO_STDOUT" ""
  )
)
EXIT /B 0

REM If EXIST fileName will check for existence of a folder or a file.
REM Param_1: Path
REM Param_2: Ini-file option name.
REM Param_3: returnValue. (YES | NO)
REM Param_4: Exception on error. (YES | NO)
:checkIfFileOrFolderExist_IniFileOptionSupported
IF [%1]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - No path supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%1]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Empty double qoutes supplied to the function. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 2 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%2]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 2 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 3 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%3]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 3 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 4 missing. Exit" "OUTPUT_TO_STDOUT" ""
)
IF [%4]==[""] (
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":checkIfDirExist - Parameter 4 missing. Only double quotes found. Exit" "OUTPUT_TO_STDOUT" ""
)

IF EXIST "%~1" (
  set "%~3=YES"
) ELSE (
  set "%~3=NO"
  IF "%~4"=="NO" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path defined in %varSettingsFile% %~2 does not exist." "OUTPUT_TO_STDOUT" ""
  )
  IF "%~4"=="YES" (
    CALL  ..\utility_functions :Exception_End "varTargetLogFile" "Path defined in %varSettingsFile% %~2 does not exist. Exit" "OUTPUT_TO_STDOUT" ""
  ) 
)
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

REM Implement: Local filesystem check: Either partion labeled with drive letter og partition mounted as a volume point (ntfs - folder mount)
REM Param_1: Path
REM Param_2: Check variable used to verify fileSystem-type.
:CheckIfParamIsLocalFileSystem
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":CheckIfParamIsLocalFileSystem - Not implemented yet. Exit" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Implement: A path is a network path if it is either an unc network path or an url.
REM We still do not handle every protocol on the planet. so HKPS, svn, etc is ignored.
REM Param_1: Path
REM Param_2: Check variable used to verify network-type.
:CheckIfParamIsNetworkPath
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":CheckIfParamIsNetworkPath - Not implemented yet. Exit" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

REM Implement: Unc network path (microsoft): \\SERVER\Share-name\Regular-FilePath-Folder1\Regular-FilePath-Folder2
REM Unc network path (unix): //SERVER/Share-name/Regular-FilePath-Folder1/Regular-FilePath-Folder2
REM Param_1: Path
REM Param_2: Check variable used to verify unc network.
:CheckIfParamIsUncNetworkPath
  CALL  ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":CheckIfParamIsUncNetworkPath - Not implemented yet. Exit" "OUTPUT_TO_STDOUT" ""
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

REM UNFINISHED FUNCTION - Added not to forget the solution.
REM Retrieve the last folderName in the path.
REM Function also trims trailing whitespace.
:ExtractRightMostFolderNameInPath
ECHO UNTESTED FUNCTION. TEST AND VERIFY FUNCTIONALITY BEFORE USING IT.
SET "varTest=c:\Test\Test\Awesome Test"
setlocal enabledelayedexpansion
for %%a in ("%varTest:\=" "%") do (
  set "varLastFolder=%%a"
)
setlocal disabledelayedexpansion
REM Remove brackets from the string.
set "varLastFolderBracketLess=%varLastFolder:~1,-1%"
REM Trim trailing whitespace up to 100 chars.
setlocal enabledelayedexpansion
for /l %%a in (1,1,100) do if "!varLastFolderBracketLess:~-1!"==" " set "varLastFolderBracketLess=!varLastFolderBracketLess:~0,-1!"
setlocal disabledelayedexpansion  
ECHO varLastFolderBracketLess: %varLastFolderBracketLess%
endlocal
EXIT /B 0

REM UNFINISHED FUNCTION - Added not to forget the solution.
REM Param_1 Parameter to check.
REM Param_2 ReturnValue with new string.
:AddTrailingSlash
ECHO UNTESTED FUNCTION. TEST AND VERIFY FUNCTIONALITY BEFORE USING IT.
SET "varTmpParamStr=%~1"
set "varTmpParamStr=%varTmpParamStr:~-1%"
if '%varTmpParamStr% NEQ '\ set "varTmpParamStr=%varTmpParamStr%\"
/EXIT /B 0

REM Param_1 File path
:CheckFileReadAccess
REM ECHO TODO: Implement!
EXIT /B 0

REM Param_1 File path
:CheckFileWriteAccess
REM ECHO TODO: Implement!
EXIT /B 0

REM Param_1 Folder path
:CheckFolderReadAccess
REM ECHO TODO: Implement!
EXIT /B 0

REM Param_1 Folder path
:CheckFolderWriteAccess
REM ECHO TODO: Implement!
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

REM deleteFolder param1:Path to folder
:deleteFolder
ECHO TODO: Implement!
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:DestinationPath
:copyFolder
IF NOT EXIST "%~1" (
  CALL ..\logging :Append_To_Screen "Error: :copyFolder: Source-Path not found.Return" "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

ECHO Copying folder from: %~1
ECHO                  to: %~2

IF EXIST "%~1" (
  robocopy %~1 %~2 %varOutputFormat% /e /sec /dcopy:DAT /r:2 /w:10
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_Screen "Error: :copyFolder: Robocopy copy error. ERRORLEVEL: %ERRORLEVEL%" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
) ELSE (
  CALL ..\logging :Append_To_Screen "Error: :copyFolder: Robocopy folder error." "OUTPUT_TO_STDOUT" ""
)
  ECHO.
EXIT /B 0

REM Param_1:SourcePath
REM Param_2:DestinationPath
:moveFolder
  SET "varMoveFolder=NOT_VERIFIED"
  
  IF NOT EXIST "%~2" (
    mkdir %2
    IF %ERRORLEVEL% NEQ 0 (
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
    REM move /Y %~f1 %~f2
    
    REM If /MOVE is used with robocopy version 10.0.19041.1 the program appearently does not preserve folder and file
    REM attributes. Even though I used /SEC (which should be equal to /DATS). Some advice to use a two step copy and
    REM then delete source folder. Going to test if it was because of missing /DCOPY:DAT.
    REM Maybe also test /secfix and /timfix.
    REM TWO-Step copy:
    REM robocopy source dstination /r:5 /MIR /Tee
    REM robocopy \\<servername>\sharename e:\data\foldername /r:5 /E /DCOPY:T /XF * /Tee

    REM /tee writes console output to a logfile aswell.
    REM robocopy %~1 %~2 %varOutputFormat% /tee /e /dcopy:DAT /sec /MOVE /r:2 /w:10
    IF EXIST "%~1" IF EXIST "%~2" (
      robocopy %~1 %~2 %varOutputFormat% /e /sec /dcopy:DAT /MOVE /r:2 /w:10
      IF %ERRORLEVEL% NEQ 0 (
        CALL ..\logging :Append_To_Screen "Error: :moveFolder: Robocopy copy error. ERRORLEVEL: %ERRORLEVEL%" "OUTPUT_TO_STDOUT" ""
        EXIT /B 1
      )
    ) ELSE (
      CALL ..\logging :Append_To_Screen "Error: :moveFolder: Robocopy folder error." "OUTPUT_TO_STDOUT" ""
    )
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
