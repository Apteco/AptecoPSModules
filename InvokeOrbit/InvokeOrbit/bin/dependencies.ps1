
$psScripts = @(
    #"WriteLogfile"
)

$psModules = @(
    "WriteLog"
    "SqlServer"
    "MeasureRows"
    "EncryptCredential"
)

# Define either a simple string or provide a pscustomobject with a specific version number
$psPackages = @(
    [PSCustomObject]@{
        name="Npgsql"
        version = "4.1.12"
    }
)