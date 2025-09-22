Function Resize-Logfile {

<#
.SYNOPSIS
    Cleans the logfile except for the last n rows

.DESCRIPTION
    The logfile, that is defined by $logfile or $Script:logfile needs to be cleaned from time to time.
    So this function rewrites the file with the last (most current) n lines.

.PARAMETER RowsToKeep
    The number of lines you want to keep

.EXAMPLE
    Clean-Logfile -RowsToKeep 200000

.INPUTS
    Int

.OUTPUTS
    $null

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [cmdletbinding()]
    param(
       [Parameter(Mandatory=$true)][int]$RowsToKeep #= 200000
    )

    # TODO [ ] use input path rather than a variable?

    If ( $null -eq $logfile ) {

        Write-Warning -Message "There is no variable '`$logfile' present on 'Script' scope"
        Write-Warning -Message "Please define a path in '`$logfile' or use 'Write-Log' once"

    } else {

        # Testing the path
        If ( ( Test-Path -Path $logfile -IsValid ) -eq $false ) {
            Write-Error -Message "Invalid variable '`$logfile'. The path '$( $logfile )' is invalid."
        } else {

            # [ ] TODO maybe implement another parameter to input date instead of no of rows, use streamreader for this instead
            # [Datetime]::ParseExact("20221027130112","yyyyMMddHHmmss",$null)

            # Create a temporary file
            $tempFile = Join-Path -Path $Env:tmp -ChildPath "$( [guid]::newguid().toString() ).tmp" #New-TemporaryFile

            # Write only last lines to the new file
            Get-Content -Tail $RowsToKeep -Encoding utf8 -Path $Script:logfile | Set-Content -path $tempFile.FullName -Encoding utf8

            # delete original file
            If ( (Test-Path -Path $logfile) -eq $true ) {
                Remove-Item $logfile
            }

            # move file to new location
            Move-Item -Path $tempFile.FullName -Destination $logfile

        }

    }

}