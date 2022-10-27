# Parameters for publishing the module
$Path = ".\WriteLog"
$PublishParams = @{
    NuGetApiKey = 'oy2iflnjm4tzjqljsv6qzkk2m3iyvtjefobuvjs6ug4g7a' # Swap this out with your API key
    Path = (  Resolve-Path -Path $Path )
    #ProjectUri = 'https://github.com/Apteco/AptecoPSModules/tree/main/WriteLog'
    #Tags = @("PSEdition_Desktop", "PSEdition_Core", "Windows", "Apteco")
}

# We install and run PSScriptAnalyzer against the module to make sure it's not failing any tests
Install-Module -Name PSScriptAnalyzer -force
Invoke-ScriptAnalyzer -Path $Path

# Test the publish
Publish-Module @PublishParams -WhatIf -Verbose -Repository PSGallery

# Do the publish
Publish-Module @PublishParams -Verbose -Repository PSGallery

# The module is now listed on the PowerShell Gallery
Find-Module WriteLog