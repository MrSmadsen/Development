New-ModuleManifest -Path ".\mSimpleExample.psd1" -ModuleVersion "0.1" -PowerShellVersion "5.0" -Author "Søren Madsen" -RootModule ".\mSimpleExample.psm1" -ScriptsToProcess "..\runScript.ps1"

# Test the manifest file.
Test-ModuleManifest ".\mSimpleExample.psd1"