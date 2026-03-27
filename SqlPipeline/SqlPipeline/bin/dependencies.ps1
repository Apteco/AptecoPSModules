
$Script:psScripts = [Array]@(
    #"WriteLogfile"
)

$Script:psModules = [Array]@(
    "SimplySql"
    #"ImportDependency" # This module is already in the psd1 file as a dependency, so it will be automatically imported when the module is imported. No need to install it separately.
    #"WriteLog"
    #"MeasureRows"
    #"EncryptCredential"
    #"ExtendFunction"
    #"ConvertUnixTimestamp"
    #"ConvertStrings"
    #"Microsoft.PowerShell.Utility"
    #"MergePSCustomObject"
    #"MergeHashtable"
)

# Define either a simple string or provide a pscustomobject with a specific version number
$Script:psPackages = [Array]@(
    "DuckDB.NET.Bindings.Full"
    "DuckDB.NET.Data.Full"
    <#
    [PSCustomObject]@{
        name="Npgsql"
        version = "4.1.12"
    }
    #>
)

$Script:psAssemblies = [Array]@(
    #"System.Web"
)