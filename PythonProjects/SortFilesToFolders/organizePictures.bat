@echo off

REM python.exe sortFilesToFolders.py -n -f2
REM python.exe sortFilesToFolders.py -of:\resultat1 -n -f2
REM python.exe sortFilesToFolders.py -if:\rodedeBilleder -n -f2
REM python.exe sortFilesToFolders.py -if:\rodedeBilleder -of:\resultat2 -n -f2

REM Uden eventnavn
REM python.exe sortFilesToFolders.py -iD:\Billeder_Video\Usorterede_billeder -oD:\Billeder_Video\Sorteringsoutput -f2 -n -m -eo

REM Med eventnavn
REM python.exe sortFilesToFolders.py -iD:\Billeder_Video\Usorterede_billeder -oD:\Billeder_Video\Sorteringsoutput -f2 -n -m -eo -e eventname

REM Sørens bat-fils linie - Alle filtyper:
python.exe sortFilesToFolders.py -iD:\Billeder_Video\Usorterede_billeder -oD:\Billeder_Video\Sorteringsoutput -f2 -n -m -eo

REM Sørens bat-fils linie - Kun billeder:
REM python.exe sortFilesToFolders.py -iD:\Billeder_Video\Usorterede_billeder -oD:\Billeder_Video\Sorteringsoutput -f2 -n -m

@echo on
pause