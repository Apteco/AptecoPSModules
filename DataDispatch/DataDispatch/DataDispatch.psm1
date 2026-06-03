
#-----------------------------------------------
# LOAD PUBLIC FUNCTIONS
#-----------------------------------------------

$Public = @( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue )

@( $Public ) | ForEach-Object {
    $import = $_
    Try {
        . $import.FullName
    } Catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
