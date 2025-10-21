function Get-PwshPath {

    #$pse = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
    
    $pwshPath = $Script:defaultPsCorePath
    <#
    if ($pse.OS -eq "Windows") {
        # For Windows
        $pwshPath = (get-command pwsh).source
    } elseif ( $pse.OS -eq "Linux" ) {
        # For Linux
        If ( $null -ne (which pwse) ) {
            $pwshPath = (which pwse)
        }
    }
    #>

    if ($null -eq $pwshPath) {
        Write-Verbose "pwsh is not installed or not found."
    } else {
        Write-Verbose "pwsh Path: $( $pwshPath )"
    }

    return $pwshPath

}
