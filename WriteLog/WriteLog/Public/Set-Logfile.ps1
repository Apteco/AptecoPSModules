Function Set-Logfile {

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    try {
        
        If ( (Test-Path -Path $Path -IsValid) -eq $true) {
            # Create the item if not existing
            If (( Test-Path -Path $Path ) -eq $false) {
                $item = New-Item -Path $Path -ItemType File
            }
            $Script:logfile = $item.FullName
        } else {
            Write-Error -Message "The path '$( $Path )' is invalid."
        }
    } catch {
        Write-Error -Message "The path '$( $Path )' is invalid."
    }

    $item.FullName

}