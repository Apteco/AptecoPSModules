
$psScripts = [Array]@(
    "Install-Dependencies"
    "Import-Dependencies"
)

$psModules = [Array]@(
    "WriteLog"
    "MeasureRows"
    "EncryptCredential"
    "ExtendFunction"
    "ConvertUnixTimestamp"
    #"Microsoft.PowerShell.Utility"
    #"PSOAUth"  # is defined in the local plugins where it is needed
)


$psGlobalPackages = [Array]@(

)


# Define either a simple string or provide a pscustomobject with a specific version number
$psLocalPackages = [Array]@(
    <#
    [PSCustomObject]@{
        name="Npgsql"
        version = "4.1.12"
        includeDependencies = $true
    }

    [PSCustomObject]@{
        name="MailKit"
        #version = "4.1.12"
        includeDependencies = $false
    }

    [PSCustomObject]@{
        name="System.Data.Sqlite"
        #version = "4.1.12"
        includeDependencies = $false
    }

    #>

)

$psAssemblies = [Array]@(

)