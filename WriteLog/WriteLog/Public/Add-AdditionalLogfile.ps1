Function Add-AdditionalLogfile {

    [cmdletbinding()]
    param(
       [Parameter(Mandatory=$true)]
       [String]$Path

       ,[Parameter(Mandatory=$false)]
       [String]$Name = ""
    )

    Begin {
        
        # Testing the path
        If ( ( Test-Path -Path Path -IsValid ) -eq $false ) {
            Write-Error -Message "The path '$( $Path )' is invalid."
            throw "The path '$( $Path )' is invalid."
        }

        # If Name is empty, use the filename from the path
        If ( [string]::IsNullOrWhiteSpace( $Name ) ) {
            $textfilesPresent = @( $Script:additionalLogs | Where-Object { $_.Type -eq "textfile" } ).Count
            $Name = "Textfile_$( $textfilesPresent + 1 )"
        }

    }

    Process {
        $Script:additionalLogs.Add( [PSCustomObject]@{
            "Type" = "textfile"
            "Name" = $Name
            "Options" = [PSCustomObject]@{
                "Path" = $Path
            }
        } ) | Out-Null
        Write-Verbose -Message "Added additional textfile to '$( $Path )' with name '$( $Name )'"
    }

}