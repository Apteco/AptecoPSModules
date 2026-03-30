Function Resize-Logfile {

<#
.SYNOPSIS
    Cleans the logfile except for the last n rows

.DESCRIPTION
    The logfile, that is defined by $logfile or $Script:logfile needs to be cleaned from time to time.
    So this function rewrites the file with the last (most current) n lines.
    Optionally a specific path can be provided via -Path, or all registered log files can be resized at once with -All.

.PARAMETER RowsToKeep
    The number of lines you want to keep

.PARAMETER Path
    Optional path to a specific logfile to resize. If omitted, the main logfile ($Script:logfile) is used.

.PARAMETER All
    If set, resizes all registered log files: the main logfile and all additional textfile log files.

.EXAMPLE
    Resize-Logfile -RowsToKeep 200000

.EXAMPLE
    Resize-Logfile -RowsToKeep 200000 -Path "C:\Logs\myapp.log"

.EXAMPLE
    Resize-Logfile -RowsToKeep 200000 -All

.INPUTS
    Int

.OUTPUTS
    $null

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [cmdletbinding()]
    param(
       [Parameter(Mandatory=$true)][int]$RowsToKeep
      ,[Parameter(Mandatory=$false)][String]$Path = ""
      ,[Parameter(Mandatory=$false)][Switch]$All
    )

    If ( -not [String]::IsNullOrWhiteSpace( $Path ) ) {

        # Explicit path provided — resize only that file
        Resize-SingleLogfile -Path $Path -RowsToKeep $RowsToKeep

    } ElseIf ( $All ) {

        # Resize main logfile
        If ( $null -eq $Script:logfile ) {
            Write-Warning -Message "There is no variable '`$logfile' present on 'Script' scope"
            Write-Warning -Message "Please define a path in '`$logfile' or use 'Write-Log' once"
        } else {
            Resize-SingleLogfile -Path $Script:logfile -RowsToKeep $RowsToKeep
        }

        # Resize all additional textfile log files
        $Script:additionalLogs | Where-Object { $_.Type -eq "textfile" } | ForEach-Object {
            Resize-SingleLogfile -Path $_.Options.Path -RowsToKeep $RowsToKeep
        }

    } Else {

        # Default: resize the main logfile
        If ( $null -eq $Script:logfile ) {
            Write-Warning -Message "There is no variable '`$logfile' present on 'Script' scope"
            Write-Warning -Message "Please define a path in '`$logfile' or use 'Write-Log' once"
        } else {
            Resize-SingleLogfile -Path $Script:logfile -RowsToKeep $RowsToKeep
        }

    }

}