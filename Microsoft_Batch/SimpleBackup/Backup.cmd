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

REM TODO: OUTPUT_DEBUG idea is good. However to be functional an option to enable/disable debuginfo should be added to the script.
REM       If varEnableDebugOutput=YES -> all append_to..... functions will output the string to std_out (and the log).

REM Todo: Would like to re-implement a lot of functions to: (to avoid having every variable accessible in global scope)
Rem :function
REM SETLOCAL
REM SET "_doworkResult=%do_some_work%"
REM ENDLOCAL & SET "_returnVariable=%_doworkResult%"
REM Problem: When the above function structure is called from another function that has used SETLOCAL enableDelayedExpansion
REM the variable _returnVariable is not assigned a value. Haven't found a solution for that problem yet.

REM Set code page to unicode - Requires that the batfile is saved in unicode utf-8 format.
chcp %varCodePage% > nul

REM Param_1: Function_To_Be_Called
CALL %1
EXIT /B 0

:Prepare
SET "varPreparationSucccesful=NO"
REM This is to ensure that the logFile-variable isn't containing anything from a prior backup-execution in the same cmd.exe session.
SET "varTargetLogFile="
REM Initializing the global application errorcode variable.
SET "varAppErrorCode=0"

REM Get SimpleBackup Version info.
SET "varVersionFile=..\Version.info"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varVersionFile%" "varVersionFile" "varResult" "CREATE_NO" "EXCEPTION_NO"
IF "%varResult%"=="YES" (
  SET /a "varVersionInfoSettingsValidated=0"
  CALL ..\utility_functions :readVersionInfo "%varVersionFile%"
) ELSE (
  SET "varReleaseVersion=No VersionInfo Available."
)

REM Determine privilige level.
CALL ..\utility_functions :is_cmd_running_with_admin_priviligies_using_whoami
CALL :SetupApplicationMode
CALL :PreconditionalChecks
CALL :SetupTimeAndDate
CALL :PerformSystemConfigPreconditionals
CALL :CreateBackupDestinationFolderAndFiles
SET "varPreparationSucccesful=YES"
EXIT /B 0

REM Do not change this date variable. The format is used extensively in the script and 
REM changing this requires alot of the code to be changed.
:SetupTimeAndDate
SET "varDate=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%"
SET "varDate=%varDate: =0%"
EXIT /B 0

:PerformSystemConfigPreconditionals
CALL ..\utility_functions :windows_powercfg_DisablePowerDown "%varTemporarilyDisablePowerDown%"

REM This is meant as an option to do file system stuff in elevated user mode (if UAC is enabled).
IF "%varElevatedAdminPriviligies%"=="NO" (
  echo Cmd session is NOT running as elevated Administrator.
) ELSE IF "%varElevatedAdminPriviligies%"=="YES" (
  echo Cmd session is running as elevated Administrator.
)
EXIT /B 0

:PerformSystemConfigPostconditionals
CALL ..\utility_functions :windows_powercfg_EnablePowerDown "%varTemporarilyDisablePowerDown%" "%varSleepTimeout%" "%varHibernationTimeout%" "%varSleepTimeoutBattery%" "%varHibernationTimeoutBattery%"
EXIT /B 0

:SetupApplicationMode
SET /a "varCount=0"
SET "varMode=NO_APPLICATION_FUNCTION_DEFINED"
SET "varApplicationFunctionText=NO_APPLICATION_FUNCTION_DEFINED"
IF "%varAppFunctionBackupFiles%"=="YES" (
SET "varMode=a"
SET "varApplicationFunctionText=Archive files"
SET /a "varCount+=1"
)
IF "%varAppFunctionUpdateArchive%"=="YES" (
SET "varMode=u"
SET "varApplicationFunctionText=Update Existing archive"
SET /a "varCount+=1"
)
IF "%varAppFunctionIntegrityCheck%"=="YES" (
SET "varMode=t"
SET "varApplicationFunctionText=Archive Integrity Test"
SET /a "varCount+=1"
)
IF "%varAppFunctionExtractFilestoFolder%"=="YES" (
SET "varMode=e"
SET "varApplicationFunctionText=Extract archive to folder"
SET /a "varCount+=1"
)
IF "%varAppFunctionExtractFilesWithFullFilePath%"=="YES" (
SET "varMode=x"
SET "varApplicationFunctionText=Extract archive with full paths"
SET /a "varCount+=1"
)
IF "%varAppFunctionValidateChecksum%"=="YES" (
SET "varMode=v"
SET "varApplicationFunctionText=Validate the archive checksum"
SET /a "varCount+=1"
)
IF "%varAppFunctionSyncBackupFolder%"=="YES" (
  SET "varMode=s1"
  SET "varApplicationFunctionText=Synchronize folder to external storage."
  SET /a "varCount+=1"
)
IF "%varAppFunctionSyncBackupFolder%"=="YES_PURGE_DST" (
  SET "varMode=s2"
  SET "varApplicationFunctionText=Synchronize folder to external storage - Purge enabled."
  SET /a "varCount+=1"
)

IF "%varMode%"=="NO_APPLICATION_FUNCTION_DEFINED" (
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

IF "%varAppFunctionBackupFiles%"=="YES" (
  CALL :PerformBackupPreconditionalChecks
)
IF "%varAppFunctionUpdateArchive%"=="YES" (
  CALL :PerformUpdatePreconditionalChecks
)
IF "%varAppFunctionIntegrityCheck%"=="YES" (
  CALL :PerformIntegrityCheckPreconditionalChecks
)
IF "%varAppFunctionExtractFilestoFolder%"=="YES" (
  CALL :PerformExtractFilesPreconditionalChecks
)
IF "%varAppFunctionExtractFilesWithFullFilePath%"=="YES" (
  CALL :PerformExtractFilesPreconditionalChecks
)
IF "%varAppFunctionValidateChecksum%"=="YES" (
  CALL :PerformVerifyChecksumPreconditionalChecks
)
IF "%varAppFunctionSyncBackupFolder%"=="YES" (
  CALL :PerformSyncBackupFolderPreconditionalChecks
)
EXIT /B 0

:PerformGenericPreconditionalChecks
SET "varCheck=FALSE"
IF "%varCheckWorkingCopyChanges%"=="YES" (
  SET "varCheck=TRUE"
)
IF "%varExportSvn%"=="YES" (
  SET "varCheck=TRUE"
)

IF "%varCheck%"=="TRUE" (
  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varSvnadminPath%" "varSvnadminPath" "varResult" "CREATE_NO" "EXCEPTION_YES"

  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varSvnPath%" "varSvnPath" "varResult" "CREATE_NO" "EXCEPTION_YES"
)

IF "%varCheckWorkingCopyChanges%"=="YES" (
  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varSimpleBackupCheckoutPath%" "varSimpleBackupCheckoutPath" "varResult" "CREATE_NO" "EXCEPTION_YES"
  CALL :CheckImportantApplicationFiles
)

IF NOT EXIST "%varArchiveProgram%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The archive program not found. varArchiveProgram: %varArchiveProgram%" "OUTPUT_TO_STDOUT" ""
)

