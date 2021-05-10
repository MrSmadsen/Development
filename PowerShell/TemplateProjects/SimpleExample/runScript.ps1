#If debugging and verbose output should be disabled: Usage: .\runScript.ps1
#If debugging and verbose output should be enabled:  Usage:  .\runScript.ps1 -enableDebug -enableVerbose
param (
    [switch]$enableDebug,
    [switch]$enableVerbose
)

#Importing module:
# For running when working:

# Starting the script using the manifest file is still abit buggy, but it does run if your execution policy is set up to allow scripts.
# Import-Module -Name .\mSimpleExample\mSimpleExample.psd1

Import-Module -Name .\mSimpleExample\mSimpleExample.psm1

# For debugging: -Force will reimport the module without having to restart the powershell session.  
  # Import-Module -Name .\mSimpleExample\mSimpleExample.psm1 -verbose -Force
  #Import-Module -Name .\mSimpleExample\mSimpleExample.psm1 -Force
  #Get-Module .\mSimpleExample\mSimpleExample.psm1 -ListAvailable

  #Import-Module -Name .\mSimpleExample\mSimpleExample.psd1 -verbose -Force
  #Get-Module .\mSimpleExample\mSimpleExample.psd1 -ListAvailable
    
userModule_SimpleExample_main $enableDebug $enableVerbose

# Remove-Module -Name .\mSimpleExample\mSimpleExample.psm1
# Remove-Module -Name .\mSimpleExample\mSimpleExample.psd1