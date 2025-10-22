
Function Write-Log {

<#
.SYNOPSIS
    Writing log messages into a logfile and additionally to the console output.
    The messages are also redirected to the Apteco software, if used in a custom channel

.DESCRIPTION
    The logfile getting written looks like

    20210217134552	a6f3eda5-1b50-4841-861e-010174784e8c	INFO	Hello World
    20210217134617	a6f3eda5-1b50-4841-861e-010174784e8c	ERROR	Hello World

    separated by tabs.

    Make sure, the variables $logfile and $processId are present before calling this. Otherwise they will be created automatically.
    The variables could be filled like

    $logfile = ".\test.log"
    $processId = [guid]::NewGuid()

    The process id is good for parallel calls so you know they belong together

.PARAMETER Message
    The message the script should log into a file and additionally to the console

.PARAMETER WriteToHostToo
    Boolean flag (default=true) to let the function put the message additionally to the console

.PARAMETER Severity
    Uses the enum [LogSeverity] (default=[LogSeverity]::VERBOSE) to choose the loglevel.
    The logfile will contain that loglevel and depending on error or warning, it will be shown in the console

.EXAMPLE
    Write-Log -message "Hello World"

.EXAMPLE
    Write-Log -message "Hello World" -severity ([LogSeverity]::ERROR)

.EXAMPLE
    "Hello World" | Write-Log

.EXAMPLE
    Write-Log -message "Hello World" -WriteToHostToo $false

.INPUTS
    String

.OUTPUTS
    $null

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [cmdletbinding()]
    param(
          [Parameter(Mandatory=$true,ValueFromPipeline)][String]$Message
         ,[Parameter(Mandatory=$false)][Boolean]$WriteToHostToo = $true
         ,[Parameter(Mandatory=$false)][LogSeverity]$Severity = [LogSeverity]::VERBOSE
    )

    Begin {

        # Testing the path
        If ( ( Test-Path -Path $Script:logfile -IsValid ) -eq $false ) {
            Write-Error -Message "Invalid variable '`$logfile'. The path '$( $Script:logfile )' is invalid."
            throw "Invalid path for logfile. The path '$( $Script:logfile )' is invalid."
        }

        # Check on $Message
        If ( $null -eq $Message ) {
            Write-Error -Message "Invalid variable '`$Message'. The message '$( $Message )' is invalid."
            throw "Invalid log message. The message '$( $Message )' is invalid."
        }

    }

    Process {

        # Create an array first for all the parts of the log message
        # TODO set the structure of the log message somewhere globally and replace placeholders with $string.replace("#severity#","$($Severity.ToString())") etc. Custom variables like machine name etc. could be added there, too
        $logarray = @(
            [datetime]::Now.ToString("yyyyMMddHHmmss")
            $Script:processId
            $Severity.ToString()
            $Message
        )

        # Specify the tab delimiter
        # TODO Add a setter and getter for that delimiter somewhere globally
        $delimiter = $Script:logDelimiter

        # Put the array together
        #$logstring = $logarray -join "`t"
        
        # Create a StringBuilder object
        $logstring = [System.Text.StringBuilder]::new()

        # Iterate over the array and append each element
        for ($i = 0; $i -lt $logarray.Length; $i++) {

            # Append the current element
            $logstring.Append($logarray[$i]) | Out-Null
            
            # Check if it's not the last element to add the delimiter
            if ($i -lt $logarray.Length - 1) {
                $logstring.Append($delimiter) | Out-Null
            }

        }

        # Save the string to the logfile
        $randomDelay = Get-Random -Maximum 3000
        $outArgs = @{
            FilePath = $script:logfile
            InputObject = $logstring.toString()
            Encoding = "utf8"
            Append = $true
            NoClobber = $true
        }
        Invoke-CommandRetry -Command 'Out-File' -Args $outArgs -retries 10 -MillisecondsDelay $randomDelay | Out-Null

        # Put the string to host, too
        If ( $WriteToHostToo -eq $true ) {
            # Write-Host $message # Updating to the newer streams Information, Verbose, Error and Warning
            Switch ( $Severity ) {
                ( [LogSeverity]::VERBOSE ) {
                    #Write-Verbose $message $message -Verbose # To always show the logmessage without verbose flag, execute    $VerbosePreference = "Continue"
                    Write-Verbose -Message $Message -InformationAction Continue -Verbose
                }
                ( [LogSeverity]::INFO ) {
                    Write-Information -MessageData "INFO: $( $Message )" -Tags @("Info") -Verbose # -InformationAction Continue
                }
                ( [LogSeverity]::WARNING ) {
                    Write-Warning -Message $Message
                }
                ( [LogSeverity]::ERROR ) {
                    Write-Error -Message $Message -CategoryActivity "ERROR"
                }
                Default {
                    #Write-Verbose -Message $message -Verbose
                    Write-Verbose -Message $Message -Verbose # -InformationAction Continue
                }
            }
        }

    }

    End {

    }

}