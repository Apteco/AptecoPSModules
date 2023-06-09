
$psScripts = @(
    #"WriteLogfile"
)

$psModules = @(
    "WriteLog"
    "MeasureRows"
    "EncryptCredential"
    "ExtendFunction"
    "ConvertUnixTimestamp"
    #"Microsoft.PowerShell.Utility"
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