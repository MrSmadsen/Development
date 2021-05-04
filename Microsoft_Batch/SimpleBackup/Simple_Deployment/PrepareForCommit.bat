@echo off
REM Initializing the lists used for ini-file parameter validation.
SET "varGeneralSettingsFile=..\Settings.ini"
CALL ..\ParameterValidation :initParameterListValues
CALL ..\utility_functions :readBackupSettingsFile "%varGeneralSettingsFile%"

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

IF "%1"=="" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "No path found. Usage: PrepareForCommit.bat "Path_To_Svn_Folder". Exit" "OUTPUT_TO_STDOUT" ""
)

SET "varVersionFile=..\.Version"
SET "varSvnCheckOut=%~1"

REM Get Release Info from SVN.
CALL ..\svnRepoFunctions :svnGetRevision "%varSvnCheckOut%" "YES" "varRevisionNumber"
CALL ..\svnRepoFunctions :svnGetLastChangedAuthor "%varSvnCheckOut%" "YES" "varLastChangedAuthor"
CALL ..\svnRepoFunctions :svnGetLastChangedDate "%varSvnCheckOut%" "YES" "varLastChangedDate"

REM Get Year and month from system.
SET "varDateYear=%DATE:~-4%"
SET "varDateMonth=%DATE:~3,2%"

CALL ..\fileSystem :createFile "%varVersionFile%" "OVERWRITE_EXISTING_FILE" "V"

REM Calculate expected revisionNumber for next release version.
SET /A varExpectedReleaseRevision=1 + %varRevisionNumber%

REM Append info to the release file.
ECHO varMayorVersion=%varDateYear%>>"%varVersionFile%"
ECHO varMinorVersion=%varDateMonth%>>"%varVersionFile%"
ECHO varRevisionNumber=%varExpectedReleaseRevision%>>"%varVersionFile%"
ECHO varReleaseVersion=%varDateYear%.%varDateMonth% Revision %varExpectedReleaseRevision%>>"%varVersionFile%"
ECHO varLastChangedAuthor=%varLastChangedAuthor%>>"%varVersionFile%"
REM ECHO varLastChangedDate=Revision %varRevisionNumber%: %varLastChangedDate%>>"%varVersionFile%"
PAUSE