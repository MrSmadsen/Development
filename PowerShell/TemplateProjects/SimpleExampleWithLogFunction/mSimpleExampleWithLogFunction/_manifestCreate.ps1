New-ModuleManifest -Path ".\mSimpleExampleWithLogFunction.psd1" -ModuleVersion "0.1" -PowerShellVersion "5.0" -Author "S�ren Madsen" -RootModule ".\mSimpleExample.psm1" -ScriptsToProcess "..\runScript.ps1"

# Test the manifest file.
Test-ModuleManifest ".\mSimpleExampleWithLogFunction.psd1"