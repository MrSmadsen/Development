$Parms = @{
  Path = ".\mSimpleExample.psd1"
  Author = "Søren Madsen"
  ModuleVersion = "0.2"
  CompanyName = "N/A"
  RootModule = ".\mSimpleExample.psm1"
  ScriptsToProcess = "..\runScript.ps1"
}

Update-ModuleManifest @Parms