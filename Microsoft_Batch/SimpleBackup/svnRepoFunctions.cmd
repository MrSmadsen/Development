@echo off
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
REM Param_7: Function_Param_6
CALL %1 %2 %3 %4 %5 %6 %7
EXIT /B 0

REM Param_1: Svn repository check out to update
:svnUpdate
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="NO" (
  EXIT /B 1
)

set "execPath=%varSvnPath%"

REM Oberservation:
REM It seems that if spaces in folder names occure in the path before reaching
REM the repository root folder makes svn.exe commands fail on windows 10.
REM Spaces in folder names "inside the repository"-part of the path is not a problem.
"%execPath%" update "%~1"
IF %ERRORLEVEL% NEQ 0 (
  REM cd /d "%varReturnDir%"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnUpdate failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
EXIT /B 0

REM Param_1: Path to svn repository on server.
REM Param_2: Path to destination folder to check repo out to.
REM Param_3: Optional flags to pass to svn.exe.
:svnCheckout
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="NO" (
  EXIT /B 1
)

SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~2" "" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="NO" (
  EXIT /B 1
)

set "execPath=%varSvnPath%"
set "varFlags=%~3"

"%execPath%" co %varFlags% %1 %~2
IF %ERRORLEVEL% NEQ 0 (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnCheckout failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)
EXIT /B 0

REM Param_1: Svn repository check out to get status from
REM Param_2: Optional flags to pass to svn.exe. Example: --no-ignore to check for unversioned files, --quiet to ignore the unversioned files.
REM Param_3: Update before calling status.   (YES | NO)
REM Param_4: Throw exception if out of date. (YES | NO)
REM Param_5: Throw exception if changes are found. (YES | NO)
REM Param_6: Number of acceptable changes.
:CheckWorkingCopyForChanges
SET /a "varNoOfAcceptableChanges=%6"
REM this file contains the result of the SvnStatus call.
IF EXIST .\__VerifyFileStateBeforeCriticalFunction_test.txt (
  CALL ..\fileSystem :deleteFile ".\__VerifyFileStateBeforeCriticalFunction_test.txt" "" ""
)

IF "%~3"=="YES" (
  CALL ..\svnRepoFunctions :svnUpdate "%~1"
)

REM createFile is not really required in batch. But I have the function :-) and in other languages it would probably be relevant.
CALL ..\fileSystem :createFile ".\__VerifyFileStateBeforeCriticalFunction_test.txt" "OVERWRITE_EXISTING_FILE" ""
CALL ..\svnRepoFunctions :svnStatus "%~1" "%~2" "%~4" > .\__VerifyFileStateBeforeCriticalFunction_test.txt

REM First edition of this function exits with exception if any change is found.
SET /a "varLineCnt=0"
FOR /f "usebackq delims=" %%x in (".\__VerifyFileStateBeforeCriticalFunction_test.txt") do (
  SET /a "varLineCnt+=1"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Following changes are found in the working copy:" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%%x" "OUTPUT_TO_STDOUT" ""
)

IF %varLineCnt% LEQ %varNoOfAcceptableChanges% (
  IF %varLineCnt% EQU 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%~1 matches the version stored in the svn repository. No changes found." "OUTPUT_TO_STDOUT" ""
  )
  IF %varLineCnt% GTR 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%varLineCnt% changes found. %varNoOfAcceptableChanges% are acceptable. Workingcopy OK." "OUTPUT_TO_STDOUT" ""
  )
  IF %varLineCnt% LSS 0 (    
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CheckWorkingCopyForChanges - Function implementation error. Integer varLineCnt below 0. Exit." "OUTPUT_TO_STDOUT" ""
  )
)

IF %varLineCnt% GTR %varNoOfAcceptableChanges% (
  IF "%~5"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "%~1 does not match the version in the repository. %varLineCnt% changes found. Only %varNoOfAcceptableChanges% acceptable. Exit." "OUTPUT_TO_STDOUT" ""
  )
  IF NOT "%~5"=="YES" (
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%~1 does not match the version in the repository." "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%varLineCnt% changes found. Only %varNoOfAcceptableChanges% acceptable." "OUTPUT_TO_STDOUT" ""
  )
  EXIT /B 1
)

REM Keeping the file for now. The user will be able to see the changes in the file.
REM IF EXIST .\__VerifyFileStateBeforeCriticalFunction_test.txt (
REM   CALL ..\fileSystem :deleteFile ".\__VerifyFileStateBeforeCriticalFunction_test.txt" "" ""
REM )
EXIT /B 0

