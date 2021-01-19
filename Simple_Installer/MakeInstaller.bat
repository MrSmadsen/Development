@echo off
"C:\Program Files\7-Zip\7z.exe" a -t7z ".\SimpleBackup.7z" @".\SimpleBackupFiles.txt" -xr!thumbs.db -mx5 -mmt -ms=on

"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" ".\SimpleBackup\.svn" -r
"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" "*.odt" -r
"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" "__VerifyFileStateBeforeCriticalFunction_test.txt" -r
"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" "test.txt" -r
"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" "Howto_Description_original.pdf" -r
"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" ".gitignore" -r
"C:\Program Files\7-Zip\7z.exe" d ".\SimpleBackup.7z" "*.md" -r

copy /b "C:\Program Files\7-Zip\7z.sfx" + ".\SimpleBackup.7z" ".\SimpleBackupIntaller.exe"
pause