SET "varCheck=FALSE"
IF "%varMoveFolders%"=="YES" (
  SET "varCheck=TRUE"
)
IF "%varMoveFoldersBack%"=="YES" (
  SET "varCheck=TRUE"
)
IF "%varCheck%"=="TRUE" (
  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varSvnadminPath%" "varSvnadminPath" "varResult" "CREATE_NO" "EXCEPTION_YES"

  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varSrcPathFolder01%" "varSrcPathFolder01" "varResult" "CREATE_NO" "EXCEPTION_YES"

  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varSrcPathFolder02%" "varSrcPathFolder02" "varResult" "CREATE_NO" "EXCEPTION_YES"

  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varDstPathFolder01%" "varDstPathFolder01" "varResult" "CREATE_DIR" "EXCEPTION_YES"

  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varDstPathFolder02%" "varDstPathFolder02" "varResult" "CREATE_DIR" "EXCEPTION_YES"
)
EXIT /B 0

:PerformBackupPreconditionalChecks
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varBackupLocation%" "varBackupLocation" "varResult" "CREATE_DIR" "EXCEPTION_YES"

IF "%varBackupSynchronization%"=="YES" (
  CALL :PerformSyncBackupFolderPreconditionalChecks
)

IF "%varBackupSynchronization%"=="YES_PURGE_DST" (
  CALL :PerformSyncBackupFolderPreconditionalChecks
)

IF "%varExportSvn%"=="YES" (
  IF NOT EXIST "%varSvnadminPath%" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "SvnAdmin.exe not found. %varSvnadminPath%" "OUTPUT_TO_STDOUT" ""
  )

  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varRepositoryLocation%" "varRepositoryLocation" "varResult" "CREATE_NO" "EXCEPTION_YES"
  
  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varRepositoryDumpLocation%" "varRepositoryDumpLocation" "varResult" "CREATE_DIR" "EXCEPTION_YES"
)

REM Validate the paths in varFileList
IF EXIST ".\%varFileList%" (
  REM Validate the paths in varFileList
  FOR /f "usebackq delims=" %%x in ("%varFileList%") do (
    IF NOT EXIST "%%x" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The path %%x from %varFileList% does not exist. Exit." "OUTPUT_TO_STDOUT" ""
    )
  )
) ELSE (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The file %varFileList% not found." "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM This is ok in batch scripting due to the GOTO like behaviour.
REM The script just continues from the line it has reached.
:PerformUpdatePreconditionalChecks
:PerformIntegrityCheckPreconditionalChecks
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varExistingArchivePath%" "varExistingArchivePath" "varResult" "CREATE_NO" "EXCEPTION_YES"

IF NOT EXIST "%varExistingArchivePath%\%varExistingArchiveFileName%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchiveFileName does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

IF "%varMode%"=="u" (
  IF NOT EXIST ".\%varFileList%" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The file %varFileList% not found." "OUTPUT_TO_STDOUT" ""
  )
  REM Validate the paths in varFileList
  FOR /f "usebackq delims=" %%x in ("%varFileList%") do (
    IF NOT EXIST "%%x" (
      CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "The path %%x from %varFileList% does not exist. Exit." "OUTPUT_TO_STDOUT" ""
    )
  )
)
EXIT /B 0

:PerformExtractFilesPreconditionalChecks
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varExistingArchivePath%" "varExistingArchivePath" "varResult" "CREATE_NO" "EXCEPTION_YES"

SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varExtractionLocation%" "varExtractionLocation" "varResult" "CREATE_DIR" "EXCEPTION_YES"

IF NOT EXIST "%varExistingArchivePath%\%varExistingArchiveFileName%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchiveFileName does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:PerformVerifyChecksumPreconditionalChecks
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varExistingArchivePath%" "varExistingArchivePath" "varResult" "CREATE_NO" "EXCEPTION_YES"

IF NOT EXIST "%varExistingArchivePath%\%varExistingArchiveFileName%" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path defined in %varSettingsFile% varExistingArchivePath\varExistingArchiveFileName does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:PerformSyncBackupFolderPreconditionalChecks
SET "varResult=EMPTY"
CALL ..\fileSystem :checkIfFileOrFolderExist "%varSyncFolderLocation%" "varSyncFolderLocation" "varResult" "CREATE_DIR" "EXCEPTION_NO"

REM Disable Sync if the syncLocation is not found. That way we can turn the external storage off and on without changing the config file.
IF "%varResult%"=="NO" (
  IF "%varMode%"=="s1" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path in varSyncFolderLocation not found. Exit" "OUTPUT_TO_STDOUT" ""
  ) ELSE IF "%varMode%"=="s2" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Path in varSyncFolderLocation not found. Exit" "OUTPUT_TO_STDOUT" ""
  )
)
EXIT /B 0

REM If it is important to be able to read the file with file changes after the backup a solution could be
REM to add a fileHandle with unique file name for each function call to CheckWorkingCopyForChanges. If no fileHandle is provided the default file name is used.
REM This is not implemented.
:CheckImportantApplicationFiles
REM These files cannot have changes in them!
SET "varBackupCmd=Backup.cmd"
SET "varFileSystemCmd=fileSystem.cmd"
SET "varLoggingCmd=logging.cmd"
SET "varSettingsIni=Settings.ini"
SET "varSvnRepoFunctionsCmd=svnRepoFunctions.cmd"
SET "varUtilityFunctionsCmd=utility_functions.cmd"
SET "varParameterValidationCmd=ParameterValidation.cmd"
SET "varVersionInfofile=Version.info"

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Checking SimpleBackup working copy files for changes:" "OUTPUT_TO_STDOUT" ""
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varBackupCmd%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varFileSystemCmd%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varLoggingCmd%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varSettingsIni%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varSvnRepoFunctionsCmd%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varUtilityFunctionsCmd%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varParameterValidationCmd%" "--quiet" "YES" "YES" "YES" 0
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varVersionInfofile%" "--quiet" "YES" "YES" "YES" 0

REM To count the number of changes inside the file use svn diff. Should be able to do just that.
REM That way we can have a higher certainty that only our accepted changes are what we will find in the file.
REM This is not implemented.
REM This file can have changes to enable/disable raspberry pi image backup.
SET "varMultipleBackupsCmd=Multiple_Backups.cmd"
CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\%varMultipleBackupsCmd%" "--quiet" "YES" "YES" "YES" 1
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0

:CheckFileLoggingCmdForChanges
IF "%varCheckWorkingCopyChanges%"=="YES" (
  CALL ..\svnRepoFunctions :CheckWorkingCopyForChanges "%varSimpleBackupCheckoutPath%\logging.cmd" "--quiet" "YES" "YES" "YES" 0
)
EXIT /B 0

:CreateBackupDestinationFolderAndFiles
IF "%varMode%"=="a" (
  CALL :CreateNewFolderWithDate
  CALL :CreateNewArchiveFiles
  SET "varUseExistingChecksumfile=NO"
)
IF "%varMode%"=="u" (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  SET "varUseExistingChecksumfile=YES"
)
IF "%varMode%"=="t" (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  SET "varUseExistingChecksumfile=YES"
)
IF "%varMode%"=="e" (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  SET "varUseExistingChecksumfile=YES"
  CALL :PrepareExtraction
)
IF "%varMode%"=="x" (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  SET "varUseExistingChecksumfile=YES"
  CALL :PrepareExtraction
)
IF "%varMode%"=="v" (
  CALL :UseExistingFolderWithDate
  CALL :SetupExistingArchiveFiles
  SET "varUseExistingChecksumfile=YES"
)
IF "%varMode%"=="s1" (
  CALL :CreateSyncLogFile
  SET "varUseExistingChecksumfile=NO"
)
IF "%varMode%"=="s2" (
  CALL :CreateSyncLogFile
  SET "varUseExistingChecksumfile=NO"
)
EXIT /B 0

