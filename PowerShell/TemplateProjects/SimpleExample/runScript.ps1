#------------------------------ Below here! Excample: using statement. ------------------------------
# If debugging and verbose output should be disabled: Usage: .\runScript.ps1
# If debugging output should be enabled:              Usage:  .\runScript.ps1 -enableDebug
# If debugging and verbose output should be enabled:  Usage:  .\runScript.ps1 -enableDebug -enableVerbose

# Using using statement and public class members. This is meant to be the scenario when using object oriented style of programming
# and we want to avoid declaring Export-ModuleMember -Function <FunctionName> in the module.
# It did not run correctly without extension or if pointed directly to the manifest file.
using module .\mSimpleExample\mSimpleExample.psm1

param (
    [switch]$enableDebug,
    [switch]$enableVerbose
)

$objSimpleExampleOfAClass = New-Object -TypeName SimpleExampleOfAClass -ArgumentList $enableDebug, $enableVerbose    
# String: Double quoted strings are expandable     - Values in $-expressions inside the string is replaced by the value.
# String: Single quoted strings are not expandable - The string is parsed "as it is" to the callee.
$objSimpleExampleOfAClass.printStringValue('SimpleExample')

#------------------------------ Below here! Function export. ------------------------------
#Importing module:
# For running when working:

# Starting the script using the manifest file is still abit buggy, but it does run if your execution policy is set up to allow scripts.
# Import-Module -Name .\mSimpleExample\mSimpleExample.psd1

# TEST:
# Should load manifest file if it is present and has the correct name (same as sub-folder and module itself)
#Import-Module .\mSimpleExample\mSimpleExample
#Import-Module -Name .\mSimpleExample\mSimpleExample
#Import-Module -Name .\mSimpleExample\mSimpleExample.psm1

# For debugging: -Force will reimport the module without having to restart the powershell session.  
  # Import-Module -Name .\mSimpleExample\mSimpleExample.psm1 -verbose -Force
  #Import-Module -Name .\mSimpleExample\mSimpleExample.psm1 -Force
  #Get-Module .\mSimpleExample\mSimpleExample.psm1 -ListAvailable

  #Import-Module -Name .\mSimpleExample\mSimpleExample.psd1 -verbose -Force
  #Get-Module .\mSimpleExample\mSimpleExample.psd1 -ListAvailable
    
# userModule_SimpleExample_main $enableDebug $enableVerbose

# Remove-Module -Name .\mSimpleExample\mSimpleExample.psm1
# Remove-Module -Name .\mSimpleExample\mSimpleExample.psd1