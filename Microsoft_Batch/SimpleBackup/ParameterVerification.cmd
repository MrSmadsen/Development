@echo off
REM Version and Github_upload date: 2.12 (22-03-2021)
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

:initParameterListValues
REM (YES | NO) List
SET "itemList_YES-NO[0]=YES"
SET "itemList_YES-NO[1]=NO"

REM (YES_PURGE_DST | YES | NO) List
REM varAppFunctionSyncBackupFolder
REM varBackupSynchronizationDuringBackup
SET "itemList_YES_PURGE_DST-YES-NO[0]=YES_PURGE_DST"
SET "itemList_YES_PURGE_DST-YES-NO[1]=YES"
SET "itemList_YES_PURGE_DST-YES-NO[2]=NO"

REM (OVERWRITE_EXISTING_FILES | SKIP__EXISTING_FILES | AUTO_RENAME_EXTRACTING_FILE | AUTO_RENAME_EXISTING_FILE) List
REM varOverWriteFiles
SET "itemList_WriteMode[0]=OVERWRITE_EXISTING_FILES"
SET "itemList_WriteMode[1]=SKIP__EXISTING_FILES"
SET "itemList_WriteMode[2]=AUTO_RENAME_EXTRACTING_FILE"
SET "itemList_WriteMode[3]=AUTO_RENAME_EXISTING_FILE"

REM (-v1m | -v2m | -v5m | -v10m | -v100m | -v1g | -v2g | -v5g | -v10g | -v100g) List
REM varSplitVolumesize
SET "itemList_SplitVolumesize[0]=-v1m"
SET "itemList_SplitVolumesize[1]=-v2m"
SET "itemList_SplitVolumesize[2]=-v5m"
SET "itemList_SplitVolumesize[3]=-v10m"
SET "itemList_SplitVolumesize[4]=-v100m"
SET "itemList_SplitVolumesize[5]=-v1g"
SET "itemList_SplitVolumesize[6]=-v2g"
SET "itemList_SplitVolumesize[7]=-v5g"
SET "itemList_SplitVolumesize[8]=-v10g"
SET "itemList_SplitVolumesize[9]=-v100g"

REM (0 | 1 | 3 | 5 | 7 | 9) List
REM varCompressionLvl
SET "itemList_SplitCompressionLvl[0]=-mx0"
SET "itemList_SplitCompressionLvl[1]=-mx1"
SET "itemList_SplitCompressionLvl[2]=-mx3"
SET "itemList_SplitCompressionLvl[3]=-mx5"
SET "itemList_SplitCompressionLvl[4]=-mx7"
SET "itemList_SplitCompressionLvl[5]=-mx9"

REM (zip | 7z) List
REM varCompressionLvl
SET "itemList_varFormat[0]=zip"
SET "itemList_varFormat[1]=7z"

REM (D | DA | DAT | DATS | DATSO | DATSOU) List
REM varSyncFolder_DCOPY_FLAGS
REM varSyncFolder_COPY_FLAGS
REM varMoveFolder_DCOPY_FLAGS
REM varMoveFolder_COPY_FLAGS
REM varCopyFolder_DCOPY_FLAGS
REM varCopyFolder_COPY_FLAGS
SET "itemList_COPY_FLAGS[0]=D"
SET "itemList_COPY_FLAGS[1]=DA"
SET "itemList_COPY_FLAGS[2]=DAT"
SET "itemList_COPY_FLAGS[3]=DATS"
SET "itemList_COPY_FLAGS[4]=DATSO"
SET "itemList_COPY_FLAGS[5]=DATSOU"

