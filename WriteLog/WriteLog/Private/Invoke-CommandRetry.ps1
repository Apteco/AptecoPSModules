
<#
Inspired by https://blogs.endjin.com/2014/07/how-to-retry-commands-in-powershell/
#>

Function Invoke-CommandRetry {

    <#
    .SYNOPSIS
        Retrying a specific command multiple times until it fails. This can be used e.g. to
        try to write in a file if multiple write commands can occur at the same time.

    .DESCRIPTION
        This function is a helper for the logging script function. It retries a specific command,
        e.g. you have concurrent calls to write to the logfile. In this case this function
        can try the write command multiple times until it fails.

    .PARAMETER Command
        The command to be executed like Write-Output or Set-Content

    .PARAMETER Args
        The arguments for the command defined in a hashtable because it uses splatting

    .PARAMETER Retries
        Optional parameter (default 10) for retries of this command

    .PARAMETER MillisecondsDelay
        Optional parameter (default random between 0 and 3000) to define the milliseconds to wait before the next try

    .EXAMPLE
        Invoke-CommandRetry -command "Write-Output" -args @{"InputObject"="Hello World"}

    .EXAMPLE
        $randomDelay = Get-Random -Maximum 3000
        $outArgs = @{
            FilePath = $logfile
            InputObject = $logstring
            Encoding = "utf8"
            Append = $true
            NoClobber = $true
        }
        Invoke-CommandRetry -Command 'Out-File' -Args $outArgs -retries 10 -MillisecondsDelay $randomDelay

    .INPUTS
        String, HashTable

    .OUTPUTS
        Boolean

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param (
        [Parameter(Mandatory=$true)][String]$Command,
        [Parameter(Mandatory=$true)][hashtable]$Args,
        [Parameter(Mandatory=$false)][int]$Retries = 10,
        [Parameter(Mandatory=$false)][int]$MillisecondsDelay = ( Get-Random -Maximum 3000 )
    )

    # Setting ErrorAction to Stop is important. This ensures any errors that occur in the command are
    # treated as terminating errors, and will be caught by the catch block.
    $Args.ErrorAction = "Stop"

    $retrycount = 0
    $completed = $false

    while ($completed -ne $true) {
        try {
            & $Command @Args
            Write-Verbose -Message "Command [$( $Command )] succeeded."
            $completed = $true
        } catch {
            if ($retrycount -ge $Retries) {
                Write-Warning -Message "Command [$( $Command )] failed the maximum number of $( $retrycount ) times."
                throw
            } else {
                Write-Warning -Message "Command [$( $Command )] failed. Retrying in $( $secondsDelay ) seconds."
                Start-Sleep -Milliseconds $MillisecondsDelay
                $retrycount += 1
            }
        }
    }

    # Return
    $completed

}