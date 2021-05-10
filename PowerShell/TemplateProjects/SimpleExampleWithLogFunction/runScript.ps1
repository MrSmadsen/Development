#If debugging and verbose output should be disabled: Usage: .\runScript.ps1
#If debugging and verbose output should be enabled:  Usage:  .\runScript.ps1 -enableDebug -enableVerbose
param (
    [switch]$enableDebug,
    [switch]$enableVerbose
)

#Importing module:
# For running when working:

# Starting the script using the manifest file is still abit buggy, but it does run if your execution policy is set up to allow scripts.
# Import-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psd1

Import-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psm1

# For debugging: -Force will reimport the module without having to restart the powershell session.
  # Import-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psm1 -verbose -Force
  #Import-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psm1 -Force
  #Get-Module .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psm1 -ListAvailable

  #Import-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psd1 -verbose -Force
  #Get-Module .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psd1 -ListAvailable
    
userModule_SimpleExampleWithLogFunction_main $enableDebug $enableVerbose

# Remove-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psm1
# Remove-Module -Name .\mSimpleExampleWithLogFunction\mSimpleExampleWithLogFunction.psd1