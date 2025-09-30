function Get-PythonPath {

    $pse = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck
    
    $pythonPath = $null
    if ($pse.OS -eq "Windows") {
        # For Windows
        $pythonPath = (Get-Command python).Source
    } elseif ( $pse.OS -eq "Linux" ) {
        # For Linux
        If ( $null -ne (which python) ) {
            $pythonPath = (which python)
        } elseif ( $null -ne (which python3) ) {
            $pythonPath = (which python3)
        }
    }

    if (-not $pythonPath) {
        Write-Verbose "Python is not installed or not found."
    } else {
        Write-Verbose "Python Path: $pythonPath"
    }

    return $pythonPath

}
