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
    $outFile  = Join-Path $OutputDir "$pkgId.$Version.nupkg"
    $unzipDir = Join-Path $OutputDir "$pkgId.$Version"

    Write-Host "Downloading $PackageId $Version ..."
    Invoke-WebRequest -Uri $url -OutFile $outFile

    Write-Host "Extracting to $unzipDir ..."
    Expand-Archive -Path $outFile -DestinationPath $unzipDir -Force

    if (-not $KeepPackage) {
        Write-Host "Removing $outFile ..."
        Remove-Item -Path $outFile -Force
    }

    Write-Host "Done: $unzipDir"
    return $unzipDir

}