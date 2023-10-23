
function Get-PicklistOptions {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$TableName # try to use TableName rather than logicalname because of plurals
        #[Parameter(Mandatory=$false)][String] $GroupId
        # [Parameter(Mandatory=$true)][String]$LogicalName # try to use TableName rather than logicalname because of plurals
        ,[Parameter(Mandatory=$false)][int]$LanguageCode = 1031 # try to use TableName rather than logicalname because of plurals

        )

    begin {

    }

    process {

        # Load the logicalname for the entitysetname
        $detail = Get-TableDetail -TableName $TableName

        # Load the data
        $picklistAttributes = Get-Record -TableName "EntityDefinitions(LogicalName='$( $detail.LogicalName )')/Attributes/Microsoft.Dynamics.CRM.PicklistAttributeMetadata" -select LogicalName,OptionSet -expand 'GlobalOptionSet($select=Options)'

        # Reformat the data
        $formattedOptions = [System.Collections.ArrayList]@()
        $picklistAttributes | ForEach-Object {
            $picklistAttribute = $_
            $picklistAttribute.GlobalOptionSet.Options | ForEach-Object {
                $option = $_
                [void]$formattedOptions.Add(
                    [PSCustomObject]@{
                        "Attribute" = $picklistAttribute.LogicalName
                        "Code" = $option.Value
                        "Description" = ( $option.Label.LocalizedLabels | Where-Object { $_.LanguageCode -eq $LanguageCode }).Label
                    }
                )
            }
        }

        # return
        $formattedOptions #| Sort-Object -ContentType

    }

    end {

    }

}
