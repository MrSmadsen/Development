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
CALL %1
EXIT /B 0

:Prepare
REM This is to ensure that the logFile-variable isn't containing anything from a prior backup-execution in the same cmd.exe session.
set "varTargetLogFile="
REM Initializing the global application errorcode variable.
SET varAppErrorCode=0
REM Determine privilige level.
CALL ..\utility_functions :is_cmd_running_with_admin_priviligies_using_whoami
CALL :SetupApplicationMode
CALL :PreconditionalChecks
CALL :SetupTimeAndDate
CALL :PerformAdministrativePreconditionals
CALL :CreateBackupDestinationFolderAndFiles
CALL :ActivateApplicationFunction
EXIT /B 0

:SetupTimeAndDate
SET varDate=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%
SET varDate=%varDate: =0%
EXIT /B 0

REM This function is meant as an option to do file system stuff in elevated user mode (if UAC is enabled).
:PerformAdministrativePreconditionals
IF %varElevatedAdminPriviligies%==NO (
  echo Cmd session is NOT running as elevated Administrator.
) ELSE IF %varElevatedAdminPriviligies%==YES (
  echo Cmd session is running as elevated Administrator.
)
EXIT /B 0

:SetupApplicationMode
set /a varCount=0
SET varMode=NO_APPLICATION_FUNCTION_DEFINED
SET varApplicationFunctionText=NO_APPLICATION_FUNCTION_DEFINED
IF %varAppFunctionBackupFiles%==YES (
SET varMode=a
REM Enable the cleanup function in function utility_functions.cmd->Cleanup
SET varCleanupEnabled=CLEANUP_ENABLED
REM SET varCleanupEnabled=CLEANUP_ASK
SET "varApplicationFunctionText=Archive files"
SET /a varCount += 1
)
IF %varAppFunctionUpdateArchive%==YES (
SET varMode=u
SET "varApplicationFunctionText=Update Existing archive"
SET /a varCount += 1
)
IF %varAppFunctionIntegrityCheck%==YES (
SET varMode=t
SET "varApplicationFunctionText=Archive Integrity Test"
SET /a varCount += 1
)
IF %varAppFunctionExtractFilestoFolder%==YES (
SET varMode=e
SET "varApplicationFunctionText=Extract archive to folder"
SET /a varCount += 1
)
IF %varAppFunctionExtractFilesWithFullFilePath%==YES (
SET varMode=x
SET "varApplicationFunctionText=Extract archive with full paths"
SET /a varCount += 1
)
IF %varAppFunctionVerifyChecksum%==YES (
SET varMode=v
SET "varApplicationFunctionText=Verify the SHA512 checksum"
SET /a varCount += 1
)

IF %varMode%==NO_APPLICATION_FUNCTION_DEFINED (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in Application function configuration. Please check Application Function options in varSettingsFile. Exit" "OUTPUT_TO_STDOUT" ""
)

IF %varCount% EQU 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in Application function configuration. No Application function activated. Please check Application Function options in varSettingsFile. Exit" "OUTPUT_TO_STDOUT" ""
)

IF %varCount% GTR 1 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in Application function configuration. Only 1 application function allowed. Please check Application Function options in varSettingsFile. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:PreconditionalChecks
CALL :PerformGenericPreconditionalChecks

IF %varAppFunctionBackupFiles%==YES (
  CALL :PerformBackupPreconditionalChecks
)
IF %varAppFunctionUpdateArchive%==YES (
  CALL :PerformUpdatePreconditionalChecks
)
IF %varAppFunctionIntegrityCheck%==YES (
  CALL :PerformIntegrityCheckPreconditionalChecks
)
IF %varAppFunctionExtractFilestoFolder%==YES (
  CALL :PerformExtractFilesPreconditionalChecks
)
IF %varAppFunctionExtractFilesWithFullFilePath%==YES (
  CALL :PerformExtractFilesPreconditionalChecks
)
IF %varAppFunctionVerifyChecksum%==YES (
  CALL :PerformVerifyChecksumPreconditionalChecks
)
EXIT /B 0

:PerformGenericPreconditionalChecks
SET "varExecutable=%varArchiverPath%\%varArchiveProgram%"
IF NOT EXIST "%varExecutable%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The archive program not found. %varExecutable%" "OUTPUT_TO_STDOUT" ""
)

