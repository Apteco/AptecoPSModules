

function Update-BackgroundJob {

    <#
    .SYNOPSIS
    Expensive Checks are put into the background so they are not finished when the module is loaded

    #>

    [CmdletBinding()]
    param()

    If ( $Script:backgroundJobs.Count -gt 0 ) {

        # Wait for the jobs to complete (optional, depending on your needs)
        Wait-Job -Job $Script:backgroundJobs | Out-Null

        $jobsToRemove = @()
        $Script:backgroundJobs | ForEach-Object {

            $job = $_
            $results = Receive-Job -Job $job

            switch ($job.Name) {

                "PwshIs64Bit" {

                    $Script:defaultPsCoreIs64Bit = $results

                }

                "InstalledModule" {

                    $Script:installedModules = $results | Group-Object Name, PathEdition | ForEach-Object {
                        # Get the latest version for each module/edition combination
                        $_.Group | where-Object { $_.Version -ne "Unknown" } | Sort-Object { [version]($_.Version -replace '[^0-9.]', '0') } -Descending | Select-Object -First 1
                    } | Sort-Object PathEdition, Name

                }

                "InstalledGlobalPackages" {

                    $Script:installedGlobalPackages = $results

                }

                default {
                    Write-Warning "Unknown job: $($job.Name)"
                }

            }

            $jobsToRemove += $job

        }

        # Clean up the job
        $jobsToRemove | ForEach-Object {
            Remove-Job -Job $_
            $Script:backgroundJobs.Remove($_)
        }

    }


}
