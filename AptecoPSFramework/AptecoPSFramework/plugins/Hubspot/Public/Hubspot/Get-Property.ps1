
function Get-Property {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
         [Parameter(Mandatory=$true)][String]$Object
        ,[Parameter(Mandatory=$false)][Switch]$Archived = $false
    )

    begin {

    }
    process {

        $loadArchived = $false
        If ( $Archived -eq $true ) {
            $loadArchived = $true
        }

        $properties = @( Invoke-Hubspot -Object "crm" -Path "properties/$( $Object )" -Query ([PSCustomObject]@{"archived"=$loadArchived}) -Method GET )

        $properties.results

    }

    end {

    }

}
