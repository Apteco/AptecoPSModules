
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
    "MergePSCustomObject"
    "MergeHashtable"
)

# Define either a simple string or provide a pscustomobject with a specific version number
$psPackages = @(
    
    [PSCustomObject]@{
        name="System.Data.Sqlite"
        #version = "4.1.12"
    }
    
)

$psAssemblies = @(
    "System.Data"
)