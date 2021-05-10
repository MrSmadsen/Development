<#
 .Synopsis
  An example of a simple powerShell module.
  Its called from a startup file named runScript.ps1 and initiated in a "main-function" inside the module itself.

 .Description
  This is a simple module to learn basic Powershell scripting.
    
  Powershell script module.
  The script and the directory where it's stored must use the same name.
  The module's directory needs to be in a path specified in $env:PSModulePath. 
  
  Deployment information can be found in the last comment section in this file.

 .Parameter None
  None.

 .Example
  # No example.
#>

function userModule_SimpleExample_main
{    
    param (
      [Parameter(Mandatory=$true, Position=0, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
      [ValidateNotNullOrEmpty()]
      [ValidateSet($true, $false, 0, 1)]
      $enableDebug,
      [Parameter(Mandatory=$true, Position=1, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
      [ValidateNotNullOrEmpty()]
      [ValidateSet($true, $false, 0, 1)]
      $enableVerbose
    )
    if ($enableDebug) {
    $DebugPreference = "Continue"
    }
    else {
        $DebugPreference = "SilentlyContinue"
    }
    if ($enableVerbose) {
    $VerbosePreference = "Continue"
    }
    else {
        $VerbosePreference = "SilentlyContinue"
    }
    Write-Debug "Entered function: userModule_SimpleExample_main"
    
    # $objSimpleExampleOfAClass = [SimpleExampleOfAClass]::new($enableDebug, $enableVerbose, 'hmmmm')
    $objSimpleExampleOfAClass = New-Object -TypeName SimpleExampleOfAClass -ArgumentList $enableDebug, $enableVerbose
    
    # String: Double quoted strings are expandable     - Values in $-expressions inside the string is replaced by the value.
    # String: Single quoted strings are not expandable - The string is parsed "as it is" to the callee.
    $objSimpleExampleOfAClass.printStringValue('SimpleExample')
}

# Classes in powershell are strongly typed.
class SimpleExampleOfAClass {
  # Instance variables.
  # Used to setup Preferences variables for output.
  # Setup debugging output. Seems to only be effective in current scope and subscope in the same file.
    # (Values: Stop | SilentlyContinue | Continue | Inquire)
    # Stop: Displays the debug message and stops executing. Writes an error to the console.
    # SilentlyContinue: (Default) No effect. The debug message isn't displayed and execution continues without interruption.  
    # Continue: Displays the debug message and continues with execution.    
    # Inquire: Displays the debug message and asks you whether you want to continue. Adding the Debug common parameter to a command, when the command is configured to generate a debugging message, changes the value of the $DebugPreference variable to Inquire.  
    [String] $debugOutput = "SilentlyContinue"
    [String] $verboseOutput = "SilentlyContinue"

  # Default constructor
  SimpleExampleOfAClass()
  {
      Write-Debug "Entered function: SimpleExampleOfAClass.SimpleExampleOfAClass()"      
      Write-Debug "SimpleExampleOfAClass(): Throw Exception. Exit."
      throw [InvalidOperationException]::new("Not allowed to use default constructor. Exit.")
  }

  # Non-Default constructor
  SimpleExampleOfAClass([Bool]$debug, [Bool]$verbose)
  {    
      # Setting up output configuration for this class. Default is SilentlyContinue.    
      if ($debug) {
          $this.debugOutput = "Continue"
      }
      if ($verbose) {
          $this.verboseOutput = "Continue"
      }
      $DebugPreference = $this.debugOutput
      $VerbosePreference = $this.verboseOutput
      Write-Verbose "-enableDebug: $debug. DebugPreference has been set to: $DebugPreference"
      Write-Verbose "-enableVerbose: $verbose. VerbosePreference has been set to: $VerbosePreference"
      Write-Debug "Entered function: SimpleExampleOfAClass.SimpleExampleOfAClass([Bool]$debug, [Bool]$verbose)"
  }

  [void] printStringValue([String]$value)
  {
      $DebugPreference = $this.debugOutput
      $VerbosePreference = $this.verboseOutput
      Write-Debug "Entered function: SimpleExampleOfAClass.printStringValue([String]$value)"
      
      Write-Host "Value to print: $value"
      $this.doCallHiddenFuntion()
      Write-Host "Printing the value is done."
  }

  # This is not a "private function" like in c-sharp/Java using the private keyword. It is still callable but it is
  # only listed as a Class member by Get-Member if the flag -Force is used: Get-Member .\mSimpleExample\mSimpleExample.psm1 -ListAvailable -Force.
  hidden [void] doCallHiddenFuntion()
  {
      $DebugPreference = $this.debugOutput
      $VerbosePreference = $this.verboseOutput
      Write-Debug "Entered function: SimpleExampleOfAClass.doCallHiddenFuntion()"
  }
}
# Use these export statements if importing the module directly.  
  #Export function:
    Export-ModuleMember -Function userModule_SimpleExample_main