SET varCheck=FALSE
IF %varMoveFolders%==YES (
  SET varCheck=TRUE
)
IF %varMoveFoldersBack%==YES (
  SET varCheck=TRUE
)
IF %varCheck%==TRUE (
  setlocal enabledelayedexpansion
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varSrcPathFolder01%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varSrcPathFolder01%" (
      CALL ..\fileSystem :CheckFolderReadAccess
    ) ELSE (
      CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path defined in %varSettingsFile% varSrcPathFolder01 does not exist." "OUTPUT_TO_STDOUT" ""
    )
  )
  
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varSrcPathFolder02%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varSrcPathFolder02%" (
      CALL ..\fileSystem :CheckFolderReadAccess
    ) ELSE (
      CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path defined in %varSettingsFile% varSrcPathFolder02 does not exist." "OUTPUT_TO_STDOUT" ""
    )  
  )
  
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varDstPathFolder01%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varDstPathFolder01%" (
      CALL ..\fileSystem :CheckFolderReadAccess
    ) ELSE (
        CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path defined in %varSettingsFile% varDstPathFolder01 does not exist." "OUTPUT_TO_STDOUT" ""
    )
  )
  
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varDstPathFolder02%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varDstPathFolder02%" (
      CALL ..\fileSystem :CheckFolderReadAccess
    ) ELSE (
      CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Path defined in %varSettingsFile% varDstPathFolder02 does not exist." "OUTPUT_TO_STDOUT" ""
    )
  )
  setlocal disabledelayedexpansion
)

REM Informational
IF NOT EXIST "%varSvnadminPath%" (
  CALL ..\utility_functions :Append_To_LogFile "%varTargetLogFile%" "SvnAdmin.exe not found. %varSvnadminPath%" "OUTPUT_TO_STDOUT" ""
)
REM Informational
IF NOT EXIST "%varSvnPath%" (
CALL ..\utility_functions :Append_To_LogFile "%varTargetLogFile%" "Svn.exe not found. %varSvnPath%" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:PerformBackupPreconditionalChecks
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%varBackupLocation%" "varCheck"
IF !varCheck!==NO (  
  IF EXIST "%varBackupLocation%" (
  ECHO.
  ) ELSE (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varBackupLocation does not exist. Exit." "OUTPUT_TO_STDOUT" ""
  )
)
IF !varCheck!==YES (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% is an url, should be a file path. Part - varBackupLocation" "OUTPUT_TO_STDOUT" ""
)

IF %varExportSvn%==YES (
  IF NOT EXIST "%varSvnadminPath%" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "SvnAdmin.exe not found. %varSvnadminPath%" "OUTPUT_TO_STDOUT" ""
  )
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varRepositoryLocation%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varRepositoryLocation%" (
      CALL ..\fileSystem :CheckFolderReadAccess
    ) ELSE (
      CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varRepositoryLocation does not exist." "OUTPUT_TO_STDOUT" ""
    )  
  )
  IF !varCheck!==YES (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Repository path is an url, the repository path should be a local file path, Part - varRepositoryLocation" "OUTPUT_TO_STDOUT" ""
  )
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varRepositoryDumpLocation%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varRepositoryDumpLocation%" (
      CALL ..\fileSystem :CheckFolderReadAccess
    ) ELSE (
      CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varRepositoryDumpLocation does not exist." "OUTPUT_TO_STDOUT" ""
    )  
  )
  IF !varCheck!==YES (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Repository path is an url, the repository path should be a local file path, Part - varRepositoryDumpLocation" "OUTPUT_TO_STDOUT" ""
  )
)

REM Verify the paths in varFileList
IF EXIST ".\%varFileList%" (
  REM Verify the paths in varFileList
  FOR /f "usebackq delims=" %%x in ("%varFileList%") do (
    IF NOT EXIST "%%x" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The path %%x from %varFileList% does not exist. Exit." "OUTPUT_TO_STDOUT" ""
    )
  )
) ELSE (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The file %varFileList% not found." "OUTPUT_TO_STDOUT" ""
)
setlocal disabledelayedexpansion
EXIT /B 0

