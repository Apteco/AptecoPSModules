
Function Get-BaseParameters {

    <#
    .SYNOPSIS
        Loads the parameters of a function/cmdlet

    .DESCRIPTION
        Apteco PS Modules - PowerShell functions extension

        This function helps to gather all parameters that a function/cmdlet has
        except the common parameters like -verbose etc.

        This can be used to extend existing functions/cmdlets with more scripting
        and possibly additional parameters like


        function Invoke-CoreWebRequest {

            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)][string]$AdditionalString
            )
            DynamicParam { Get-BaseParameters "Invoke-WebRequest" }

            Process {
                Write-Host $AdditionalString
                $updatedParameters = Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters
                Invoke-WebRequest @updatedParameters
            }

        }

    .PARAMETER Base
        Name of the function/cmdlet to gather the parameters from

    .EXAMPLE
        Get-BaseParameters -Base "Invoke-WebRequest"

    .INPUTS
        String

    .OUTPUTS
        Dictionary

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Base
    )

    Process {
        $baseC = Get-Command -Name $Base -All | where { $_.CommandType -ne "Alias" }
        $common = [CommonParameters].GetProperties().name
        if ($baseC) {
            $dict = [RuntimeDefinedParameterDictionary]::new()
            $baseC.Parameters.GetEnumerator() | ForEach {
                $val = $_.value
                $key = $_.key
                if ($key -notin $common) {
                    $param = [RuntimeDefinedParameter]::new($key, $val.parameterType, $val.attributes)
                    $dict.add($key, $param)
                }
            }
            return $dict
        }
    }

}
