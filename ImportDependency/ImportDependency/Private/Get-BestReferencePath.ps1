Function Get-BestReferencePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageRoot   # e.g. "$HOME\.nuget\packages\myPkg\1.0.0"
    )

    process {

        foreach ($tfm in $Script:frameworkPreference) {

            $genericPath = Join-Path $PackageRoot "ref\$( $tfm )"
            $dll = Get-ChildItem -Path $genericPath -Filter "*.dll" -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($dll) {
                return $dll.DirectoryName
            }
        }

        throw "No compatible assembly found in $PackageRoot for RID $runtimeId"

    }
}