:CreateNewFolderWithDate
ECHO.
SET "varTargetBackupfolder=%varBackupLocation%\%varDate%"
CALL ..\fileSystem :NormalizeFilePath "%varTargetBackupfolder%\." "varTargetBackupfolder"

REM This creates the backup folder with date.
IF EXIST "%varTargetBackupfolder%" (
  ECHO New backupfolder created at: %varTargetBackupfolder%.
) ELSE (
  mkdir "%varTargetBackupfolder%"
  IF NOT EXIST "%varTargetBackupfolder%" (
    CALL  ..\utility_functions :Exception_End "%varTargetLogFile%" "Error mkdir: Couldn't create the backup folder: %varTargetBackupfolder%" "OUTPUT_TO_STDOUT" ""
  )
  ECHO New backupfolder created at: %varTargetBackupfolder%.
)
EXIT /B 0

REM Do not change the texts used to generate files names etc. It will most certainly break the functionality in other functions.
:CreateNewArchiveFiles
ECHO Creating new archive files.
IF "%varGenerateSfxArchive%"=="NO" (
  SET "varTargetBackupSet=%varTargetBackupfolder%\%varDate%-backup.%varFormat%"
  SET "varTargetFileName=%varDate%-backup.%varFormat%"
) ELSE IF "%varGenerateSfxArchive%"=="YES" (
  IF "%varFormat%"=="7z" (  
    SET "varTargetBackupSet=%varTargetBackupfolder%\%varDate%-backup.exe"
    SET "varTargetFileName=%varDate%-backup.exe"
    EXIT /B 0
  )
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CreateNewArchiveFiles - value in varformat must be 7z. Exit" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CreateNewArchiveFiles - value in varGenerateSfxArchive is incorrect. Must be either YES or NO. Exit" "OUTPUT_TO_STDOUT" ""
)

REM Create general logfile.
SET "varTargetLogFileName=%varDate%-logfile.txt"
SET "varTargetLogFile=%varTargetBackupfolder%\%varTargetLogFileName%"
CALL ..\logging :createLogFile "%varTargetLogFile%" ""

REM Create robocopy logfile.
CALL ..\fileSystem :createRobocopyLogFile "%varTargetBackupfolder%" "%varDate%-RoboCopyLogfile.txt"
EXIT /B 0

:CreateSyncLogFile
REM varSyncFolderLocation
SET "varTargetLogFileName=%varDate%-logfile.txt"
SET "varTargetLogFile=%varBackupLocation%\%varDate%-logfile.txt"
CALL ..\logging :createLogFile "%varTargetLogFile%" ""

REM Create robocopy logfile.
CALL ..\fileSystem :createRobocopyLogFile "%varBackupLocation%" "%varDate%-RoboCopyLogfile.txt"
EXIT /B 0

:UseExistingFolderWithDate
ECHO Use existing archive files.
SET "varTargetBackupfolder=%varExistingArchivePath%"
CALL ..\fileSystem :NormalizeFilePath "%varTargetBackupfolder%\." "varTargetBackupfolder"
ECHO Using Existing folder at: %varTargetBackupfolder%.

REM Retrieve existing date timestamp.
CALL ..\fileSystem :getSimpleBackup_DateFolderFromPath "%varTargetBackupfolder%" varExistingDate
ECHO Restrieved timeStamp: %varExistingDate%
EXIT /B 0

:SetupExistingArchiveFiles
SET "varTargetBackupSet=%varTargetBackupfolder%\%varExistingArchiveFileName%"
SET "varTargetFileName=%varExistingArchiveFileName%"

