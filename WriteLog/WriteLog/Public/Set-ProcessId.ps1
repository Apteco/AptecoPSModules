Function Set-ProcessId {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Id
    )

    $Script:processId = $Id

}