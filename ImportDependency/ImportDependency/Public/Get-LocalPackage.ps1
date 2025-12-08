            
Function Get-LocalPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String[]]$NugetRoot   # e.g. "$HOME\.nuget\packages\myPkg\1.0.0"
    )

    begin {

        $existing = $NugetRoot | Where-Object { Test-Path $_ }
        $packages = [System.Collections.ArrayList]::new()
        
    }

    process {

        $existing | ForEach-Object {
            Get-ChildItem $_ -Recurse -File | ForEach-Object {

                if ($_.Extension -eq ".nuspec") {

                    # Fast path: read existing nuspec
                    [xml]$xml = Get-Content $_.FullName
                    $meta = $xml.package.metadata

                    # Calculate directory size
                    $pkgFolder = Split-Path $_.FullName -Parent
                    $sizeBytes = (Get-ChildItem $pkgFolder -Recurse -File | Measure-Object Length -Sum).Sum

                    $packages.Add([PSCustomObject]@{
                        Id      = $meta.id
                        Version = $meta.version
                        Description = $meta.description
                        Authors     = $meta.authors
                        Path    = $_.DirectoryName
                        Source  = "nuspec"
                        SizeMB      = [math]::Round(($sizeBytes / 1MB), 2)

                    } ) | Out-Null

                } elseif ($_.Extension -eq ".nupkg") {

                    # Slow(er) path: read nuspec inside the ZIP container
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($_.FullName)
                    $entry = $zip.Entries | Where-Object { $_.FullName -like "*.nuspec" }

                    # Calculate directory size
                    $pkgFolder = Split-Path $_.FullName -Parent
                    $sizeBytes = (Get-ChildItem $pkgFolder -Recurse -File | Measure-Object Length -Sum).Sum

                    if ($entry) {
                        $stream = $entry.Open()
                        $reader = New-Object System.IO.StreamReader($stream)
                        [xml]$xml = $reader.ReadToEnd()
                        $stream.Dispose()
                        $zip.Dispose()

                        $meta = $xml.package.metadata

                        $packages.Add([PSCustomObject]@{
                            Id      = $meta.id
                            Version = $meta.version
                            Description = $meta.description
                            Authors     = $meta.authors
                            SizeMB      = [math]::Round(($sizeBytes / 1MB), 2)
                            Path    = $_.FullName
                            Source  = "zip"
                        } ) | Out-Null
                    }
                    
                }
            }
        }

        # return
        $packages

    }

}