IF "%varMode%"=="u" (
  SET "varTargetLogFileName=%varDate%-UpdateArchive-logfile.txt"
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-UpdateArchive-logfile.txt"
) ELSE IF "%varMode%"=="e" (
  SET "varTargetLogFileName=%varDate%-ExtractToFolder-logfile.txt"
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-ExtractToFolder-logfile.txt"
) ELSE IF "%varMode%"=="x" (
  SET "varTargetLogFileName=%varDate%-ExtractFullPath-logfile.txt"
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-ExtractFullPath-logfile.txt"
) ELSE IF "%varMode%"=="t" (
  SET "varTargetLogFileName=%varDate%-IntegrityTest-logfile.txt"
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-IntegrityTest-logfile.txt"
) ELSE IF "%varMode%"=="v" (
  SET "varTargetLogFileName=%varDate%-VerifyChecksum-logfile.txt"
  SET "varTargetLogFile=%varTargetBackupfolder%\%varDate%-VerifyChecksum-logfile.txt"
) ELSE (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in varMode. Exit" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :createLogFile "%varTargetLogFile%" ""

REM Create robocopy logfile.
CALL ..\fileSystem :createRobocopyLogFile "%varTargetBackupfolder%" "%varDate%-RoboCopyLogfile.txt"
EXIT /B 0

:PrepareExtraction
IF "%varExtractionLocation%"=="DEFAULT_LOCATION" (
  SET "varExtractionLocation=%varTargetBackupfolder%\ExtractedArchiveContent\"
) ELSE (
  SET "varResult=EMPTY"
  CALL ..\fileSystem :checkIfFileOrFolderExist "%varExtractionLocation%" "varExtractionLocation" "varResult" "CREATE_DIR" "EXCEPTION_YES"
)
EXIT /B 0

:ActivateApplicationFunction
IF "%varMode%"=="a" (  
  CALL :GenerateBackupArchive
  
  IF "%varIntegrityTest%"=="YES" (
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing Integrity test of file: %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
    CALL :DoIntegrityTest
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varChecksumValidation%"=="YES" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing checksum validation of file: %varTargetChecksumFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL :ValidateFileChecksum
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varDeleteOldBackupFolders%"=="YES" (
    CALL ..\fileSystem :deleteOldBackups "%varBackupLocation%" "%varDate%"
  )
  
  CALL :End
  
  IF "%varBackupSynchronization%"=="NO" ( CALL :PerformSystemConfigPostconditionals )
  
  REM :End is called before sync'ing to be able to copy the entire logFile to external storage.
  IF "%varBackupSynchronization%"=="YES" IF EXIST "%varSyncFolderLocation%" (
    CALL ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_DISABLED"
    CALL :PerformSystemConfigPostconditionals
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varDate%" "%varTargetLogFileName%" "%varSyncFolderLocation%\%varDate%"
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varDate%" "%varTargetRoboCopyLogFileName%" "%varSyncFolderLocation%\%varDate%"
    CALL ..\logging :Append_To_Screen "Copying SimpleBackup logfile to external storage done." "OUTPUT_TO_STDOUT" ""
  )
  
  IF "%varBackupSynchronization%"=="YES_PURGE_DST" IF EXIST "%varSyncFolderLocation%" (
    CALL ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_ENABLED"
    CALL :PerformSystemConfigPostconditionals
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varDate%" "%varTargetLogFileName%" "%varSyncFolderLocation%\%varDate%"
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varDate%" "%varTargetRoboCopyLogFileName%" "%varSyncFolderLocation%\%varDate%"
    CALL ..\logging :Append_To_Screen "Copying SimpleBackup logfile to external storage done." "OUTPUT_TO_STDOUT" ""
  )
  
  IF NOT EXIST "%varSyncFolderLocation%" IF "%varBackupSynchronization%"=="YES" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronization to external storage skipped. Destination not found." "OUTPUT_TO_STDOUT" ""
    CALL :PerformSystemConfigPostconditionals
  )
  IF NOT EXIST "%varSyncFolderLocation%" IF "%varBackupSynchronization%"=="YES_PURGE_DST" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronization to external storage skipped. Destination not found." "OUTPUT_TO_STDOUT" ""
    CALL :PerformSystemConfigPostconditionals
  )
) ELSE IF "%varMode%"=="u" (
  CALL :UpdateBackupArchive
  
  IF "%varIntegrityTest%"=="YES" (
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing Integrity test of file: %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
    CALL :DoIntegrityTest
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varChecksumValidation%"=="YES" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing checksum validation of file: %varTargetChecksumFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL :ValidateFileChecksum
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )
  
  CALL :End
  
  IF "%varBackupSynchronization%"=="NO" ( CALL :PerformSystemConfigPostconditionals )
  
  REM :End is called before sync'ing to be able to copy the entire logFile to external storage.
  IF "%varBackupSynchronization%"=="YES" IF EXIST "%varSyncFolderLocation%" IF DEFINED varExistingDate (
    CALL ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_DISABLED"
    CALL :PerformSystemConfigPostconditionals
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varExistingDate%" "%varTargetLogFileName%" "%varSyncFolderLocation%\%varExistingDate%"
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varExistingDate%" "%varTargetRoboCopyLogFileName%" "%varSyncFolderLocation%\%varExistingDate%"
    CALL ..\logging :Append_To_Screen "Copying SimpleBackup logfile to external storage done." "OUTPUT_TO_STDOUT" ""
  )

  IF "%varBackupSynchronization%"=="YES_PURGE_DST" IF EXIST "%varSyncFolderLocation%" IF DEFINED varExistingDate (
    CALL ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_ENABLED"
    CALL :PerformSystemConfigPostconditionals
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varExistingDate%" "%varTargetLogFileName%" "%varSyncFolderLocation%\%varExistingDate%"
    CALL ..\fileSystem :copyFile "%varBackupLocation%\%varExistingDate%" "%varTargetRoboCopyLogFileName%" "%varSyncFolderLocation%\%varExistingDate%"
    CALL ..\logging :Append_To_Screen "Copying SimpleBackup logfile to external storage done." "OUTPUT_TO_STDOUT" ""
  )
  
  IF NOT EXIST "%varSyncFolderLocation%" IF "%varBackupSynchronization%"=="YES" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronization to external storage skipped. Destination not found." "OUTPUT_TO_STDOUT" ""
    CALL :PerformSystemConfigPostconditionals
  )
  IF NOT EXIST "%varSyncFolderLocation%" IF "%varBackupSynchronization%"=="YES_PURGE_DST" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronization to external storage skipped. Destination not found." "OUTPUT_TO_STDOUT" ""
    CALL :PerformSystemConfigPostconditionals
  )
) ELSE IF "%varMode%"=="t" (
  CALL :TestBackupArchiveIntegrity
  CALL :End
  CALL :PerformSystemConfigPostconditionals
) ELSE IF "%varMode%"=="e" (
  IF "%varIntegrityTest%"=="YES" (
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing Integrity test of file: %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
    CALL :DoIntegrityTest
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varChecksumValidation%"=="YES" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing checksum validation of file: %varTargetChecksumFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL :ValidateFileChecksum
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )
  
  CALL :ExtractBackupArchive
  CALL :End
  CALL :PerformSystemConfigPostconditionals
) ELSE IF "%varMode%"=="x" (
  IF "%varIntegrityTest%"=="YES" (
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing Integrity test of file: %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
    CALL :DoIntegrityTest
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )

  IF "%varChecksumValidation%"=="YES" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Performing checksum validation of file: %varTargetChecksumFile%" "OUTPUT_TO_STDOUT" ""
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    CALL :ValidateFileChecksum
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
  )
  
  CALL :ExtractBackupArchive
  CALL :End
  CALL :PerformSystemConfigPostconditionals
) ELSE IF "%varMode%"=="v" (
  CALL :VerifyChecksum
  CALL :End
  CALL :PerformSystemConfigPostconditionals
) ELSE IF "%varMode%"=="s1" (
  CALL :SyncBackupFolder
  CALL :End
  CALL :PerformSystemConfigPostconditionals
  CALL ..\fileSystem :copyFile "%varBackupLocation%" "%varTargetLogFileName%" "%varSyncFolderLocation%"
  CALL ..\fileSystem :copyFile "%varBackupLocation%" "%varTargetRoboCopyLogFileName%" "%varSyncFolderLocation%"
  CALL ..\logging :Append_To_Screen "Copying SimpleBackup logfile to external storage done." "OUTPUT_TO_STDOUT" ""
) ELSE IF "%varMode%"=="s2" (
  CALL :SyncBackupFolder
  CALL :End
  CALL :PerformSystemConfigPostconditionals
  CALL ..\fileSystem :copyFile "%varBackupLocation%" "%varTargetLogFileName%" "%varSyncFolderLocation%"
  CALL ..\fileSystem :copyFile "%varBackupLocation%" "%varTargetRoboCopyLogFileName%" "%varSyncFolderLocation%"
  CALL ..\logging :Append_To_Screen "Copying SimpleBackup logfile to external storage done." "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL :PerformSystemConfigPostconditionals
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Error in varMode. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:GenerateBackupArchive
IF "%varExportSvn%"=="YES" (
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
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Simplebackup:                         %varReleaseVersion%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:                 %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                                 %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Format:                               %varFormat%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "CompressionLevel:                     %varCompressionLvl%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                       %varThreadAffinity%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Split archive into volumes:           %varSplitArchiveFile%, VolumeSizeSwitch: %varSplitVolumesize%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Password protect the archive file:    %varPassword%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include archive integrity test:       %varIntegrityTest%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include checksum validation:          %varChecksumValidation%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Checksum algorithm used:              %varChecksumBitlength%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Move Folders:                         %varMoveFolders%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Move Folders back:                    %varMoveFoldersBack%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Export SVN repository:                %varExportSvn%" "OUTPUT_TO_STDOUT" ""
IF "%varDeleteOldBackupFolders%"=="YES" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Delete old backups                    YES" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Delete old backups                    NO" "OUTPUT_TO_STDOUT" ""
)
IF "%varBackupSynchronization%"=="YES" (  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronize to external storage:      YES, (%varSyncFolderLocation%)" "OUTPUT_TO_STDOUT" ""
) ELSE IF "%varBackupSynchronization%"=="YES_PURGE_DST" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronize to external storage:      YES_WITH_PURGE, (%varSyncFolderLocation%)" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronize to external storage:      NO" "OUTPUT_TO_STDOUT" ""
)
IF "%varZipUtcMode%"=="YES" (
  IF "%varFormat%"=="zip" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Zip Utc mode:                         %varZipUtcMode%" "OUTPUT_TO_STDOUT" ""
  )
)
IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:            YES, Mode: %varShutdownDeviceWhenDone%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:            NO" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                          %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                             %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :SetSplitFlag
CALL :SetupCompressionFlags

