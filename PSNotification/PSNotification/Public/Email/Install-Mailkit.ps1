


#-----------------------------------------------
# SOME CHECKS
#-----------------------------------------------

# Check elevation
if ($os -eq "Windows") {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    Write-Log -Message "User: $( $identity.Name )"
    Write-Log -Message "Elevated: $( $isElevated )"
} else {
    Write-Log -Message "No user and elevation check due to OS"
}


# Check execution policy
$executionPolicy = Get-ExecutionPolicy
Write-Log -Message "Your execution policy is currently: $( $executionPolicy )" -Severity VERBOSE


#-----------------------------------------------
# NUGET SETTINGS
#-----------------------------------------------

$packageSourceName = "NuGet" # otherwise you could create a local repository and put all dependencies in there. You can find more infos here: https://github.com/Apteco/HelperScripts/tree/master/functions/Log#installation-via-local-repository
$packageSourceLocation = "https://www.nuget.org/api/v2"
$packageSourceProviderName = "NuGet"


#-----------------------------------------------
# CHECK PACKAGES NUGET REPOSITORY
#-----------------------------------------------


# Get NuGet sources
$sources = @( Get-PackageSource -ProviderName $packageSourceProviderName ) #| where { $_.Location -like "https://www.nuget.org*" }

# See if Nuget needs to get registered
If ( $sources.count -ge 1 ) {
    Write-Log -Message "You have at minimum 1 $( $packageSourceProviderName ) repository. Good!" -Severity VERBOSE
} elseif ( $sources.count -eq 0 ) {
    Write-Log -Message "You don't have $( $packageSourceProviderName ) as a PackageSource, do you want to register it now?" -Severity WARNING
    $registerNugetDecision = $Host.UI.PromptForChoice("", "Register $( $packageSourceProviderName ) as repository?", @('&Yes'; '&No'), 1)
    If ( $registerNugetDecision -eq "0" ) {

        # Means yes and proceed
        Register-PackageSource -Name $packageSourceName -Location $packageSourceLocation -ProviderName $packageSourceProviderName

        # Load sources again
        $sources = @( Get-PackageSource -ProviderName $packageSourceProviderName ) #| where { $_.Location -like "https://www.nuget.org*" }

    } else {
        # Means no and leave
        Write-Log "No package repository found! Please make sure to add a NuGet repository to your machine!" -Severity ERROR
        exit 0
    }
}

Find-Package -Name MailKit | Sort-Object Source, Name, Version | Install-Package
Find-Package -Name MimeKit | Sort-Object Source, Name, Version | Install-Package