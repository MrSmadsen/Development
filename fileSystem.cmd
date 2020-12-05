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
CALL %1 %2 %3 %4
EXIT /B 0

REM Param_1: Path
REM Param_2: Check variable used to verify url-type.
:CheckIfParamIsUrl
set %~2=NOT_VERIFIED
set varParam_1=%~1
set varParam_1=%varParam_1:~0,7%
REM ECHO varParam_1: %varParam_1%
IF [%varParam_1%]==[http://] (
  REM ECHO SET TO YES
  set "%~2=YES"
) ELSE IF [%varParam_1%]==[HTTP://] (
  REM ECHO SET TO YES
  set "%~2=YES"
) ELSE IF [%varParam_1%]==[https://] (
REM ECHO SET TO YES
set "%~2=YES"
) ELSE IF [%varParam_1%]==[HTTPS://] (
  REM ECHO SET TO YES
  set "%~2=YES"
) ELSE (
  REM ECHO SET TO NO
  set "%~2=NO"
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
  set varLastFolder=%%a
)
setlocal disabledelayedexpansion
REM Remove brackets from the string.
set varLastFolderBracketLess=%varLastFolder:~1,-1%
REM Trim trailing whitespace up to 100 chars.
setlocal enabledelayedexpansion
for /l %%a in (1,1,100) do if "!varLastFolderBracketLess:~-1!"==" " set varLastFolderBracketLess=!varLastFolderBracketLess:~0,-1!
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
REM Use existing file
IF EXIST "%~1" (
  IF "%~2"=="USE_EXISTING_FILE" (
    IF "%~3"=="V" ( ECHO Using existing file: %~1. )
    EXIT /B 0
  ) ELSE IF "%~2"=="OVERWRITE_EXISTING_FILE" (
    IF "%~3"=="V" ( ECHO OVER_WRITE_FILE: deleting file: %~1. )
    CALL :deleteFile "%~1" "" "%~3"
    REM Proceed through the code to reach fil creation.
  ) ELSE (
    CALL  ..\utility_functions :Exception_End "" "createFile: Please specify Param_2: REM Param_2: "USE_EXISTING_FILE" OR "OVERWRITE_EXISTING_FILE. Exit" "OUTPUT_TO_STDOUT" ""
  )
)
IF NOT EXIST "%~1" (
  REM Create empty file.
  TYPE NUL > "%~1"
  IF %ERRORLEVEL% NEQ 0 (
    CALL  ..\utility_functions :Exception_End "" "createFile: Could not create file. Exit" "OUTPUT_TO_STDOUT" ""
  )
  IF "%~3"=="V" ( ECHO Created File:  %~1. )
)
EXIT /B 0

REM Param_1: Path and fileName to the file to delete on the filesystem.
REM Param_2: RegularMode "" or QuietMode: "USE_QUIET_MODE".
REM Param_3: Verbose_Mode - "V"
:deleteFile
IF "%~2"=="USE_QUIET_MODE" (
  SET "varDeleteMode=/Q"
)
del "%~1" %varDeleteMode%
IF %ERRORLEVEL% NEQ 0 (
  CALL  ..\utility_functions :Exception_End "" "deleteFile: Could not delete file. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~3"=="V" ( ECHO Deleted file "%~1". )
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
  SET varMoveFolder=NOT_VERIFIED
  
  IF NOT EXIST "%~2" (
    mkdir %2
    IF %ERRORLEVEL% NEQ 0 (
      SET varMoveFolder=NO
      CALL ..\logging :Append_To_Screen "Error: :moveFolder: Destination-Path %2 does not exist.Return" "OUTPUT_TO_STDOUT" ""
      EXIT /B 1
    )
  )

  IF NOT EXIST "%~1" (
    SET varMoveFolder=NO
    CALL ..\logging :Append_To_Screen "Error: :moveFolder: Source-Path %1 does not exist.Return" "OUTPUT_TO_STDOUT" ""
    EXIT /B 1
  )
  
  set varMoveFolder=YES
  
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
REM Param_3: Verbose_Mode - "V"
:getDataFromPath
SET "varGetDataFromPathResult="
IF "%~2"=="REMOVE_QUOTE_SIGNS" (
  SET varGetDataFromPathResult=%~1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FULLY_QUALIFIED_PATH" (
  SET varGetDataFromPathResult=%~f1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="DRIVE_LETTER_ONLY" (
  SET varGetDataFromPathResult=%~d1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="PATH_ONLY" (
  SET varGetDataFromPathResult=%~p1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FILE_NAME_ONLY" (
  SET varGetDataFromPathResult=%~n1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FILE_EXTENSION_ONLY" (
  SET varGetDataFromPathResult=%~x1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="SHORT_NAME_ONLY" (
  SET varGetDataFromPathResult=%~s1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="FILE_ATTRIBUTES" (
  SET varGetDataFromPathResult=%~a1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="DATE-TIME_OF_FILE" (
  SET varGetDataFromPathResult=%~t1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
)
IF "%~2"=="SIZE_OF_FILE" (
  SET varGetDataFromPathResult=%~z1
  IF "%~3"== "V" ( ECHO "%varGetDataFromPathResult%" )
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