REM SET "varFunctionName2=Func_DoCompressfiles"
REM ..\utility_functions :logTimeStampB4CommandStart "%varTargetLogFile%" "%varFunctionName2%"
CALL :DoCompressfiles
REM ..\utility_functions :logTimeStamp_CommandFinished "%varTargetLogFile%" "%varFunctionName2%"
CALL :CalculateFileChecksum
CALL :MoveMultipleFoldersBack
EXIT /B 0

:UpdateBackupArchive
CALL :SetupUpdateFlags
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to update the archive:    Time of ArchiveUpdate %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Simplebackup:                      %varReleaseVersion%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "UpdateFlags:                       %varUpdateFlags%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include archive integrity test:    %varIntegrityTest%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include checksum validation:       %varChecksumValidation%" "OUTPUT_TO_STDOUT" ""
IF "%varBackupSynchronization%"=="YES" (  
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronize to external storage:   YES, (%varSyncFolderLocation%)" "OUTPUT_TO_STDOUT" ""
) ELSE IF "%varBackupSynchronization%"=="YES_PURGE_DST" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronize to external storage:   YES_WITH_PURGE, (%varSyncFolderLocation%)" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Synchronize to external storage:   NO" "OUTPUT_TO_STDOUT" ""
)
IF "%varZipUtcMode%"=="YES" (
  IF "%varFormat%"=="zip" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Zip Utc mode:                      %varZipUtcMode%" "OUTPUT_TO_STDOUT" ""
  )
)
IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         YES, Mode: %varShutdownDeviceWhenDone%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         NO" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :DoUpdateArchive
CALL :CalculateFileChecksum
EXIT /B 0

:TestBackupArchiveIntegrity
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to check integrity of the archive: Time of IntegrityTest %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Simplebackup:                      %varReleaseVersion%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                    %varThreadAffinity%" "OUTPUT_TO_STDOUT" ""
IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         YES, Mode: %varShutdownDeviceWhenDone%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         NO" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :DoIntegrityTest
EXIT /B 0

:ExtractBackupArchive
CALL :SetupExtractionFlags
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to extract archive: Time of FileExtraction %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Simplebackup:                      %varReleaseVersion%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Overwrite Mode:                    %varOverWriteFiles% - Flags: %varOverWriteFilesFlag%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Backup-File:                       %varTargetBackupSet%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Extract to:                        %varExtractionLocation%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include archive integrity test:    %varIntegrityTest%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Include checksum validation:       %varChecksumValidation%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         YES, Mode: %varShutdownDeviceWhenDone%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         NO" "OUTPUT_TO_STDOUT" ""
)

CALL :DoExtractFiles
EXIT /B 0

:VerifyChecksum
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Starting to validate the checksum/checksums of the archive: Time of checksum validation %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Simplebackup:                      %varReleaseVersion%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:              %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                              %varMode%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                    %varThreadAffinity%" "OUTPUT_TO_STDOUT" ""
IF NOT "%varShutdownDeviceWhenDone%"=="NO" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         YES, Mode: %varShutdownDeviceWhenDone%" "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Shutdown device when done:         NO" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Log-File:                          %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

CALL :ValidateFileChecksum
EXIT /B 0

:SyncBackupFolder
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Simplebackup:                         %varReleaseVersion%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function:                 %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
IF "%varMode%"=="s1" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                                 %varMode% - PURGE_DISABLED" "OUTPUT_TO_STDOUT" ""
)
IF "%varMode%"=="s2" (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Mode:                                 %varMode% - PURGE_ENABLED" "OUTPUT_TO_STDOUT" ""
)
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                       /MT - Robocopy defaults to 8 threads" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ThreadAffinity:                       /MT - Robocopy defaults to 8 threads" "OUTPUT_TO_STDOUT" ""

IF "%varMode%"=="s1" (
  ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_DISABLED"
)
IF "%varMode%"=="s2" (
  ..\fileSystem :synchronizeFolder "%varBackupLocation%" "%varSyncFolderLocation%" "PURGE_ENABLED"
)
EXIT /B 0

:MoveMultipleFolders
IF "%varMoveFolders%"=="YES" (
  CALL ..\fileSystem :moveFolder "%varSrcPathFolder01%" "%varDstPathFolder01%"
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varSrcPathFolder01%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
  TIMEOUT /T 2
  CALL ..\fileSystem :moveFolder "%varSrcPathFolder02%" "%varDstPathFolder02%"
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varSrcPathFolder02%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
) ELSE IF "%varMoveFolders%"=="NO" (
   ECHO.
) ELSE (
   ECHO ERROR in %varSettingsFile%. Is varMoveFolders setup correctly?
   ECHO varMoveFolders_value: %varMoveFolders%
   CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "" "" ""
)
EXIT /B 0

:MoveMultipleFoldersBack
IF "%varMoveFoldersBack%"=="YES" (
  CALL ..\fileSystem :moveFolder %varDstPathFolder01% %varSrcPathFolder01%
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varDstPathFolder01%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
  TIMEOUT /T 2
  CALL ..\fileSystem :moveFolder %varDstPathFolder02% %varSrcPathFolder02%
  IF %ERRORLEVEL% NEQ 0 (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Error moving folder: %varDstPathFolder02%. Continuing backup procedure." "OUTPUT_TO_STDOUT" ""
  )
) ELSE IF "%varMoveFoldersBack%"=="NO" (
   ECHO.
) ELSE (
   ECHO ERROR in %varSettingsFile%. Is varMoveFoldersBack setup correctly?
   ECHO varMoveFoldersBack_value: %varMoveFoldersBack%
   CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "" "" ""
)
EXIT /B 0

