
<#

Loaded from https://gist.github.com/ksumrall/3b7010a9fbc9c5cb19e9dc8b9ee32fb1

# TODO [ ] rework this module to work better with arrays or extended PSCustomObjects

#>


# This one only joins values, but does not create new members
# So the result contains all members of source and changed values from extend
function Join-Objects($source, $extend){
    if($source.GetType().Name -eq "PSCustomObject" -and $extend.GetType().Name -eq "PSCustomObject"){
        foreach($Property in $source | Get-Member -type NoteProperty, Property){
            if($extend.$($Property.Name) -eq $null){
              continue;
            }
            $source.$($Property.Name) = Join-Objects $source.$($Property.Name) $extend.$($Property.Name)
        }
    }else{
       $source = $extend;
    }
    # check for an array type. powershell will convert this to a primitive if it is an array of fewer than 2 values
    if($source.GetType().Name -eq "Object[]" -and $source.Count -lt 2){
        return ,$source
    }else{
        return $source
    }
}