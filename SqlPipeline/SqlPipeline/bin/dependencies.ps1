
$psScripts = @(
    #"WriteLogfile"
)

$psModules = @(
    #"SimplySql"
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
$psPackages = @(
    <#
    [PSCustomObject]@{
        name="Npgsql"
        version = "4.1.12"
    }
    #>
)

$psAssemblies = @(
    #"System.Web"
)