function Add-MockChannel {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

        ,[Parameter(Mandatory = $true)]
         [String]$Folder      # Local folder to write one file per notification into

    )

    process {

        # Make sure the target folder exists
        If ( (Test-Path -Path $Folder -IsValid) -eq $false ) {
            throw "Folder path '$( $Folder )' is not valid"
        }
        If ( (Test-Path -Path $Folder) -eq $false ) {
            New-Item -Path $Folder -ItemType Directory | Out-Null
        }

        $definition = [PSCustomObject]@{
            "folder" = (Resolve-Path -Path $Folder).Path
        }

        Add-Channel -Type "Mock" -Name $Name -Definition $definition

        # Adds a dummy target (Mock writes to one folder, no real recipients) to make it easier with group notifications
        Add-Target -Name $Name -TargetName $Name -Definition ([PSCustomObject]@{})

    }

}
