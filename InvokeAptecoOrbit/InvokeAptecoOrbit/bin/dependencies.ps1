$Script:psScripts = [Array]@(
)

$Script:psModules = [Array]@(
    "EncryptCredential"
    #"ImportDependency" # This module is already in the psd1 file as a dependency, so it will be automatically imported when the module is imported. No need to install it separately.
)

# Define either a simple string or provide a pscustomobject with a specific version number
$Script:psPackages = [Array]@(
)

$Script:psAssemblies = [Array]@(
)
