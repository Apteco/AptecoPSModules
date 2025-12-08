

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

                    $Script:installedModules = $results

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