REM Param_1: Svn repository check out to get status from
REM Param_2: Optional flags to pass to svn.exe. Example: --no-ignore to check for unversioned files, --quiet to ignore the unversioned files.
REM Param_3: Throw exception if out of date. (YES | NO)
:svnStatus
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="NO" (
  EXIT /B 1
)

REM SET "varReturnDir=%CD%"
REM cd /d "%~1"
set "execPath=%varSvnPath%"
set "varFlags=%~2"

REM "%execPath%" status %varFlags% "%~1"
REM "%execPath%" status %varFlags% "."
"%execPath%" status %varFlags% %~1

IF %ERRORLEVEL% NEQ 0 (
REM cd /d "%varReturnDir%"
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "svnStatus failed. Errorlevel: %ERRORLEVEL%." "OUTPUT_TO_STDOUT" ""
  EXIT /B 1
)

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
for /F "tokens=1,2" %%I in ('"%execPath%" info -r HEAD %~1') do if "%%I"=="Revision:" set "vHEAD=%%J"
for /F "tokens=1,2" %%I in ('"%execPath%" info -r BASE %~1') do if "%%I"=="Revision:" set "vBASE=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~3"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Revision number.
:svnGetRevision
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetRevision - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetRevision - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vHEAD%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Path.
:svnGetPath
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Path:" SET vPATH=%%J

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetPath - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetPath - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vPATH%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - URL.
:svnGetURL
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="URL:" SET vURL=%%J

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetURL - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetURL - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vURL%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Relative URL.
:svnGetRelativeURL
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims=:" %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Relative URL" SET "vRelativeURL=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetRelativeURL - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetRelativeURL - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
REM Remove the leading space - :~1%.
SET "%~3=%vRelativeURL:~1%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Repository Root.
:svnGetRepositoryRoot
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=2-3 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Root:" SET "vRepositoryRoot=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetRepositoryRoot - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetRepositoryRoot - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vRepositoryRoot%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Repository UUID.
:svnGetRepositoryUUID
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims=:" %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Repository UUID" SET "vRepositoryUUID=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetRepositoryUUID - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetRepositoryUUID - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vRepositoryUUID:~1%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Node Kind.
:svnGetNodeKind
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims=:" %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Node Kind" SET "vNodeKind=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetNodeKind - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetNodeKind - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vNodeKind:~1%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Last Changed Author.
:svnGetLastChangedAuthor
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims=:" %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Last Changed Author" SET "vLastChangedAuthor=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetLastChangedAuthor - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetLastChangedAuthor - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vLastChangedAuthor:~1%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Last Changed Rev.
:svnGetLastChangedRev
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=1,2 delims=:" %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Last Changed Rev" SET "vLastChangedRev=%%J"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetLastChangedRev - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetLastChangedRev - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vLastChangedRev:~1%"
EXIT /B 0

REM Param_1: Svn repository to get revision from.
REM Param_2: Throw exception if out of date. (YES | NO)
REM Param_3: returnValue - Last Changed Date.
:svnGetLastChangedDate
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "execPath=%varSvnPath%"

REM HEAD is the latest revision in the repository.
REM BASE is the last revision you have obtained from the repository.
REM They are the same after a successful commit or update.
REM When you make changes, your files differ from the BASE copies
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Revision:" SET "vHEAD=%%J"
FOR /F "tokens=1,2 delims= " %%I IN ('"%execPath%" info -r BASE %~1') DO IF "%%I"=="Revision:" SET "vBASE=%%J"
FOR /F "tokens=3-10 delims= " %%I IN ('"%execPath%" info -r HEAD %~1') DO IF "%%I"=="Date:" SET "vLastChangedDate=%%J %%K %%L %%M %%N %%O %%P"

IF NOT "%vBASE%"=="%vHEAD%" (
  IF "%~2"=="YES" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":svnGetLastChangedDate - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%. Exit." "OUTPUT_TO_STDOUT" ""
  ) ELSE (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" ":svnGetLastChangedDate - The checked out files are not up to date. Revision is: %vBASE%. Revision should be: %vHEAD%." "OUTPUT_TO_STDOUT" ""
  )
)
SET "%~3=%vLastChangedDate%"
EXIT /B 0

REM Param_1: Path to destination folder in the repo.
REM Param_2: Path to file to add.
REM Param_3: Optional flags to pass to svn.exe. Example: --no-ignore to check for unversioned files, --quiet to ignore the unversioned files.
:svnAdd
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="NO" (
  EXIT /B 1
)

SET "varReturnDir=%CD%"
cd /d "%~1"

set "execPath=%varSvnPath%"
set "varFlags=%~3"
"%execPath%" add %varFlags% %~2
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
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%~1" "" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="NO" (
  EXIT /B 1
)

