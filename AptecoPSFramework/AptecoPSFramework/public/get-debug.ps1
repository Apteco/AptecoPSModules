
Function Get-Debug {
<#

Public function to get a debug variable that is saved on module level
Can be used to debug the whole thing

#>
    [cmdletbinding()]
    param(
        
    )

    Process {
       
        $Script:debug

    }


}