REM This is ok in batch scripting due to the GOTO like behaviour.
REM The script just continues from the line it has reached.
:PerformUpdatePreconditionalChecks
:PerformIntegrityCheckPreconditionalChecks
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%varExistingArchivePath%" "varCheck"
IF !varCheck!==NO (
  IF EXIST "%varExistingArchivePath%" (
  ECHO.
  ) ELSE (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchivePath does not exist. Exit." "OUTPUT_TO_STDOUT" ""
  )
)
IF !varCheck!==YES (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% is an url, should be a file path. Part - varBackupLocation" "OUTPUT_TO_STDOUT" ""
)

IF NOT EXIST "%varExistingArchivePath%"\"%varExistingArchiveFileName%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchiveFileName does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

IF "%varMode%"=="u" (
  IF NOT EXIST ".\%varFileList%" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The file %varFileList% not found." "OUTPUT_TO_STDOUT" ""
  )
  REM Verify the paths in varFileList
  FOR /f "usebackq delims=" %%x in ("%varFileList%") do (
    IF NOT EXIST "%%x" (
      CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The path %%x from %varFileList% does not exist. Exit." "OUTPUT_TO_STDOUT" ""
    )
  )
)
setlocal disabledelayedexpansion
EXIT /B 0

:PerformExtractFilesPreconditionalChecks
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%varExistingArchivePath%" "varCheck"
IF !varCheck!==NO (
  IF EXIST "%varExistingArchivePath%" (
  ECHO.
  ) ELSE (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchivePath does not exist. Exit." "OUTPUT_TO_STDOUT" ""
  )
)
IF !varCheck!==YES (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% is an url, should be a file path. Part - varBackupLocation" "OUTPUT_TO_STDOUT" ""
)

set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%varExtractionLocation%" "varCheck"
IF !varCheck!==NO (
  IF EXIST "%varExtractionLocation%" (
  ECHO.
  ) ELSE (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExtractionLocation does not exist. Exit." "OUTPUT_TO_STDOUT" ""
  )
)
IF !varCheck!==YES (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% is an url, should be a file path. Part - varBackupLocation" "OUTPUT_TO_STDOUT" ""
)

IF NOT EXIST "%varExistingArchivePath%"\"%varExistingArchiveFileName%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchiveFileName does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)
setlocal disabledelayedexpansion
EXIT /B 0

:PerformVerifyChecksumPreconditionalChecks
setlocal enabledelayedexpansion
set varCheck=EMPTY
CALL ..\filesystem :CheckIfParamIsUrl "%varExistingArchivePath%" "varCheck"
IF !varCheck!==NO (
  IF EXIST "%varExistingArchivePath%" (
  ECHO.
  ) ELSE (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchivePath does not exist. Exit." "OUTPUT_TO_STDOUT" ""
  )
)
IF !varCheck!==YES (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% is an url, should be a file path. Part - varBackupLocation" "OUTPUT_TO_STDOUT" ""
)

IF NOT EXIST "%varExistingArchivePath%"\"%varExistingArchiveFileName%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchiveFileName does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

IF NOT EXIST "%varExistingChecksumFile%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingChecksumFile does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)
setlocal disabledelayedexpansion
EXIT /B 0

:CreateBackupDestinationFolderAndFiles
IF %varMode%==a (
  CALL :CreateNewFolderWithDate
  CALL :CreateNewArchiveFiles
)
IF %varMode%==u (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
)
IF %varMode%==t (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
)
IF %varMode%==e (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  CALL :PrepareExtraction
)
IF %varMode%==x (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  CALL :PrepareExtraction
)
IF %varMode%==v (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
)
EXIT /B 0

:CreateNewFolderWithDate
ECHO.
SET "varTargetBackupfolder=%varBackupLocation%\%varDate%\"
REM This creates the backup folder with date.
IF EXIST "%varTargetBackupfolder%" (
  ECHO New backupfolder created at: %varTargetBackupfolder%.
) ELSE (
  mkdir "%varTargetBackupfolder%"
  IF %ERRORLEVEL% NEQ 0 (
    CALL  ..\utility_functions :Exception_End "%varTargetLogFile%" "Error mkdir: Couldn't create the backup folder: %varTargetBackupfolder%" "OUTPUT_TO_STDOUT" ""
  )
  ECHO New backupfolder created at: %varTargetBackupfolder%.
)
EXIT /B 0

