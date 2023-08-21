
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

        # If the variable is not present, it will create a temporary file
        If ( $null -eq $Script:logfile ) {
            $f = New-TemporaryFile
            $Script:logfile = $f.FullName
            Write-Warning -Message "There is no variable '`$logfile' present on 'Script' scope. Created one at '$( $Script:logfile )'"
        }

        # Testing the path
        If ( ( Test-Path -Path $Script:logfile -IsValid ) -eq $false ) {
            Write-Error -Message "Invalid variable '`$logfile'. The path '$( $Script:logfile )' is invalid."
        }

        # If a process id (to identify this session by a guid) it will be set automatically here
        If ( $null -eq $Script:processId ) {
            $Script:processId = [guid]::NewGuid().ToString()
            Write-Warning -Message "There is no variable '`$processId' present on 'Script' scope. Created one with '$( $Script:processId )'"
        }

    }

    Process {

        # Create an array first for all the parts of the log message
        $logarray = @(
            [datetime]::Now.ToString("yyyyMMddHHmmss")
            $Script:processId
            $Severity.ToString()
            $Message
        )

        # Put the array together
        $logstring = $logarray -join "`t"

        # Save the string to the logfile
        #$logstring | Out-File -FilePath $logfile -Encoding utf8 -Append -NoClobber
        #Out-File -InputObject = $logstring
        $randomDelay = Get-Random -Maximum 3000
        $outArgs = @{
            FilePath = $script:logfile
            InputObject = $logstring
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
                    Write-Verbose Message $Message -InformationAction Continue -Verbose
                }
                ( [LogSeverity]::INFO ) {
                    Write-Information -MessageData $Message -InformationAction Continue -Tags @("Info")
                }
                ( [LogSeverity]::WARNING ) {
                    Write-Warning -Message $Message
                }
                ( [LogSeverity]::ERROR ) {
                    Write-Error -Message $Message -CategoryActivity "ERROR"
                }
                Default {
                    #Write-Verbose -Message $message -Verbose
                    Write-Verbose Message $Message -InformationAction Continue -Verbose
                }
            }
        }

        # Return
        #$null

    }

    End {

    }

}