:SetSplitFlag
SET "varSplitFlag= "
IF "%varSplitArchiveFile%"=="YES" (
  IF "%varSplitVolumesize%"=="-v1m" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v2m" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v5m" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v10m" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v100m" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v1g" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v2g" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v5g" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v10g" (
    SET "varSplitFlag=%varSplitVolumesize%"
  ) ELSE IF "%varSplitVolumesize%"=="-v100g" (
    SET "varSplitFlag=%varSplitVolumesize%"
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
CALL :SetupSfxFlag
CALL :SetupPasswordFlag
CALL :SetupNTSecurityInfoFlag
CALL :SetupLinkFlags

REM Default is on.
SET "varSolidModeFlag= "

IF "%varFormat%"=="7z" (
  IF "%varSolidMode%"=="YES" (
    SET "varSolidModeFlag=-ms=on"
  )
  IF "%varSolidMode%"=="NO" (
    SET "varSolidModeFlag=-ms=off"
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
  REM SET "varUpdateFlags=%varUpdateMode%"
  SET "varUpdateFlags= "
)
CALL :SetupUtcMode
EXIT /B 0

:SetupUtcMode
SET "varUtcFlag= "
IF "%varZipUtcMode%"=="YES" (
  IF "%varFormat%"=="zip" (
    SET "varUtcFlag=-mtc"
  )
)
EXIT /B 0

:SetupSfxFlag
SET "varSfxFlag= "
IF "%varGenerateSfxArchive%"=="YES" (
    ECHO SETTING Sfx MODE.
    SET "varSfxFlag=-sfx"
)
EXIT /B 0

:SetupPasswordFlag
SET "varPasswordFlag= "

IF "%varPassword%"=="YES" (
  IF NOT %varSecretPassword%==NO (
  REM ECHO varPassword = YES, varSecretPassword = 'Password'
  SET "varPasswordFlag=-p%varSecretPassword%"
  EXIT /B 0
  )
  REM ECHO varPassword = YES, varSecretPassword = NO
  SET "varPasswordFlag=-p"
) else (
  REM ECHO varPassword = NO  
  SET "varPasswordFlag= "
)
EXIT /B 0

REM Store NT security information
REM Only supported by .wim archives. Not implemented in this script.
:SetupNTSecurityInfoFlag
SET "varNTSecurityInfoFlag= "
REM -sni : store NT security information
IF "%varFormat%"=="wim" (
  SET "varNTSecurityInfoFlag=-sni"
) ELSE (
  SET "varNTSecurityInfoFlag= "
)
EXIT /B 0

REM Only supported by .wim and tar archives. Not implemented in this script.
:SetupLinkFlags
REM -snh : store hard links as links
REM -snl : store symbolic links as links
IF "%varFormat%"=="tar" (
  SET "varLinkFlags=-snh -snl"
) ELSE IF "%varFormat%"=="wim" (
  SET "varLinkFlags=-snh -snl"
) ELSE (
  SET "varLinkFlags= "
)
EXIT /B 0

:SetupExtractionFlags
REM Fallback value is SKIP__EXISTING_FILES
SET "varOverWriteFilesFlag=-aos"
SET "varSetOverWriteFlag=EMPTY"

IF "%varSetOverWriteFlag%"=="YES" (
  REM Assume yes to overwrite.
  IF "%varOverWriteFiles%"=="OVERWRITE_EXISTING_FILES" (
    SET "varOverWriteFilesFlag=-aoa"
  )
  IF "%varOverWriteFiles%"=="SKIP__EXISTING_FILES" (
    SET "varOverWriteFilesFlag=-aos"
  )
  IF "%varOverWriteFiles%"=="AUTO_RENAME_EXTRACTING_FILE" (
    SET "varOverWriteFilesFlag=-aou"
  )
  IF "%varOverWriteFiles%"=="AUTO_RENAME_EXISTING_FILE" (
    SET "varOverWriteFilesFlag=-aot"
  )
)
EXIT /B 0

:DoCompressfiles
SET "varAppErrorCode=0"
"%varArchiveProgram%" %varPasswordFlag% %varSplitFlag% %varMode% %varLinkFlags% %varNTSecurityInfoFlag% %varSfxFlag% -t%varFormat% "%varTargetBackupSet%" @"%varFileList%" %varCompressionLvl% %varThreadAffinity% %varUtcFlag% %varSolidModeFlag%
SET "varAppErrorCode=%ERRORLEVEL%"
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation %varAppErrorCode%
EXIT /B 0

:DoUpdateArchive
IF "%varFormat%"=="7z" (
  "%varArchiveProgram%" %varMode% "%varTargetBackupSet%" @"%varFileList%" %varThreadAffinity% %varSolidModeFlag% %varUpdateFlags%
) ELSE (
  "%varArchiveProgram%" %varMode% "%varTargetBackupSet%" @"%varFileList%" %varThreadAffinity% %varUtcFlag%
)
SET "varAppErrorCode=%ERRORLEVEL%"
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation %varAppErrorCode%
EXIT /B 0

:DoIntegrityTest
SETLOCAL enabledelayedexpansion
SET "varDir=%varTargetBackupfolder%"
SET "varSearchString=!varTargetFileName!"
SET "varAppErrorCode=0"
SET "varCheckForSplitFile=NO"

REM Find the split file if it exists.
REM All other cases the file is defined in the ini-file.
IF "%varAppFunctionBackupFiles%"=="YES" (
  IF "%varSplitArchiveFile%"=="YES" (
    SET "varCheckForSplitFile=YES"
  )
)

IF "%varCheckForSplitFile%"=="YES" (
  REM Shows only files in the directory %varDir% in simple output format.
  for /f "delims=" %%F in ('dir "%varDir%" /b /a-d') do (
    echo %%F|findstr /i /b "!varSearchString!.001">nul
    IF "!ERRORLEVEL!"=="0" (
      SET "varSearchString=!varSearchString!.001"
    )
  )
)
ECHO Testing file: "%varTargetBackupfolder%\!varSearchString!"
"%varArchiveProgram%" t "%varTargetBackupfolder%\!varSearchString!" * -r
SET "varAppErrorCode=!ERRORLEVEL!"
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation !varAppErrorCode!
SETLOCAL disabledelayedexpansion & ENDLOCAL
EXIT /B 0

REM To support extracting to the "corrected" drive add the 7zip flag -spf/-spf2(no_drive_letter) as an option in the ini-file.
REM This will enable fully qualified path support. Currently the files are NOT extracted to their original fully qualified path,
REM but into the output folder supplied to the extraction function.
:DoExtractFiles
SET "varAppErrorCode=0"
"%varArchiveProgram%" %varMode% "%varTargetBackupSet%" -o%varExtractionLocation% * -r %varOverWriteFilesFlag%
SET "varAppErrorCode=%ERRORLEVEL%"
REM The evaluation function does not work properly when called from within SETLOCAL
CALL :Evaluation %varAppErrorCode%
EXIT /B 0

REM This function uses certutil to calculate the checksum.
REM 7zip actually also supports checksum calculation. Example: 7z h -scrcsha256 file.extension.
:CalculateFileChecksum
SETLOCAL enabledelayedexpansion
SET "varTargetChecksumFile=NOT_DEFINED"

IF NOT "%varUseExistingChecksumfile%"=="NO" IF NOT "%varUseExistingChecksumfile%"=="YES" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CalculateFileChecksum: Option varUseExistingChecksumfile error. Check value. Exit." "OUTPUT_TO_STDOUT" ""
)

REM Generate the searchPattern to find archive files and checksum file (If varUseExistingChecksumfile==YES).
for /f "tokens=1-2 delims=." %%F in ("!varTargetFileName!") do (
  SET "varSearchString=%%F.%%G"
)

IF "%varUseExistingChecksumfile%"=="NO" (
  SET "varTargetChecksumFile=%varTargetBackupfolder%\%varDate%-Checksum-%varChecksumBitlength%.txt"
)
IF "%varUseExistingChecksumfile%"=="YES" (
  IF EXIST "%varTargetBackupfolder%\%varExistingChecksumFile%" (
    SET "varTargetChecksumFile=%varTargetBackupfolder%\%varExistingChecksumFile%"
  ) ELSE (
    REM Retrieve the dataTime part of the TargetFilename. We use it to find the checksum file.
    for /f "tokens=1-4 delims=-" %%F in ("!varSearchString!") do (
      SET "varTmpStr=%%F-%%G-%%H-%%I-Checksum-*"
    )
    REM Shows only files in the directory %varDir% in simple output format.
    for /f "delims=" %%F in ('dir "%varTargetBackupfolder%" /b /a-d') do (
      echo %%F|findstr /i /b "!varTmpStr!">nul
      IF "!ERRORLEVEL!"=="0" (
        SET "varTargetChecksumFile=%varTargetBackupfolder%\%%F"
      )
    )
  )
)

IF "!varTargetChecksumFile!"=="NOT_DEFINED" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CalculateFileChecksum: No checksum file found in folder: %varTargetBackupfolder%. Exit." "OUTPUT_TO_STDOUT" ""
)

REM Overwrite the file to avoid the old checksum(s).
CALL ..\fileSystem :createFile "!varTargetChecksumFile!" "OVERWRITE_EXISTING_FILE" "V"

IF NOT EXIST "!varTargetChecksumFile!" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Checksumfile %varTargetChecksumFile% does not exist. CreateFile failed. Exit." "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "%varChecksumBitlength% checksums will be calculated for archive files in the backup destination folder." "OUTPUT_TO_STDOUT" ""

REM Find the archive files to base the calculations on.
SET /a "varProcessedFileCount=0"
SET /a "varFailedFileCount=0"
SET /a "varFileCount=0"
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%F in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  echo %%F|findstr /i /b "!varSearchString!">nul
  IF "!ERRORLEVEL!"=="0" (
    SET /a "varFileCount+=1"
  )
)

