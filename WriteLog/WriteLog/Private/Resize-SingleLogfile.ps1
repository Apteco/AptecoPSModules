Function Resize-SingleLogfile {

    [cmdletbinding()]
    param(
       [Parameter(Mandatory=$true)][String]$Path
      ,[Parameter(Mandatory=$true)][int]$RowsToKeep
    )

    If ( ( Test-Path -Path $Path -IsValid ) -eq $false ) {
        Write-Error -Message "The path '$( $Path )' is invalid."
        return
    }

    If ( ( Test-Path -Path $Path ) -eq $false ) {
        Write-Verbose -Message "Skipping '$( $Path )' — file does not exist yet."
        return
    }

    # Create a temporary file
    $tmpdir = Get-TemporaryPath
    $tempFile = Join-Path -Path $tmpdir -ChildPath "$( [guid]::newguid().toString() ).tmp"

    # Write only last lines to the new file
    Get-Content -Tail $RowsToKeep -Encoding utf8 -Path $Path | Set-Content -Path $tempFile -Encoding utf8

    # Delete original file and replace with trimmed version
    Remove-Item -Path $Path
    Move-Item -Path $tempFile -Destination $Path

    Write-Verbose -Message "Resized '$( $Path )' to last $( $RowsToKeep ) lines."

}
