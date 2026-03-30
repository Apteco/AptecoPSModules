function Install-NuGetPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PackageId,

        [Parameter(Mandatory = $false)]
        [string]$Version = "",

        [Parameter(Mandatory = $false)]
        [string]$OutputDir = "./lib",

        [Parameter(Mandatory = $false)]
        [switch]$KeepPackage = $false
    )

    # Resolve latest version if not specified
    if (-not $Version) {
        $indexUrl = "https://api.nuget.org/v3-flatcontainer/$($PackageId.ToLower())/index.json"
        $index = Invoke-RestMethod -Uri $indexUrl
        $Version = $index.versions[-1]
    }

    $pkgId    = $PackageId.ToLower()
    $url      = "https://api.nuget.org/v3-flatcontainer/$pkgId/$Version/$pkgId.$Version.nupkg"
    # Download as .zip so Expand-Archive accepts it on Windows PowerShell 5.1,
    # which rejects any extension other than .zip even though .nupkg is identical format.
    $outFile  = Join-Path $OutputDir "$pkgId.$Version.zip"
    $unzipDir = Join-Path $OutputDir "$pkgId.$Version"

    Write-Verbose "Downloading $PackageId $Version ..."
    Invoke-WebRequest -Uri $url -OutFile $outFile

    Write-Verbose "Extracting to $unzipDir ..."
    Expand-Archive -Path $outFile -DestinationPath $unzipDir -Force

    if (-not $KeepPackage) {
        Write-Verbose "Removing $outFile ..."
        Remove-Item -Path $outFile -Force
    }

    Write-Verbose "Done: $unzipDir"
    return $unzipDir

}