IF %varFileCount% EQU 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating %varChecksumBitlength% checksum failed. No archive files found. Exit." "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "No. of files to process: !varFileCount!" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

SET "originalDir=%cd%"
cd /d "%varTargetBackupfolder%"
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%A in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  cd /d "%originalDir%"
  echo %%A|findstr /i /b "!varSearchString!">nul
  IF "!ERRORLEVEL!"=="0" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating %varChecksumBitlength% checksum for file: %%A" "OUTPUT_TO_STDOUT" ""
    cd /d "%varTargetBackupfolder%"
    
    SET /a "count=0"
    REM Certutil will return 3 lines.
    REM Line 1: SHA algorithm and file id
    REM Line 2: The checksum
    REM Line 3: did certutil process succeed or fail.
    for /f "tokens=*" %%F in ('certutil -hashfile "%%A" %varChecksumBitlength%') do (
      cd /d "%originalDir%"
      IF NOT !ERRORLEVEL!==0 (
        CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CalculateFileChecksum - Calculating %varChecksumBitlength% checmsum for file: %%A Failed. ErorLevel: !ERROR_LEVEL!. Exit." "OUTPUT_TO_STDOUT" ""
      )
      SET /a "count=!count!+1"
      REM Put checksum into variable
      IF !count! EQU 1 (
        SET "varSHAChecksumJobDefinition=%%F"
      )
      IF !count! EQU 2 (
        SET "varSHAChecksumValue=%%F"
      )
      IF !count! EQU 3 (
        REM If enabled (ini-file option: varCheckWorkingCopyChanges) the file logging.cmd is checked for changes.
        REM This is to avoid writing trailing white space after the checksum.
        CALL :CheckFileLoggingCmdForChanges
        SET "varCertutilResultStr=%%F"
        CALL ..\logging :Append_To_LogFile "%varTargetChecksumFile%" "!varSHAChecksumJobDefinition!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_To_LogFile "%varTargetChecksumFile%" "%%A=!varSHAChecksumValue!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_To_LogFile "%varTargetChecksumFile%" "!varCertutilResultStr!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_NewLine_To_LogFile "%varTargetChecksumFile%" "OUTPUT_TO_STDOUT" ""
        SET /a "count=0"
      )
      cd /d "%varTargetBackupfolder%"
    )
    cd /d "%originalDir%"
    SET /a "varProcessedFileCount=!varProcessedFileCount!+1"
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating %varChecksumBitlength% checksum for file: %%A performed with success." "" ""
    CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
    cd /d "%varTargetBackupfolder%"
  )
)

cd /d "%originalDir%"
SET /a "varFailedFileCount=(!varFileCount!-!varProcessedFileCount!)"
IF !varProcessedFileCount! EQU !varFileCount! (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating %varChecksumBitlength% checksum for !varProcessedFileCount! of !varFileCount! file/files. Checksum generation succeeded." "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating %varChecksumBitlength% checksum for !varFailedFileCount! of !varFileCount! file/files." "OUTPUT_TO_STDOUT" ""
  SETLOCAL disabledelayedexpansion & ENDLOCAL
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":CalculateFileChecksum: Checksum calculation failed. Exit." "OUTPUT_TO_STDOUT" ""
)
SETLOCAL disabledelayedexpansion & ENDLOCAL
EXIT /B 0

REM This function uses certutil to calculate the checksum.
REM 7zip actually also supports checksum calculation. Example: 7z h -scrcsha256 file.extension.
:ValidateFileChecksum
SETLOCAL enabledelayedexpansion
SET "varTargetChecksumFile=NOTE_DEFINED"

IF NOT "%varUseExistingChecksumfile%"=="NO" IF NOT "%varUseExistingChecksumfile%"=="YES" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":ValidateFileChecksum: Option varUseExistingChecksumfile error. Check value. Exit." "OUTPUT_TO_STDOUT" ""  
)

REM Generate the searchPattern to find archive files and checksum file if the existing checksum file does not exist.
for /f "tokens=1-2 delims=." %%F in ("!varTargetFileName!") do (
  SET "varSearchString=%%F.%%G"
)

IF "%varUseExistingChecksumfile%"=="NO" (
  IF NOT "%varMode%"=="a" (
    CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":ValidateFileChecksum: varUseExistingChecksumfile = No. Error, verifyChecksum should always look for an existing checksum file, if varMode != a. Exit." "OUTPUT_TO_STDOUT" ""
  )  
  SET "varTargetChecksumFile=%varTargetBackupfolder%\%varDate%-Checksum-%varChecksumBitlength%.txt"
)

IF "%varUseExistingChecksumfile%"=="YES" IF "%varMode%"=="a" (  
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":ValidateFileChecksum: critical error 1, Mode not supported. Incorrected setup in ActivateApplicationFunction. Exit." "OUTPUT_TO_STDOUT" ""
)

IF "%varUseExistingChecksumfile%"=="YES" IF "%varMode%"=="u" (
  IF EXIST "%varTargetBackupfolder%\%varExistingChecksumFile%" (
    SET "varTargetChecksumFile=%varTargetBackupfolder%\%varExistingChecksumFile%"
  )
)

IF "%varUseExistingChecksumfile%"=="YES" IF NOT "%varMode%"=="u" (
  IF EXIST "%varTargetBackupfolder%\%varExistingChecksumFile%" (
    SET "varTargetChecksumFile=%varTargetBackupfolder%\%varExistingChecksumFile%"
  )
  IF NOT EXIST "%varTargetBackupfolder%\%varExistingChecksumFile%" (
    REM Retrieve the dataTime part of the TargetFilename. We use it to find the checksum file.
    for /f "tokens=1-4 delims=-" %%F in ("!varSearchString!") do (
      SET "varTmpStr=%%F-%%G-%%H-%%I-Checksum-*"
    )
    REM Shows only files in the directory %varDir% in simple output format.
    for /f "delims=" %%F in ('dir "%varTargetBackupfolder%" /b /a-d') do (
      echo %%F|findstr /i /b "!varTmpStr!">nul
      IF "!ERRORLEVEL!"=="0" (
        SET "varTargetChecksumFile=%varTargetBackupfolder%\%%F"
      )
    )
  )
)

