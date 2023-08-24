
<#
#-----------------------------------------------
# SET FASTSTATS SYSTEM
#-----------------------------------------------

# Get Systems
$systems = Invoke-Apteco -key "GetFastStatsSystems" -additional @{dataViewName=$dataview}

# Choose system 
# TODO [ ] is viewName the correct one?
if ( $systems.totalCount -gt 1 ) {
    $system = ( $systems.list | Out-GridView -PassThru ).viewName
} elseif ( $systems.totalCount -eq 0 ) {
    "No systems"
    exit 0
} else {
    $system = $systems.list[0].viewName
}


#-----------------------------------------------
# SET PEOPLESTAGE SYSTEM
#-----------------------------------------------

# TODO [ ] Check if PS is available and if this is connected to FastStats

# Get Systems
$systems = Invoke-Apteco -key "GetPeopleStageSystems" -additional @{dataViewName=$dataview}

# Choose system 
# TODO [ ] is viewName the correct one?
if ( $systems.totalCount -gt 1 ) {
    $system = ( $systems.list | Out-GridView -PassThru ).systemName
} elseif ( $systems.totalCount -eq 0 ) {
    "No systems"
    exit 0
} else {
    $system = $systems.list[0].systemName
}
#>