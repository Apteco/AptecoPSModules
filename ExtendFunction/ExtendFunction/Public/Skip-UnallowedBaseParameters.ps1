
Function Skip-UnallowedBaseParameters {

<#
    .SYNOPSIS
        Excludes additional parameters that are not being used by already existing functions/cmdlets

    .DESCRIPTION
        Apteco PS Modules - PowerShell functions extension

        This function helps to sort out all parameters that the original function/cmdlet has.

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

    .PARAMETER Parameters
        The hashtable of parameters that were sent to the function

    .EXAMPLE
        Skip-UnallowedBaseParameters -Base "Invoke-WebRequest" -Parameters $PSBoundParameters
        
    .INPUTS
        String

    .OUTPUTS
        Hashtable

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>
    [CmdletBinding()]
    param(
         [Parameter(Mandatory=$true)][string]$Base
        ,[Parameter(Mandatory=$true)][Hashtable]$Parameters
    )

    Process {
        $baseParameters = Get-BaseParameters -Base $Base
        $common = [CommonParameters].GetProperties().name
        
        $ht = [hashtable]@{}
        $Parameters.GetEnumerator() | where { $_.Name -in @( $baseParameters.Keys + $common ) } | ForEach {
            $key = $_.Key
            $ht.add($key, $Parameters[$key])
        }

        # return
        $ht 
    }

}