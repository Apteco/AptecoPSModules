

function Invoke-SFSCQuery {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][String] $Query
        ,[Parameter(Mandatory=$false)][Switch] $Bulk = $false    # TODO implement, use this one to use a bulk select instead of a direct query
        ,[Parameter(Mandatory=$false)][Switch] $IncludeAttributes = $false    # TODO implement, use this one to use a bulk select instead of a direct query
        ,[Parameter(Mandatory=$false)][Switch] $ReturnCount = $false    # Returns a count instead of the records

    )

    begin {

    }
    process {

        $queryObj = [PSCustomObject]@{
            "q" = $Query
        }

        Write-Log -severity verbose -Message "Executing query:"
        Write-Log -severity verbose -Message "  $( $Query )"

        If ( $Bulk -eq $true ) {
            # TODO [ ] implement
        } else {
            $result = Invoke-SFSC -Service "data" -Object "query" -Query $queryObj -Method "Get"
            <#
            $result = [PSCustomObject]@{
                "totalSize" = 10
                "done" = $true
                "records" = [Array]@(
                    [PSCustomObject]@{
                        Id = "a"
                        Name = "asdfasd"
                    }
                    [PSCustomObject]@{
                        Id = "b"
                        Name = "gdfgfg"
                    }
                )
            }
            #>
        }

        #$objects = Invoke-RestMethod -URI "$( $base )/services/data/v$( $version )/sobjects/" -Method Get -verbose -ContentType $contentType -Headers $headers

        #return
        Write-Log -severity verbose -Message "Result:"
        Write-Log -severity verbose -Message "  Status: $( $result.done ) "
        Write-Log -severity verbose -Message "  Records: $( $result.totalSize ) "

        #$result #| where-object { $_.createable -eq $true } | Select-Object name, label | Out-GridView -PassThru

        # return
        $return = $null
        If ( $ReturnCount -eq $true ) {
            $return = $result.totalSize
        } else {
            If ( $IncludeAttributes -eq $true ) {
                $return = $result.records
            } else {
                $return = $result.records | Select-Object * -ExcludeProperty attributes
            }
        }

        $return

    }

    end {

    }

}