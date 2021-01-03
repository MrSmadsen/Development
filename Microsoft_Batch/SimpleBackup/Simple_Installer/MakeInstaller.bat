@echo off
"C:\Program Files\7-Zip\7z.exe" a -t7z ".\SimpleBackup.7z" @".\SimpleBackupFilesWithoutRootFolder.txt" -xr!thumbs.db -mx5 -mmt -ms=on
copy /b "C:\Program Files\7-Zip\7z.sfx" + .\SimpleBackup.7z .\SimpleBackupIntaller.exe
pause