SET "varReturnDir=%CD%"
cd /d "%~1"

set "execPath=%varSvnPath%"
set "varFlags=%~3"
REM "%execPath%" commit %varFlags% -m"%~2"
"%execPath%" commit -m"%~2"
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
set "TIME_STAMP=%date:~3,2%-%date:~0,2%-%date:~6,4%"
set "execPath=%varSvnadminPath%"

REM Repositories...
set "REPO01=%varSvnRepo1%"
set "REPO02=%varSvnRepo2%"

REM Repositories Dump Names...
set "REPO01_DUMP_NAME=%REPO01%_%TIME_STAMP%.full"
set "REPO02_DUMP_NAME=%REPO02%_%TIME_STAMP%.full"

REM Important Locations (Directories)...
set "DUMP_PATH=%varRepositoryDumpLocation%"
set "REPOSITORIES_BASE=%varRepositoryLocation%"

REM "\." is added to non-file paths to normalize the paths correctly.
CALL ..\fileSystem :NormalizeFilePath "%DUMP_PATH%\." "DUMP_PATH"
CALL ..\fileSystem :NormalizeFilePath "%REPOSITORIES_BASE%\." "REPOSITORIES_BASE"

SET "varTmpFileName=Svn_export_%TIME_STAMP%-logfile.txt"
set "varTargetLogFile1=%DUMP_PATH%\%varTmpFileName%"

set "varTargetRepo1=%REPOSITORIES_BASE%\%REPO01%"
set "varTargetFile1=%DUMP_PATH%\%REPO01_DUMP_NAME%"

set "varTargetRepo2=%REPOSITORIES_BASE%\%REPO02%"
set "varTargetFile2=%DUMP_PATH%\%REPO02_DUMP_NAME%"

CALL ..\fileSystem :NormalizeFilePath "%varTargetLogFile1%" "varTargetLogFile1"
CALL ..\fileSystem :NormalizeFilePath "%varTargetFile1%" "varTargetFile1"
CALL ..\fileSystem :NormalizeFilePath "%varTargetFile2%" "varTargetFile2"

REM "\." is added to non-file paths to normalize the paths correctly.
CALL ..\fileSystem :NormalizeFilePath "%varTargetRepo1%\." "varTargetRepo1"
CALL ..\fileSystem :NormalizeFilePath "%varTargetRepo2%\." "varTargetRepo2"

REM ECHO varTargetLogFile1 - %varTargetLogFile1%
REM ECHO varTargetFile1 - %varTargetFile1%
REM ECHO varTargetFile2 - %varTargetFile2%
REM ECHO varTargetRepo1 - %varTargetRepo1%
REM ECHO varTargetRepo2 - %varTargetRepo2%

CALL ..\logging    :createLogFile "%varTargetLogFile1%" ""
CALL ..\fileSystem :createFile "%varTargetFile1%" "OVERWRITE_EXISTING_FILE" ""
CALL ..\fileSystem :createFile "%varTargetFile2%" "OVERWRITE_EXISTING_FILE" ""
CALL ..\logging    :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Exporting svn repositories to a svn dump file: Time of backup %TIME_STAMP%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "SvnExportLog-file: %varTargetLogFile1%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Performing repository export of %REPO01% Repository." "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Svn-Repository: %REPOSITORIES_BASE%\%REPO01%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "SvnDump-File: %DUMP_PATH%\%REPO01_DUMP_NAME%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

"%execPath%" dump "%varTargetRepo1%" >> "%varTargetFile1%"

REM MM-DD-YYYY
set "TIME_STAMP=%date:~3,2%-%date:~0,2%-%date:~6,4%"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Done exporting to file %REPO01_DUMP_NAME% - Time: %TIME_STAMP%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Performing repository export of %REPO02% Repository." "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Svn-Repository: %REPOSITORIES_BASE%\%REPO02%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "SvnDump-File: %DUMP_PATH%\%REPO02_DUMP_NAME%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

"%execPath%" dump "%varTargetRepo2%" >> "%varTargetFile2%"

REM MM-DD-YYYY
set "TIME_STAMP=%date:~3,2%-%date:~0,2%-%date:~6,4%"
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Done exporting to file %REPO02_DUMP_NAME% - Time: %TIME_STAMP%" "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""

REM Remove old svn export files
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Removing old svn export files" "OUTPUT_TO_STDOUT"

forfiles /P "%DUMP_PATH%" /M *.full /D -1 /C "cmd /c del @PATH"
forfiles /P "%DUMP_PATH%" /M *.txt /D -1 /C "cmd /c del @PATH"

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile1%" "Svn export done." "OUTPUT_TO_STDOUT"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile1%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0