IF NOT DEFINED varTargetChecksumFile (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":ValidateFileChecksum: critical error 2, varTargetChecksumFile not defined. Exit." "OUTPUT_TO_STDOUT" ""
)

IF NOT EXIST "!varTargetChecksumFile!" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Checksumfile %varTargetChecksumFile% does not exist. Exit." "OUTPUT_TO_STDOUT" ""
)

REM Find the used bitLength by reading the first word on the first line of the checksum file.
SET /a "count=0"
SET "varSHABitLength=SHA000"
REM Iterate through the file but only store word 1 from line 1. This might be slow if the file has many lines.
FOR /f "usebackq tokens=1 delims= " %%x in ("%varTargetChecksumFile%") do (
  IF !count! EQU 0 (
    SET "varSHABitLength=%%x"
    SET /a "count=!count!+1"
  )
)
IF "!varSHABitLength!"=="SHA000" (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "ValidateFileChecksum: SHA bitlength revtrieval error. Exit." "OUTPUT_TO_STDOUT" ""
)

REM Find the archive files to base the calculations on.
SET /a "varProcessedFileCount=0"
SET /a "varFailedFileCount=0"
SET /a "varFileCount=0"
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%F in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  echo %%F|findstr /i /b "!varSearchString!">nul
  IF "!ERRORLEVEL!"=="0" (
    SET /a "varFileCount+=1"
  )
)

IF %varFileCount% EQU 0 (
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating !varSHABitLength! checksum failed. No archive files found. Exit." "OUTPUT_TO_STDOUT" ""
)

CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Verifying archive file:            %varTargetBackupfolder%\!varTargetFileName!" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Comparing values in checksum file: !varTargetChecksumFile!" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "No. of files to process: !varFileCount!" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""

SET "originalDir=%cd%"
cd /d "%varTargetBackupfolder%"
REM Shows only files in the directory %varTargetBackupfolder% in simple output format.
for /f "delims=" %%A in ('dir "%varTargetBackupfolder%" /b /a-d') do (
  cd /d "%originalDir%"
  echo %%A|findstr /i /b "!varSearchString!">nul
  IF "!ERRORLEVEL!"=="0" (
    CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating !varSHABitLength! checksum for file: %%A" "OUTPUT_TO_STDOUT" ""
    cd /d "%varTargetBackupfolder%"
    
    SET /a "count=0"
    REM Certutil will return 3 lines.
    REM Line 1: SHA algorithm and file id
    REM Line 2: The checksum
    REM Line 3: did certutil process succeed or fail.
    for /f "tokens=*" %%F in ('certutil -hashfile "%%A" !varSHABitLength!') do (
      cd /d "%originalDir%"
      IF NOT !ERRORLEVEL!==0 (
        CALL ..\utility_functions :Exception_End "%varTargetLogFile%" "Calculating !varSHABitLength! checksum for file: %%A Failed. ErorLevel: !ERROR_LEVEL!. Exit." "OUTPUT_TO_STDOUT" ""
      )
      SET /a "count=!count!+1"
      REM Put checksum into variable
      IF !count! EQU 1 (
        SET "varSHAChecksumJobDefinition=%%F"
      )
      IF !count! EQU 2 (
        SET "varSHA512ChecksumValue=%%F"
      )
      IF !count! EQU 3 (
        REM If enabled (ini-file option: varCheckWorkingCopyChanges) the file logging.cmd is checked for changes.
        REM This is to avoid writing trailing white space after the checksum.
        CALL :CheckFileLoggingCmdForChanges
        SET "varCertutilResultStr=%%F"
        CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "!varSHAChecksumJobDefinition!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculated: !varSHA512ChecksumValue!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "!varCertutilResultStr!" "OUTPUT_TO_STDOUT" ""
        CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
        
        FOR /f "usebackq tokens=* delims==" %%x in ("%varTargetChecksumFile%") do (
          echo %%x|findstr /i /b "%%A">nul
          IF "!ERRORLEVEL!"=="0" (
            FOR /f "tokens=2 delims==" %%y in ("%%x") do (
              SET "varSHA512ChecksumFromFile=%%y"
              CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "From file:  !varSHA512ChecksumFromFile!" "OUTPUT_TO_STDOUT" ""
            )
            IF !varSHA512ChecksumValue! EQU !varSHA512ChecksumFromFile! (
              SET /a "varProcessedFileCount=!varProcessedFileCount!+1"
            )
          )
        )
        CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
        SET /a "count=0"
      )
      cd /d "%varTargetBackupfolder%"
    )
  )
)
cd /d "%originalDir%"
SET /a "varFailedFileCount=(!varFileCount!-!varProcessedFileCount!)"
IF !varProcessedFileCount! EQU !varFileCount! (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Calculating !varSHABitLength! checksum for !varProcessedFileCount! of !varFileCount! file/files. Checksum validation succeeded." "OUTPUT_TO_STDOUT" ""
) ELSE (
  CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Reading checksum from %varTargetChecksumFile% failed for !varFailedFileCount! of !varFileCount! file/files." "OUTPUT_TO_STDOUT" ""
  SETLOCAL disabledelayedexpansion & ENDLOCAL
  CALL ..\utility_functions :Exception_End "%varTargetLogFile%" ":ValidateFileChecksum: Checksum calculation failed. Exit." "OUTPUT_TO_STDOUT" ""
)
SETLOCAL disabledelayedexpansion & ENDLOCAL
EXIT /B 0

REM Param_1: Errorlevel provided. The errorlevel is saved just after 7zip execution. to avoid other functions overwriting errorlevel.
:Evaluation
if "%1"=="0" (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: No error - Processing ok" "OUTPUT_TO_STDOUT" ""
) else if "%1"=="1" (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Warning-Non fatal error. But something went wrong" "OUTPUT_TO_STDOUT" ""
) else if "%1"=="2" (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Fatal error" "OUTPUT_TO_STDOUT" ""
) else if "%1"=="7" (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Command line error - Backup failed" "OUTPUT_TO_STDOUT" ""
) else if "%1"=="8" (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Not enough memory for operation - Backup failed" "OUTPUT_TO_STDOUT" ""
) else if "%1"=="255" (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: User stopped the process - Backup failed" "OUTPUT_TO_STDOUT" ""
) else (
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: %1" "OUTPUT_TO_STDOUT" ""
   CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "ERRORLEVEL: Undocumented error - Backup failed" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

:End
SET "varDateBackupEnded=%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%-%TIME:~3,2%"
SET "varDateBackupEnded=%varDateBackupEnded: =0%"
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Application function: %varApplicationFunctionText%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Started at %varDate%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "Finished at %varDateBackupEnded%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_To_LogFile "%varTargetLogFile%" "SimpleBackup finished. Result is available in log-file: %varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
CALL ..\logging :Append_NewLine_To_LogFile "%varTargetLogFile%" "OUTPUT_TO_STDOUT" ""
EXIT /B 0
