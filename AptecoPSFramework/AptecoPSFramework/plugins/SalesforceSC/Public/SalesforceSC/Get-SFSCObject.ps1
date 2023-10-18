


function Get-SFSCObject {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        #[Parameter(Mandatory=$false)][String] $GroupId
    )

    begin {

    }
    process {


        $objects = Invoke-SFSC -Object "sobjects" -Method "Get"

        #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers

        #return
        $objects.sobjects #| where-object { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

        <#
        [
            {
                "email": "Nikolas.Lethaus@apteco.de",
                "category": "hardbounce",
                "occurences": 1,
                "last_update": 1668083102,
                "last_update_gmt": "2022-11-10T12:25:02+00:00",
                "expires_by": 1833180850,
                "expires_by_gmt": "2028-02-03T08:54:10+00:00",
                "bounce_message": "smtp; 550 No such user (Nikolas.Lethaus@apteco.de)",
                "type": "mailing",
                "type_id": "8039163"
            },
            {
                "email": "M.Troussas@Googlemail.de",
                "category": "permanent",
                "occurences": 3,
                "last_update": 1559985183,
                "last_update_gmt": "2019-06-08T09:13:03+00:00",
                "expires_by": 2380205440,
                "expires_by_gmt": "2045-06-04T16:10:40+00:00",
                "bounce_message": "X-Postfix; Host or domain name not found. Name service error for name=googlemail.de type=MX: Host not found, try again",
                "type": "mailing",
                "type_id": "7321083"
            }
        ]
        #>

        # $bounced = Invoke-CR -Object "bounces" -Method GET -Verbose -Paging

        # $bounced

    }

    end {

    }

}

