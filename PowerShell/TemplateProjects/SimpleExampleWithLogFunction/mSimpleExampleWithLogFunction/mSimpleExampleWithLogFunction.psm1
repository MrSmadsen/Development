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

function userModule_SimpleExampleWithLogFunction_main
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
    Write-Debug "Entered function: userModule_SimpleExampleWithLogFunction_main"
    
    # $objSimpleExampleWithLogFunctionClass = [SimpleExampleWithLogFunctionClass]::new($enableDebug, $enableVerbose, 'hmmmm')
    $objSimpleExampleWithLogFunctionClass = New-Object -TypeName SimpleExampleWithLogFunctionClass -ArgumentList $enableDebug, $enableVerbose
    
    # String: Double quoted strings are expandable     - Values in $-expressions inside the string is replaced by the value.
    # String: Single quoted strings are not expandable - The string is parsed "as it is" to the callee.
    $objSimpleExampleWithLogFunctionClass.printStringValue('SimpleExampleWithLogFunction')
}

# Enum used to define Write output type.
Enum MessageType {
    HostMessage;
    DebugMessage;
    VerboseMessage;
    AllTypesMessage
}

# Classes in powershell are strongly typed.
class SimpleExampleWithLogFunctionClass {
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
  SimpleExampleWithLogFunctionClass()
  {
      Write-Debug "Entered function: SimpleExampleWithLogFunctionClass.SimpleExampleWithLogFunctionClass()"      
      Write-Debug "SimpleExampleWithLogFunctionClass(): Throw Exception. Exit."
      throw [InvalidOperationException]::new("Not allowed to use default constructor. Exit.")
  }

  # Non-Default constructor
  SimpleExampleWithLogFunctionClass([Bool]$debug, [Bool]$verbose)
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
      Write-Debug "Entered function: SimpleExampleWithLogFunctionClass.SimpleExampleWithLogFunctionClass([Bool]$debug, [Bool]$verbose)"
  }

  [void] printStringValue([String]$value)
  {
      $DebugPreference = $this.debugOutput
      $VerbosePreference = $this.verboseOutput
      Write-Debug "Entered function: SimpleExampleWithLogFunctionClass.printStringValue([String]$value)"
      
      Write-Host "Value to print: $value"
      
      [MessageType]$msgType=[MessageType]::HostMessage
      $this.appendToLogFile($value, $msgType, $true)
      Write-Verbose "Printing the value is done."
  }

  # This function is not visible to Get-Member unless -Force flag is added, but it's not "private, as in the c#/Java private modifier keyword"  
  hidden [void] appendToLogFile([string] $message, [MessageType]$eMessageType, [Bool] $screenOnly)
  {
      $DebugPreference = $this.debugOutput
      $VerbosePreference = $this.verboseOutput
      Write-Debug "Entered function: SimpleExampleWithLogFunctionClass.appendToLogFile()"
      
      if ( ([string]::IsNullOrEmpty($message.Trim())) -or ($eMessageType -eq $null) -or ($screenOnly -eq $null) )
      {
          # Add a function like batch-Exception_End.          
          Write-Debug "SimpleExampleWithLogFunctionClass.appendToLogFile(): Empty string or null parameter found. Message:      $message. Exit."
          Write-Debug "SimpleExampleWithLogFunctionClass.appendToLogFile(): Empty string or null parameter found. eMessageType: $eMessageType. Exit."
          Write-Debug "SimpleExampleWithLogFunctionClass.appendToLogFile(): Empty string or null parameter found. screenOnly:   $screenOnly. Exit."          
          throw [InvalidOperationException]::new("SimpleExampleWithLogFunctionClass.appendToLogFile(): Throw parameter is empty or null Exception. Re-run with -enableDebug. Exit.")
      }
      
      switch ($eMessageType)
      {
          "HostMessage" {
              Write-Host $message; break
          }
          "DebugMessage" {
              Write-Debug $message; break
          }
          "VerboseMessage" {              
              Write-Verbose $message; break
          }
          "AllTypesMessage" {              
              Write-Host "This is a test of AllTypesMessage. 1: $message";
              Write-Debug "This is a test of AllTypesMessage. 2: $message";
              Write-Verbose "This is a test of AllTypesMessage. 3: $message"; break
          }
      }
  }
}
# Use these export statements if importing the module directly.  
  #Export function:
    Export-ModuleMember -Function userModule_SimpleExampleWithLogFunction_main