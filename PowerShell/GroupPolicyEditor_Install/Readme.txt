In windows 10 Home install the group policy editor by issuing these command in command prompt
with atleast admin privilege level:

REM Commands to be "written" directly into the command prompt by hand:
FOR %F IN ("%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~*.mum") DO (
DISM /Online /NoRestart /Add-Package:"%F"
)
FOR %F IN ("%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~*.mum") DO (
DISM /Online /NoRestart /Add-Package:"%F"
)



REM Commands to add to a bat-file and then run in a command prompt:
FOR %%F IN ("%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~*.mum") DO (
DISM /Online /NoRestart /Add-Package:"%F"
)
FOR %%F IN ("%SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~*.mum") DO (
DISM /Online /NoRestart /Add-Package:"%F"
)


If succesful: The group policy editor can be opened like this:
1. 'Windows-key + r'
2. Type gpedit.msc and hit return key or press ok.
