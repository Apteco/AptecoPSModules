<#

Requisites

* loaded variable $settings

#>

Function Get-Endpoints {

    $pageSize = 1
    $offset = 0
    $Script:endpoints = @()
    $totalEndpointsCount = 0
    Do {

        try {

                # Create the url
                $uri = "$( $settings.base )About/Endpoints?excludeEndpointsWithNoLicenceRequirements=false&excludeEndpointsWithNoRoleRequirements=false&count=$( $pageSize )&offset=$( $offset )"
                $uri

                # Prepare already for the next call
                $Script:endpoints += $res.list
                $offset += $pageSize

                # Do the call so in case it creates an error, jump to the next page url
                $res = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json; charset=utf-8" -Verbose

                If ( $totalEndpointsCount -eq 0 ) {
                    $totalEndpointsCount = $res.totalCount
                }
            
        } catch {
            Write-Host "Error with $( $uri )"
            Continue
        }

    #} Until ( $Script:endpoints.count -eq $res.totalCount )
    } Until ( $offset -ge $totalEndpointsCount )

    #$Script:endpoints | out-gridview

}


