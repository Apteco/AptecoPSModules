function Get-NotificationGroup {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [String]$Name
    )

    process {

        $groups = $script:store.groups.psobject.copy()

        If ( $PSBoundParameters.ContainsKey('Name') ) {
            $groups | Where-Object { $_.Name -like $Name }
        } else {
            $groups
        }

    }

}