Function Add-AdditionalDatabase {

<#
.SYNOPSIS
    Registers an additional database log target that Write-Log fans every log entry out to.

.DESCRIPTION
    Unlike Add-AdditionalLogfile, WriteLog has no idea how to talk to any particular database.
    Instead you supply a -Writer scriptblock that receives the log entry as a hashtable
    (TIMESTAMP, PROCESSID, SEVERITY, MESSAGE, PROCRAM, PROCCPU, ...) and is responsible for
    inserting it wherever you like (SQLite, SqlPipeline, SQL Server, a REST endpoint, ...).

    This keeps WriteLog free of any database dependency. Load whatever module/driver you need
    lazily inside the scriptblock itself.

    If the writer throws, Write-Log catches it and emits a warning rather than failing the log
    call, so a broken database target never breaks the caller.

.PARAMETER Writer
    A scriptblock invoked with one positional argument: the log entry as a [Hashtable].

.PARAMETER Name
    A friendly name for this target. Auto-generated (Database_1, Database_2, ...) if omitted.

.EXAMPLE
    Add-AdditionalDatabase -Name "SqliteLog" -Writer {
        param($LogEntry)
        # ... insert $LogEntry into a database
    }

.INPUTS
    None

.OUTPUTS
    $null

.NOTES
    Author:  florian.von.bracht@apteco.de

#>

    [cmdletbinding()]
    param(
       [Parameter(Mandatory=$true)]
       [ScriptBlock]$Writer

      ,[Parameter(Mandatory=$false)]
       [String]$Name = ""
    )

    Process {

        # If Name is empty, auto-generate one
        If ( [String]::IsNullOrWhiteSpace( $Name ) ) {
            $databasesPresent = @( $Script:additionalLogs | Where-Object { $_.Type -eq "database" } ).Count
            $Name = "Database_$( $databasesPresent + 1 )"
        }

        $Script:additionalLogs.Add( [PSCustomObject]@{
            "Type" = "database"
            "Name" = $Name
            "Options" = [PSCustomObject]@{
                "Writer" = $Writer
            }
        } ) | Out-Null
        Write-Verbose -Message "Added additional database log target with name '$( $Name )'"

    }

}
