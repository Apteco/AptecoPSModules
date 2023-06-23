
<#

Loaded from https://gist.github.com/ksumrall/3b7010a9fbc9c5cb19e9dc8b9ee32fb1

# TODO [ ] rework this module to work better with arrays or extended PSCustomObjects

#>


# This one extends toExtend with all members of source
function Add-PropertyRecurse($source, $toExtend){
    if($source.GetType().Name -eq "PSCustomObject"){
        foreach($Property in $source | Get-Member -type NoteProperty, Property){
            #Write-verbose $Property -Verbose
            if($toExtend.$($Property.Name) -eq $null){
              $toExtend | Add-Member -MemberType NoteProperty -Value $source.$($Property.Name) -Name $Property.Name `
            }
            else{
               $toExtend.$($Property.Name) = Add-PropertyRecurse $source.$($Property.Name) $toExtend.$($Property.Name)
            }
        }
    }
    return $toExtend
}

