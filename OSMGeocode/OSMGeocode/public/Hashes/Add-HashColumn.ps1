function Add-HashColumn {
  [CmdletBinding()]
  param(
       [parameter(Mandatory = $true, ValueFromPipeline)][PSCustomObject]$InputObject
      ,[Parameter(Mandatory = $false)][String]$HashColumnName = "hash"
      ,[Parameter(Mandatory = $false)][Switch]$AddToHashCache = $false
  )

  begin {
    #[Collections.ArrayList]$inputObjects = @()
  }

  process {
    #[void]$inputObjects.Add($Input)
    #$row | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "hash" -value ( Get-StringHash -InputString "$( $_.adresse )$( $_.plz )AachenDE".tolower() -HashName sha256 ) }
    $hashValue = Get-AddressHash -Address $InputObject -ParameterSetName "search"

    $InputObject | Add-Member -MemberType NoteProperty -Name $HashColumnName -value $hashValue

    If ( $AddToHashCache -eq $true ) {
      Add-ToHashCache -InputHash $hashValue
    }

    # Return
    $InputObject

  }

  end {
    #$inputObjects | Foreach-Object -Parallel {
        #$row = $_

    #}
  }

}