REM Do not change the texts used to generate files names etc. It will most certainly break the functionality in other functions.
:CreateNewArchiveFiles
ECHO Creating new archive files.
SET "varTargetBackupSet=%varTargetBackupfolder%%varDate%-backup.%varFormat%"
SET "varTargetFileName=%varDate%-backup.%varFormat%"
SET "varTargetLogFile=%varTargetBackupfolder%%varDate%-logfile.txt"
CALL ..\logging :createLogFile "%varTargetLogFile%" "V"
EXIT /B 0

:UseExistingFolderWithDate
ECHO Use existing archive files.
SET "varTargetBackupfolder=%varExistingArchivePath%"
ECHO Using Existing folder at: %varTargetBackupfolder%.
EXIT /B 0

:SetupExistingArchiveFiles
SET "varTargetBackupSet=%varTargetBackupfolder%\%varExistingArchiveFileName%"
SET "varTargetFileName=%varExistingArchiveFileName%"

IF %varMode%==u (
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-UpdateArchive-logfile.txt"
) ELSE IF %varMode%==e (
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-ExtractToFolder-logfile.txt"
) ELSE IF %varMode%==x (
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-ExtractFullPath-logfile.txt"
) ELSE IF %varMode%==t (
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-IntegrityTest-logfile.txt"
) ELSE IF %varMode%==v (
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-VerifyChecksum-logfile.txt"
) ELSE (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in varMode. Exit" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :createLogFile "%varTargetLogFile%" "V"
EXIT /B 0

:PrepareExtraction
setlocal enabledelayedexpansion
IF "%varExtractionLocation%"=="DEFAULT_LOCATION" (
  SET "varExtractionLocation=%varTargetBackupfolder%\ExtractedArchiveContent\"
) ELSE (
  set varCheck=EMPTY
  CALL ..\filesystem :CheckIfParamIsUrl "%varExtractionLocation%" "varCheck"
  IF !varCheck!==NO (
    IF EXIST "%varExtractionLocation%" (
    ECHO.
    )
    IF NOT EXIST "%varExtractionLocation%" (
      REM Maybe mkdir here!
      CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExtractionLocation does not exist. Exit." "OUTPUT_TO_STDOUT" ""    
    )
  )
  IF NOT !varCheck!==NO (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% is an url or incorrectly defined, should be a file path. Part - varBackupLocation" "OUTPUT_TO_STDOUT" ""
  )
)
setlocal disabledelayedexpansion
EXIT /B 0

:ActivateApplicationFunction
IF %varMode%==a (
  CALL :GenerateBackupArchive
) ELSE IF %varMode%==u (
  CALL :UpdateBackupArchive
) ELSE IF %varMode%==t (
  CALL :TestBackupArchiveIntegrity
) ELSE IF %varMode%==e (
  CALL :ExtractBackupArchive
) ELSE IF %varMode%==x (
  CALL :ExtractBackupArchive
) ELSE IF %varMode%==v (
  CALL :VerifyChecksum
) ELSE (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in varMode. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0


:GenerateBackupArchive
IF %varExportSvn%==YES (
  CALL ..\svnRepoFunctions :generateSvnRepositoryDump
)

CALL :MoveMultipleFolders

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to backup files: Time of backup %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backing up the following folders:" "OUTPUT_TO_STDOUT" ""
FOR /f "usebackq delims=" %%x in ("%varFileList%") do (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%%x" "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Format:                            %varFormat%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "CompressionLevel:                  %varCompressionLvl%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                    %varThreadAffinity%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Split archive into volumes:        %varSplitArchiveFile%, VolumeSizeSwitch: %varSplitVolumesize%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Password protect the archive file: %varPassword%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include archive integrity test:    %varIntegrityTest%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Move Folders:                      %varMoveFolders%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Move Folders back:                 %varMoveFoldersBack%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Export SVN repository:             %varExportSvn%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :SetSplitFlag
CALL :SetupCompressionFlags
CALL :DoCompressfiles

IF %varIntegrityTest%==YES (
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "Performing Integrity test of file: %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
  CALL :DoIntegrityTest
  CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
)

CALL :CalculateCrc_SHA512
CALL :MoveMultipleFoldersBack
CALL :End
EXIT /B 0

:UpdateBackupArchive
CALL :SetupUpdateFlags
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to update the archive: Time of ArchiveUpdate %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "UpdateFlags:                       %varUpdateFlags%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :DoUpdateArchive
CALL :End
EXIT /B 0

:TestBackupArchiveIntegrity
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to check integrity of the archive: Time of IntegrityTest %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                    %varThreadAffinity%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :DoIntegrityTest
CALL :End
EXIT /B 0

:ExtractBackupArchive
CALL :SetupExtractionFlags
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to extract archive: Time of FileExtraction %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Overwrite Mode:                    %varOverWriteFiles% - Flags: %varOverWriteFilesFlag%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Extract to:                        %varExtractionLocation%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :DoExtractFiles
CALL :End
EXIT /B 0

:VerifyChecksum
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to verify the checksum/checksums of the archive: Time of checksum verification %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                    %varThreadAffinity%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""


CALL :Verify_SHA512
CALL :End
EXIT /B 0

:MoveMultipleFolders
IF %varMoveFolders%==YES (
  CALL ..\fileSystem :moveFolder "%varSrcPathFolder01%" "%varDstPathFolder01%"
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varSrcPathFolder01%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
  TIMEOUT /T 2
  CALL ..\fileSystem :moveFolder "%varSrcPathFolder02%" "%varDstPathFolder02%"
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varSrcPathFolder02%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
) ELSE IF %varMoveFolders%==NO (
   ECHO.
) ELSE (
   ECHO ERROR in %varSettingsFile%. Is varMoveFolders setup correctly?
   ECHO varMoveFolders_value: %varMoveFolders%
   CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "" "" ""
)
EXIT /B 0

:MoveMultipleFoldersBack
IF %varMoveFoldersBack%==YES (
  CALL ..\fileSystem :moveFolder %varDstPathFolder01% %varSrcPathFolder01%
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varDstPathFolder01%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
  TIMEOUT /T 2
  CALL ..\fileSystem :moveFolder %varDstPathFolder02% %varSrcPathFolder02%
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varDstPathFolder02%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
) ELSE IF %varMoveFoldersBack%==NO (
   ECHO.
) ELSE (
   ECHO ERROR in %varSettingsFile%. Is varMoveFoldersBack setup correctly?
   ECHO varMoveFoldersBack_value: %varMoveFoldersBack%
   CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "" "" ""
)
EXIT /B 0

:SetSplitFlag
SET "varSplitFlag= "
IF %varSplitArchiveFile%==YES (
  IF %varSplitVolumesize%==-v1m (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v2m (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v5m (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v10m (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v100m (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v1g (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v2g (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v5g (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v10g (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE IF %varSplitVolumesize%==-v100g (
    SET varSplitFlag=%varSplitVolumesize%
  ) ELSE (
    ECHO.
    ECHO ERROR in %varSettingsFile%. Continuing without splitting up the archive.
    ECHO.
    SET "varSplitFlag= "
  )
)
EXIT /B 0

:SetupCompressionFlags
CALL :SetupUtcMode
REM Default is on.
SET "varSolidModeFlag= "

IF %varFormat%==7z (
  IF %varSolidMode%==YES (
    SET varSolidModeFlag=-ms=on
  )
  IF %varSolidMode%==NO (
    SET varSolidModeFlag=-ms=off
  )
)
EXIT /B 0

:SetupUpdateFlags
SET "varUpdateFlags= "
IF "%varUpdateMode%"=="DEFAULT_FUNCTIONALITY" (
  SET "varUpdateFlags= "
) ELSE (
  REM Untested feature. Enable on at your own risk. CHeck out https://sevenzip.osdn.jp/chm/cmdline/switches/update.htm for help
  REM :DoUpdateArchive might require an update to get it to work.
  REM SET varUpdateFlags=%varUpdateMode%
  SET "varUpdateFlags= "
)
CALL :SetupUtcMode
EXIT /B 0

:SetupUtcMode
SET "varUtcFlag= "
IF %varZipUtcMode%==YES (
  IF %varFormat%==zip (
    ECHO SETTING UTC MODE.
    SET varUtcFlag=-mtc
  )
)
EXIT /B 0

:SetupExtractionFlags
REM Fallback value is SKIP__EXISTING_FILES
SET "varOverWriteFilesFlag=-aos"
SET varSetOverWriteFlag=EMPTY

IF %varSetOverWriteFlag%==YES (
  REM Assume yes to overwrite.
  IF "%varOverWriteFiles%"=="OVERWRITE_EXISTING_FILES" (
    SET varOverWriteFilesFlag=-aoa
  )
  IF "%varOverWriteFiles%"=="SKIP__EXISTING_FILES" (
    SET varOverWriteFilesFlag=-aos
  )
  IF "%varOverWriteFiles%"=="AUTO_RENAME_EXTRACTING_FILE" (
    SET varOverWriteFilesFlag=-aou
  )
  IF "%varOverWriteFiles%"=="AUTO_RENAME_EXISTING_FILE" (
    SET varOverWriteFilesFlag=-aot
  )
)
EXIT /B 0

:DoCompressfiles
SET varAppErrorCode=0
IF %varPassword%==YES (
  IF NOT %varSecretPassword%==NO (
    REM ECHO varPassword = YES, varSecretPassword = !NO
    "%varArchiverPath%\%varArchiveProgram%" -p%varSecretPassword% %varSplitFlag% %varMode% -t%varFormat% "%varTargetBackupSet%" @"%varFileList%" -xr!thumbs.db %varCompressionLvl% %varThreadAffinity% %varUtcFlag% %varSolidModeFlag%
    EXIT /B 0
  )
  REM ECHO varPassword = YES, varSecretPassword = NO
  "%varArchiverPath%\%varArchiveProgram%" -p %varSplitFlag% %varMode% -t%varFormat% "%varTargetBackupSet%" @"%varFileList%" -xr!thumbs.db %varCompressionLvl% %varThreadAffinity% %varUtcFlag% %varSolidModeFlag%
) else (
  REM ECHO varPassword = NO
  "%varArchiverPath%\%varArchiveProgram%" %varSplitFlag% %varMode% -t%varFormat% "%varTargetBackupSet%" @"%varFileList%" -xr!thumbs.db %varCompressionLvl% %varThreadAffinity% %varUtcFlag% %varSolidModeFlag%
)
SET varAppErrorCode=%ERRORLEVEL%
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation %varAppErrorCode%
EXIT /B 0

:DoUpdateArchive
IF %varFormat%%==7z (
  "%varArchiverPath%\%varArchiveProgram%" %varMode% "%varTargetBackupSet%" @"%varFileList%" -xr!thumbs.db %varThreadAffinity% %varSolidModeFlag% %varUpdateFlags%
) ELSE (
  "%varArchiverPath%\%varArchiveProgram%" %varMode% "%varTargetBackupSet%" @"%varFileList%" -xr!thumbs.db %varThreadAffinity% %varUtcFlag%
)
SET varAppErrorCode=%ERRORLEVEL%
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation %varAppErrorCode%
EXIT /B 0

:DoIntegrityTest
setlocal enabledelayedexpansion
SET "varDir=%varTargetBackupfolder%"
SET varSearchString=!varTargetFileName!
SET varAppErrorCode=0
SET varCheckForSplitFile=NO

REM Find the split file if it exists.
REM All other cases the file is defined in the ini-file.
IF %varAppFunctionBackupFiles%==YES (
  IF %varSplitArchiveFile%==YES (
    SET varCheckForSplitFile=YES
  )
)

IF %varCheckForSplitFile%==YES (
  REM Shows only files in the directory %varDir% in simple output format.
  for /f "delims=" %%F in ('dir "%varDir%" /b /a-d') do (
    echo %%F|findstr /i /b "!varSearchString!.001">nul
    IF !ERRORLEVEL!==0 (
      SET varSearchString=!varSearchString!.001
    )
  )
)
ECHO Testing file: "%varTargetBackupfolder%\!varSearchString!"
"%varArchiverPath%\%varArchiveProgram%" t "%varTargetBackupfolder%\!varSearchString!" * -r
SET varAppErrorCode=!ERRORLEVEL!
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation !varAppErrorCode!
setlocal disabledelayedexpansion
EXIT /B 0

:DoExtractFiles
SET varAppErrorCode=0
"%varArchiverPath%\%varArchiveProgram%" %varMode% "%varTargetBackupSet%" -o%varExtractionLocation% * -r %varOverWriteFilesFlag%
SET varAppErrorCode=%ERRORLEVEL%
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation %varAppErrorCode%
EXIT /B 0

REM This function uses certutil to calculate the checksum.
REM 7zip actually also supports checksum calculation. Example: 7z h -scrcsha256 file.extension.
:CalculateCrc_SHA512
setlocal enabledelayedexpansion

for /f "tokens=1-2 delims=." %%F in ("!varTargetFileName!") do (
  SET varSearchString=%%F.%%G
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "SHA_512 checksums will be calculated for archive files in the backup destination folder." "OUTPUT_TO_STDOUT" ""

SET varTargetChecksumFile=%varTargetBackupfolder%\%varDate%-SHA512.txt
CALL ..\logging :createLogFile "%varTargetChecksumFile%" "V"

SET /a varProcessedFileCount=0
SET /a varFailedFileCount=0
SET /a varFileCount=0
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%F in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  echo %%F|findstr /i /b "!varSearchString!">nul
  IF !ERRORLEVEL!==0 (
    SET /a varFileCount +=1
  )
)

IF %varFileCount% EQU 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating SHA_512 crc failed. No archive files found. Exit." "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "No. of files to process: !varFileCount!" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

set originalDir=%cd%
cd /d "%varTargetBackupfolder%"
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%A in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  cd /d "%originalDir%"
  echo %%A|findstr /i /b "!varSearchString!">nul
  IF !ERRORLEVEL!==0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating SHA_512 crc for file: %%A" "OUTPUT_TO_STDOUT" ""
    cd /d "%varTargetBackupfolder%"
    
    SET/a count=0
    REM Certutil will return 3 lines. We skip the first. We then have to process 2 lines. Hence the usage of count.
    REM Line 1: The SHA512 checksum
    REM Line 2: did certutil process succeed or fail.
    for /f "skip=1 tokens=*" %%F in ('certutil -hashfile "%%A" SHA512') do (
      cd /d "%originalDir%"
      IF NOT !ERRORLEVEL!==0 (
        CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating SHA_512 crc for file: %%A Failed. ErorLevel: !ERROR_LEVEL!. Exit." "OUTPUT_TO_STDOUT" ""
      )
      SET/a count=!count!+1
      REM Put checksum into variable
      IF !count! EQU 1 (
        SET varSHA512ChecksumValue=%%F
      )
      IF !count! EQU 2 (
        SET varCertutilResultStr=%%F
        CALL ..\logging :Append_To_LogFile "%varTargetChecksumFile%" "%%A=!varSHA512ChecksumValue!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_To_LogFile "%varTargetChecksumFile%" "!varCertutilResultStr!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_NewLine_To_LogFile "%varTargetChecksumFile%" "OUTPUT_TO_STDOUT" ""
        SET/a count=0
      )
      cd /d "%varTargetBackupfolder%"
    )
    cd /d "%originalDir%"
    SET /a varProcessedFileCount=!varProcessedFileCount!+1
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating SHA_512 crc for file: %%A performed with success." "" ""
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    cd /d "%varTargetBackupfolder%"
  )
)

cd /d "%originalDir%"
SET /a varFailedFileCount=(!varFileCount!-!varProcessedFileCount!)
IF !varProcessedFileCount! EQU !varFileCount! (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating SHA_512 crc for !varProcessedFileCount! of !varFileCount! file/files. Checksum generation succeeded." "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating SHA_512 crc for !varFailedFileCount! of !varFileCount! file/files." "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Checksum calculation failed." "OUTPUT_TO_STDOUT" ""
  setlocal disabledelayedexpansion
  EXIT /B 1
)
setlocal disabledelayedexpansion
EXIT /B 0

REM This function uses certutil to calculate the checksum.
REM 7zip actually also supports checksum calculation. Example: 7z h -scrcsha256 file.extension.
:Verify_SHA512
setlocal enabledelayedexpansion
REM SET varIsSplitFile=NO

for /f "tokens=1-2 delims=." %%F in ("!varTargetFileName!") do (
  SET varSearchString=%%F.%%G
)

REM Retrieve the dataTime part of the TargetFilename. We use it to find the SHA512 checksum file.
for /f "tokens=1-4 delims=-" %%F in ("!varSearchString!") do (
  SET varTmpStr=%%F-%%G-%%H-%%I
)

SET varTargetChecksumFile=%varTargetBackupfolder%\!varTmpStr!-SHA512.txt
IF NOT EXIST "%varTargetChecksumFile%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Checksumfile %varTargetChecksumFile% does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

SET /a varProcessedFileCount=0
SET /a varFailedFileCount=0
SET /a varFileCount=0
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%F in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  echo %%F|findstr /i /b "!varSearchString!">nul
  IF !ERRORLEVEL!==0 (
    SET /a varFileCount +=1
  )
)

IF %varFileCount% EQU 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating SHA_512 crc failed. No archive files found. Exit." "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "No. of files to process: !varFileCount!" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

set originalDir=%cd%
cd /d "%varTargetBackupfolder%"
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%A in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  cd /d "%originalDir%"
  echo %%A|findstr /i /b "!varSearchString!">nul
  IF !ERRORLEVEL!==0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating SHA_512 crc for file: %%A" "OUTPUT_TO_STDOUT" ""
    cd /d "%varTargetBackupfolder%"
    
    SET/a count=0
    REM Certutil will return 3 lines. We skip the first. We then have to process 2 lines. Hence the usage of count.
    REM Line 1: The SHA512 checksum
    REM Line 2: did certutil process succeed or fail.
    for /f "skip=1 tokens=*" %%F in ('certutil -hashfile "%%A" SHA512') do (
      cd /d "%originalDir%"
      IF NOT !ERRORLEVEL!==0 (
        CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating SHA_512 crc for file: %%A Failed. ErorLevel: !ERROR_LEVEL!. Exit." "OUTPUT_TO_STDOUT" ""
      )
      SET/a count=!count!+1
      REM Put checksum into variable
      IF !count! EQU 1 (
        SET varSHA512ChecksumValue=%%F
      )
      IF !count! EQU 2 (
        SET varCertutilResultStr=%%F
        CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculated: !varSHA512ChecksumValue!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "!varCertutilResultStr!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
        
        FOR /f "usebackq tokens=* delims==" %%x in ("%varTargetChecksumFile%") do (
          echo %%x|findstr /i /b "%%A">nul
          IF !ERRORLEVEL!==0 (
            FOR /f "tokens=2 delims==" %%y in ("%%x") do (
              SET varSHA512ChecksumFromFile=%%y
              CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "From file:  !varSHA512ChecksumFromFile!" "OUTPUT_TO_STDOUT" ""
            )
            IF !varSHA512ChecksumValue! EQU !varSHA512ChecksumFromFile! (
              SET /a varProcessedFileCount=!varProcessedFileCount!+1
            )
          )
        )
        CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
        SET/a count=0
      )
      cd /d "%varTargetBackupfolder%"
    )
  )
)
cd /d "%originalDir%"
SET /a varFailedFileCount=(!varFileCount!-!varProcessedFileCount!)
IF !varProcessedFileCount! EQU !varFileCount! (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating SHA_512 crc for !varProcessedFileCount! of !varFileCount! file/files. Checksum verification succeeded." "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Reading SHA512 checksum from %varTargetChecksumFile% failed for !varFailedFileCount! of !varFileCount! file/files." "OUTPUT_TO_STDOUT" ""
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Checksum verification failed." "OUTPUT_TO_STDOUT" ""
  setlocal disabledelayedexpansion
  EXIT /B 1
)
setlocal disabledelayedexpansion
EXIT /B 0

REM Param_1: Errorlevel provided. The errorlevel is saved just after 7zip execution. to avoid other functions overwriting errorlevel.
:Evaluation
if %1==0 (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: No error - Processing ok" "OUTPUT_TO_STDOUT" ""
) else if %1==1 (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Warning-Non fatal error. But something went wrong" "OUTPUT_TO_STDOUT" ""
) else if %1==2 (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Fatal error" "OUTPUT_TO_STDOUT" ""
) else if %1==7 (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Command line error - Backup failed" "OUTPUT_TO_STDOUT" ""
) else if %1==8 (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Not enough memory for operation - Backup failed" "OUTPUT_TO_STDOUT" ""
) else if %1==255 (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: User stopped the process - Backup failed" "OUTPUT_TO_STDOUT" ""
) else (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Undocumented error - Backup failed" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:End
SET varDateBackupEnded=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%
SET varDateBackupEnded=%varDateBackupEnded: =0%
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Started backup at %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Finished backup at %varDateBackupEnded%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup finished. Backup-result is available in log-file: %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0
