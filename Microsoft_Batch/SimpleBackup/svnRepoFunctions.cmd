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
REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Param_1: Function_To_Be_Called
REM Param_2: Function_Param_1
REM Param_3: Function_Param_2
REM Param_4: Function_Param_3
CALL %1 %2 %3 %4
EXIT /B 0

REM Param_1: Svn repository check out to update
REM Param_2: Optional flags to pass to svn.exe.
:svnUpdate
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%~1" "varCheck"
IF !varCheck!==NO (
    IF NOT EXIST "%~1" (
    echo Path in param 1 does not exist.Return.
    EXIT /B 1
  )
)
IF !varCheck!==YES (
  echo Path is an url. Return.
  EXIT /B 1
)
setlocal disabledelayedexpansion
set execPath="%varSvnPath%"
set "varFlags=%~2"

REM Oberservation:
REM It seems that if spaces in folder names occure in the path before reaching
REM the repository root folder makes svn.exe commands fail on windows 10.
REM Spaces in folder names "inside the repository"-part of the path is not a problem.

REM SET "varReturnDir=%CD%"
REM cd /d "%~1"
REM %execPath% update %varFlags% "."
REM %execPath% update %varFlags% "%~1"

%execPath% update %varFlags% %~1


IF %ERRORLEVEL% NEQ 0 (
  REM cd /d "%varReturnDir%"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnUpdate failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
REM cd /d "%varReturnDir%"
EXIT /B 0

REM Param_1: Path to svn repository on server.
REM Param_2: Path to destination folder to check repo out to.
REM Param_3: Optional flags to pass to svn.exe.
:svnCheckout
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%~1" "varCheck"
IF !varCheck!==NO (
    IF NOT EXIST "%~1" (
    echo Path in param 1 does not exist.Return.
    EXIT /B 1
  )
)
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%~2" "varCheck"
IF !varCheck!==NO (
    IF NOT EXIST "%~2" (
    echo Path in param 1 does not exist.Return.
    EXIT /B 1
  )
)
setlocal disabledelayedexpansion
set execPath="%varSvnPath%"
set "varFlags=%~3"

%execPath% co %varFlags% %1 %~2
IF %ERRORLEVEL% NEQ 0 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnCheckout failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
EXIT /B 0

REM Param_1: Svn repository check out to get status from
REM Param_2: Optional flags to pass to svn.exe. Example: --no-ignore to check for unversioned files in the folder.
:svnStatus
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%~1" "varCheck"
IF !varCheck!==NO (
    IF NOT EXIST "%~1" (
    echo Path in param 1 does not exist.Return.
    EXIT /B 1
  )
)
IF !varCheck!==YES (
  echo Path is an url. Return.
  EXIT /B 1
)
setlocal disabledelayedexpansion

REM SET "varReturnDir=%CD%"
REM cd /d "%~1"
set execPath="%varSvnPath%"
set "varFlags=%~2"

REM %execPath% status %varFlags% "%~1"
REM %execPath% status %varFlags% "."
%execPath% status %varFlags% %~1

IF %ERRORLEVEL% NEQ 0 (
REM cd /d "%varReturnDir%"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnStatus failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
REM echo ON
for /F "tokens=1,2" %%I in ('%execPath% info -r HEAD %~1') do if "%%I"=="Revision:" set vHEAD=%%J
for /F "tokens=1,2" %%I in ('%execPath% info -r BASE %~1') do if "%%I"=="Revision:" set vBASE=%%J
REM echo OFF

IF NOT "%vBASE%"=="%vHEAD%" (
  ECHO vBASE NOT UPDATED
)
REM cd /d "%varReturnDir%"
EXIT /B 0

REM Param_1: Path to destination folder in the repo.
REM Param_2: Path to file to add.
REM Param_3: Optional flags to pass to svn.exe.
:svnAdd
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%~1" "varCheck"
IF !varCheck!==NO (
    IF NOT EXIST "%~1" (
    echo Path in param 1 does not exist.Return.
    EXIT /B 1
  )
)
IF !varCheck!==YES (
  echo Path is an url. Return.
  EXIT /B 1
)
setlocal disabledelayedexpansion

SET "varReturnDir=%CD%"
cd /d "%~1"

set execPath="%varSvnPath%"
set "varFlags=%~3"
%execPath% add %varFlags% %~2
IF %ERRORLEVEL% NEQ 0 (
  cd /d "%varReturnDir%"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnAdd failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
cd /d "%varReturnDir%"
EXIT /B 0


REM Param_1: Path to destination folder in the repo.
REM Param_2: Message
REM Param_3: Optional flags to pass to svn.exe.
:svnCommitAlreadyAddedContent
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%~1" "varCheck"
IF !varCheck!==NO (
    IF NOT EXIST "%~1" (
    echo Path in param 1 does not exist.Return.
    EXIT /B 1
  )
)
IF !varCheck!==YES (
  echo Path is an url. Return.
  EXIT /B 1
)
setlocal disabledelayedexpansion

SET "varReturnDir=%CD%"
cd /d "%~1"

set execPath="%varSvnPath%"
set "varFlags=%~3"
REM %execPath% commit %varFlags% -m"%~2"
%execPath% commit -m"%~2"
IF %ERRORLEVEL% NEQ 0 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnCommit failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  cd /d "%varReturnDir%"
  EXIT /B 1
)
cd /d "%varReturnDir%"
EXIT /B 0

:stop_visualsvn_services
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Stopping VisualSvn services to avoid file system errors when moving repositories." "OUTPUT_TO_STDOUT"

REM VisualSVN Background Job Service
sc stop vsvnjobsvc
sc config vsvnjobsvc start= disabled >> "%varTargetLogFile%"

REM VisualSVN Background Job Service
sc stop VisualSVNServer
sc config VisualSVNServer start= disabled >> "%varTargetLogFile%"

REM VisualSVN Distributed File System Service - This services was deactivated when investigating the services. Therefore it won't be restarted here.
sc stop vdfssvc
sc config vdfssvc start= disabled >> "%varTargetLogFile%"
EXIT /B 0

:start_visualsvn_services
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Restarting VisualSvn services." "OUTPUT_TO_STDOUT"

REM VisualSVN Background Job Service
sc config vsvnjobsvc start= auto >> "%varTargetLogFile%"
sc start vsvnjobsvc >> "%varTargetLogFile%"

REM VisualSVN Background Job Service
sc config VisualSVNServer start= auto >> "%varTargetLogFile%"
sc start VisualSVNServer >> "%varTargetLogFile%"

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

:generateSvnRepositoryDump
REM MM-DD-YYYY
set TIME_STAMP=%date:~3,2%-%date:~0,2%-%date:~6,4%

set "execPath=%varSvnadminPath%"

REM Repositories...
set REPO01=%varSvnRepo1%
set REPO02=%varSvnRepo2%

REM Repositories Dump Names...
set REPO01_DUMP_NAME="%REPO01%_%TIME_STAMP%.full"
set REPO02_DUMP_NAME="%REPO02%_%TIME_STAMP%.full"

REM Important Locations (Directories)...
set "REPOSITORIES_BASE=%varRepositoryLocation%"
set "DUMP_PATH=%varRepositoryDumpLocation%"

SET "varTmpPath=%DUMP_PATH%\"
SET "varTmpFileName=Svn_export_%TIME_STAMP%-logfile.txt"
set "varTargetLogFile1=%varTmpPath%%varTmpFileName%"
ECHO.
CALL ..\logging :createLogFile "%varTargetLogFile1%" "V"

CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Exporting svn repositories to a svn dump file: Time of backup %TIME_STAMP%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "SvnExportLog-file: %varTargetLogFile1%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Performing repository export of %REPO01% Repository." "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Svn-Repository: %REPOSITORIES_BASE%\%REPO01%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "SvnDump-File: %DUMP_PATH%\%REPO01_DUMP_NAME%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

set "varTargetRepo1=%REPOSITORIES_BASE%\%REPO01%"
set "varTargetFile1=%DUMP_PATH%\%REPO01_DUMP_NAME%"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\fileSystem :createFile "%varTargetFile1%" "OVERWRITE_EXISTING_FILE" "V"

"%execPath%" dump "%varTargetRepo1%" >> "%varTargetFile1%"

REM MM-DD-YYYY
set TIME_STAMP=%date:~3,2%-%date:~0,2%-%date:~6,4%
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Done exporting to file %REPO01_DUMP_NAME% - Time: %TIME_STAMP%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Performing repository export of %REPO02% Repository." "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Svn-Repository: %REPOSITORIES_BASE%\%REPO02%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "SvnDump-File: %DUMP_PATH%\%REPO02_DUMP_NAME%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

set "varTargetRepo2=%REPOSITORIES_BASE%\%REPO02%"
set "varTargetFile2=%DUMP_PATH%\%REPO02_DUMP_NAME%"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\fileSystem :createFile "%varTargetFile2%" "OVERWRITE_EXISTING_FILE" "V"

"%execPath%" dump "%varTargetRepo2%" >> "%varTargetFile2%"

REM MM-DD-YYYY
set TIME_STAMP=%date:~3,2%-%date:~0,2%-%date:~6,4%
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Done exporting to file %REPO02_DUMP_NAME% - Time: %TIME_STAMP%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

REM Remove old svn export files
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Removing old svn export files" "OUTPUT_TO_STDOUT"

REM forfiles [/P pathname] [/M searchmask] [/S] [/C command] [/D [+ | -] [{<date> | <days>}]]
REM forfiles /P "d:\brugere\smadsen\Repository_Backup\Svn_Dump" /M *.full /D -1 /C "cmd /c del @PATH"
forfiles /P "%DUMP_PATH%" /M *.full /D -1 /C "cmd /c del @PATH"
forfiles /P "%DUMP_PATH%" /M *.txt /D -1 /C "cmd /c del @PATH"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Svn export done." "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0
