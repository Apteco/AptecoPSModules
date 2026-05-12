function Get-PythonPath {

    $pse = Get-PSEnvironment -SkipBackgroundCheck -SkipLocalPackageCheck

    $pythonPaths = @()
    if ($pse.OS -eq "Windows") {
        # For Windows
        $pythonPaths = @( ( Get-Command -CommandType Application -Name "python*" -ErrorAction SilentlyContinue ).Source | Where-Object { $_ -notlike "*pythonw.exe" } )
    } elseif ( $pse.OS -eq "Linux" ) {
        # For Linux
        @("python3", "python") | ForEach-Object {
            try {
                $cmd = (which $_ 2>$null)
                if (-not [string]::IsNullOrEmpty($cmd)) {
                    $pythonPaths += $cmd
                }
            } catch {
                # Command not found
            }
        }
        $pythonPaths = @( $pythonPaths | Select-Object -Unique )
    }

    if ($pythonPaths.Count -eq 0) {
        Write-Verbose "Python is not installed or not found."
        return $null
    }

    if ($pythonPaths.Count -gt 1) {
        Write-Verbose "Multiple Python installations found: $($pythonPaths -join ', ')"
    }

    # Resolve version for each candidate
    $pythonWithVersion = @(
        $pythonPaths | ForEach-Object {
            $path = $_
            try {
                $versionOutput = & $path --version 2>&1
                if ($versionOutput -match "Python\s+(\d+(?:\.\d+)+)") {
                    [PSCustomObject]@{
                        Path    = $path
                        Version = [System.Version]$Matches[1]
                    }
                }
            } catch {
                # Skip paths that cannot be executed
            }
        } | Where-Object { $null -ne $_ }
    )

    if ($pythonWithVersion.Count -eq 0) {
        Write-Verbose "Python is not installed or not found."
        return $null
    }

    $highestVersion = ( $pythonWithVersion | Sort-Object -Property Version -Descending | Select-Object -First 1 ).Version
    $highestVersionPaths = @( $pythonWithVersion | Where-Object { $_.Version -eq $highestVersion } )

    if ($highestVersionPaths.Count -gt 1) {
        Write-Verbose "Multiple Python installations share the same highest version ($highestVersion): $($highestVersionPaths.Path -join ', '). Using the first one."
    }

    $pythonPath = $highestVersionPaths[0].Path

    Write-Verbose "Python Path: $pythonPath (Version: $highestVersion)"

    return $pythonPath

}
