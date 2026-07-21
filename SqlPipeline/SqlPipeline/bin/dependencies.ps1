
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

    # Windows PowerShell 5.1 (.NET Framework) can only load the netstandard2.0 build of DuckDB.NET,
    # which was dropped after 1.4.4 -- pin that exact version, plus the two BCL polyfills its
    # netstandard2.0 dependency group declares (System.Memory, System.Runtime.CompilerServices.Unsafe;
    # see DuckDB.NET.Data.Full's own .nuspec), so pwsh and Windows PowerShell can share one lib folder.
    # pwsh does not need these three, but installing them there too is harmless.
    # ImportDependency's Select-CompatiblePackage picks the matching version at import time.
    #
    # Pin System.Runtime.CompilerServices.Unsafe to exactly 6.0.0, not a later one: nupkg version and
    # embedded AssemblyVersion drift apart for this package, and 6.1.0's net462 build embeds
    # AssemblyVersion 6.0.1.0 while its netstandard2.0 build embeds 6.0.0.0. Windows PowerShell prefers
    # net462 over netstandard2.0, so 6.1.0 loads the wrong identity there and DuckDB.NET.Bindings 1.4.4
    # (built against 6.0.0.0) fails at first use with a FileNotFoundException. 6.0.0 has no net462 build
    # at all, so every build it does ship reports 6.0.0.0 consistently.
    [PSCustomObject]@{ Name = "DuckDB.NET.Bindings.Full"; Version = "1.4.4" }
    [PSCustomObject]@{ Name = "DuckDB.NET.Data.Full";     Version = "1.4.4" }
    [PSCustomObject]@{ Name = "System.Memory";            Version = "4.6.0" }
    [PSCustomObject]@{ Name = "System.Runtime.CompilerServices.Unsafe"; Version = "6.0.0" }

    # pwsh (Core): always take the newest DuckDB.NET build directly, no version pin needed
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