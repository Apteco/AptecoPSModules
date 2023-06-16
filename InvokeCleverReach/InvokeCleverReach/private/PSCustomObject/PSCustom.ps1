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


# This one extends toExtend with all members of source
function AddPropertyRecurse($source, $toExtend){
    if($source.GetType().Name -eq "PSCustomObject"){
        foreach($Property in $source | Get-Member -type NoteProperty, Property){
            if($toExtend.$($Property.Name) -eq $null){
              $toExtend | Add-Member -MemberType NoteProperty -Value $source.$($Property.Name) -Name $Property.Name `
            }
            else{
               $toExtend.$($Property.Name) = AddPropertyRecurse $source.$($Property.Name) $toExtend.$($Property.Name)
            }
        }
    }
    return $toExtend
}


function Json-Merge($source, $extend){
    $merged = Join-Objects $source $extend
    # this is causing a problem with arrays.
    # $extended = AddPropertyRecurse $source $merged
    return $merged

}

#read json files into PSCustomObjects like this:
#$1 = Get-Content 'C:\Beijer\smith-env-settings\1.json' -Raw | ConvertFrom-Json
#$2 = Get-Content 'C:\Beijer\smith-env-settings\2.json'-Raw | ConvertFrom-Json
#Merge properties of the first one and second one.
#$3 = Json-Merge $1 $2