Function Set-ProcessIdentifier {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Id
    )

    # Set the script scope process ID
    $Script:processId = $Id


    # Set the process ID for logging module
    Set-ProcessId -Id $Id

}