function Add-NotificationGroup {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [String]$Name
        
    )

    process {

        # Check if the group already exists
        If ( @( $script:store.groups | Where-Object { $_.Name -eq $Name } ).Count -gt 0 ) {
            throw "Group '$( $Name )' already exists"
        }

        # Add the group to the store
        $script:store.groups += [PSCustomObject]@{
            "GroupId" = [guid]::NewGuid().ToString()
            "Name" = $Name
            "DateAdded" = [datetime]::Now.ToString("yyyyMMddHHmmss")
            "DateModified" = [datetime]::Now.ToString("yyyyMMddHHmmss")
        }

        # Now save that
        Set-Store

    }

}