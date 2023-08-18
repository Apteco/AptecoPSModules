
# Resolve the endpoint by adding baseUrl and replace some parameters
Function Resolve-Url {

    param(
        [Parameter(Mandatory=$true)][PSCustomObject] $endpoint,
        [Parameter(Mandatory=$false)][Hashtable] $additional,
        [Parameter(Mandatory=$false)][Hashtable] $query
    )

    # build the endpoint
    $uri = "$( $Script:settings.base )$( $endpoint.urlTemplate )"

    # replace the dataview
    $uri = $uri -replace "{dataViewName}", $Script:settings.login.dataView

    # replace other parameters in path
    if ($additional) {
        $additional.Keys | ForEach {
            
            $uri = $uri -replace "{$( $_ )}", $additional[$_]

        }
    }

    # add parts to the query
    if ($query) {

        $uri += "?"
        $i = 0
        $query.Keys | ForEach {

            if ($i -ne $query.Count -and $i -ne 0) {
                $uri += "&"
            }

            $uri += "$( $_ )=$( [System.Web.HttpUtility]::UrlEncode($query[$_]) )"
            #$uri += "$( $_ )=$( [uri]::EscapeDataString($query[$_]) )"

            $i+=1

        }
    }

    $uri
}