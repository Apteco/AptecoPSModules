function Add-NotificationGroup {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [String]$Name
        
    )

    process {

        # Check if the group already exists
        try {
            $group = @( Get-NotificationGroup -Name $Name )

            If ( $group.count -gt 0 ) {
                throw "Group $( $Name ) already exists"
            }
        } catch {
            # Do nothing
        }

        # Add the channel to the store
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