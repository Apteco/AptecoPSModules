function Reset-HashCache {
    [CmdletBinding()]
    param(
    )
  
    begin {

    }

    process {
        $Script:knownHashes.clear()
        $true
    }

    end {
      
    }

}