REM (MD2 | MD4 | MD5 | SHA1 | SHA256 | SHA384 | SHA512) List
REM varChecksumBitlength
SET "itemList_varChecksumBitlength[0]=MD2"
SET "itemList_varChecksumBitlength[1]=MD4"
SET "itemList_varChecksumBitlength[2]=MD5"
SET "itemList_varChecksumBitlength[3]=SHA1"
SET "itemList_varChecksumBitlength[4]=SHA256"
SET "itemList_varChecksumBitlength[5]=SHA384"
SET "itemList_varChecksumBitlength[6]=SHA512"
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_YES-NO
IF NOT DEFINED itemList_YES-NO[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_YES-NO - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~2"=="YES" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="NO" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_YES-NO - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_YES_PURGE_DST-YES-NO
IF NOT DEFINED itemList_YES_PURGE_DST-YES-NO[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_YES_PURGE_DST-YES-NO - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~2"=="YES_PURGE_DST" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="YES" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="NO" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_YES_PURGE_DST-YES-NO - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_WriteMode
IF NOT DEFINED itemList_WriteMode[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_WriteMode - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)

IF "%~2"=="OVERWRITE_EXISTING_FILES" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="SKIP__EXISTING_FILES" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="AUTO_RENAME_EXTRACTING_FILE" (
  CALL :incrementVerificationCounters "%~1"  
) ELSE IF "%~2"=="AUTO_RENAME_EXISTING_FILE" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_WriteMode - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_SplitVolumesize
IF NOT DEFINED itemList_SplitVolumesize[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_SplitVolumesize - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~2"=="-v1m" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v2m" (
  CALL :incrementVerificationCounters "%~1"  
) ELSE IF "%~2"=="-v5m" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v10m" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v100m" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v1g" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v2g" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v5g" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v10g" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-v100g" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_SplitVolumesize - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_SplitCompressionLvl
IF NOT DEFINED itemList_SplitCompressionLvl[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_SplitCompressionLvl - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~2"=="-mx0" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-mx1" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-mx3" (
  CALL :incrementVerificationCounters "%~1"  
) ELSE IF "%~2"=="-mx5" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-mx7" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="-mx9" (
  CALL :incrementVerificationCounters "%~1"  
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_SplitCompressionLvl - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_Format
IF NOT DEFINED itemList_varFormat[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_varFormat - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)
IF "%~2"=="zip" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="7z" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_varFormat - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_COPY_FLAGS
IF NOT DEFINED itemList_COPY_FLAGS[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_COPY_FLAGS - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)

IF "%~2"=="D" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="DA" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="DAT" (
  CALL :incrementVerificationCounters "%~1"  
) ELSE IF "%~2"=="DATS" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="DATSO" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="DATSOU" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_COPY_FLAGS - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
REM Param_2: Variable name
REM Param_3: Variable value
:verifyParameter_ChecksumBitlength
IF NOT DEFINED itemList_varChecksumBitlength[0] (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_ChecksumBitlength - Verification list is not defined. :initParameterListValues might be incorrect. Exit" "OUTPUT_TO_STDOUT" ""
)

IF "%~2"=="MD2" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="MD4" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="MD5" (
  CALL :incrementVerificationCounters "%~1"  
) ELSE IF "%~2"=="SHA1" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="SHA256" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="SHA384" (
  CALL :incrementVerificationCounters "%~1"
) ELSE IF "%~2"=="SHA512" (
  CALL :incrementVerificationCounters "%~1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":verifyParameter_ChecksumBitlength - Value in ini-file parameter %~2 is not OK. Value: %~3. Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0

REM Param_1: Path to settingsfile.
:incrementVerificationCounters
IF "%~1"=="BackupSettings.ini" (
  SET /a "varBackupSettingsVerified+=1"
) ELSE IF  "%~1"=="..\Settings.ini" (  
  SET /a "varGeneralSettingsVerified+=1"
) ELSE (
  CALL ..\utility_functions :Exception_End "NO_FILE_HANDLE" ":incrementVerificationVariable - Incrementation error. Check SettingsFile name. Value: "%~1". Exit" "OUTPUT_TO_STDOUT" ""
)
EXIT /B 0
