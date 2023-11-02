function Add-ToHashCache {
    [CmdletBinding()]
      param(
           [parameter(Mandatory = $true, ValueFromPipeline)][String]$InputHash
      )
  
    begin {
      #[Collections.ArrayList]$inputObjects = @()
    }
    process {
      #[void]$inputObjects.Add($Input)
      #$row | ForEach-Object { $_ | Add-Member -MemberType NoteProperty -Name "hash" -value ( Get-StringHash -InputString "$( $_.adresse )$( $_.plz )AachenDE".tolower() -HashName sha256 ) }
      [void]$Script:knownHashes.add($InputHash)
    }
    end {
      #$inputObjects | Foreach-Object -Parallel {
          #$row = $_
  
      #}
    }
  }