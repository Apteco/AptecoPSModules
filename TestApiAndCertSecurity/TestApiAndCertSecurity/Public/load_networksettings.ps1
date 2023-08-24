
<#

GOOD HINT! Currently https://www.powershellgallery.com/api/v2 only supports TLSv1.2!!!

#>




# Allow only newer security protocols
# hints: https://www.frankysweb.de/powershell-es-konnte-kein-geschuetzter-ssltls-kanal-erstellt-werden/
<#
if ( $settings.changeTLS -eq $true ) {
    $AllProtocols = @(    
        [System.Net.SecurityProtocolType]::Tls11
    )
    [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
}
#>

#-----------------------------------------------
# CHECK VALID SECURITY SETTINGS
#-----------------------------------------------

# Define the url to test with
$url = $settings.connectionTestUrl

# Define the different commands in a specific order to try to establish the connection
$establishConnection = [Array]@(

    [ScriptBlock]{
        #$AllProtocols = @(    
        #    [System.Net.SecurityProtocolType]::Tls12
        #)
        #[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -uri $url -Verbose #-ErrorVariable $ef -WarningVariable $w #-ErrorAction SilentlyContinue -ErrorVariable $e
    }

    [ScriptBlock]{
        #$AllProtocols = @(    
        #    [System.Net.SecurityProtocolType]::Tls11
        #)
        #[System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls11
        Invoke-WebRequest -uri $url -Verbose
    }

    [ScriptBlock]{
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
        Invoke-WebRequest -uri $url -Verbose
    }

)

# This is checked after the call, but also in the catch area to allow e.g. to see if there was a response, but the exception was caused by unauthorization
$measureSuccess = [ScriptBlock]{
    Param ($param1)

    $null -ne $param1.Exception.Response

}

# Now try to establish the connection
$success = $false
$tries = 0
Do {
    
    try {
        Invoke-Command -ScriptBlock $establishConnection[$tries]
        $success = Invoke-Command -ScriptBlock $measureSuccess
    } catch {

        If ( $PSEdition -eq "Core" ) {
            If ( $_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] ) {
                $success = Invoke-Command -ScriptBlock $measureSuccess -ArgumentList $_
            } else {
                Write-Error "Other Error"
            }
        } else {
            If ( $_.Exception -is [System.Net.WebException] ) {
                $success = Invoke-Command -ScriptBlock $measureSuccess -ArgumentList $_
            } else {
                Write-Error "Other Error"
            }
        }

    } 
    $tries += 1

} Until ( $success -eq $true -or $tries -eq $establishConnection.Count )

# Output the result
If ( $tries -lt $establishConnection.Count ) {
    Write-Host "Success after $( $tries ) tries"
} else {
    Write-Error "No successful connection"
}








#-----------------------------------------------
# ASK FOR REGISTRY CHANGES, IF STILL NOT SUCCESSFUL
#-----------------------------------------------

<#
https://success.outsystems.com/Support/Troubleshooting/Application_runtime/Enable_SSL_for_your_integrations_-_TLS_1.1_and_TLS_1.2
https://www.alitajran.com/check-tls-settings-windows-server/

#>


    #-----------------------------------------------
    # REMEMBER CURRENT LOCATION
    #-----------------------------------------------

    # current path - will get back to this at the end
    Push-Location


    #-----------------------------------------------
    # SET .NET2 32 BIT
    #-----------------------------------------------

    # Switch to registry - choose the current user to not need admin rights
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727"

    # Check keys
    $keyName = "SchUseStrongCrypto"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }

    $keyName = "SystemDefaultTlsVersions"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }


    #-----------------------------------------------
    # SET .NET2 64 BIT
    #-----------------------------------------------

    # Switch to registry - choose the current user to not need admin rights
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727"

    # Check keys
    $keyName = "SchUseStrongCrypto"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }

    $keyName = "SystemDefaultTlsVersions"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }


    #-----------------------------------------------
    # SET .NET4 32 BIT
    #-----------------------------------------------

    # Switch to registry - choose the current user to not need admin rights
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"

    # Check keys
    $keyName = "SchUseStrongCrypto"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }

    $keyName = "SystemDefaultTlsVersions"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }


    #-----------------------------------------------
    # SET .NET4 64 BIT
    #-----------------------------------------------

    # Switch to registry - choose the current user to not need admin rights
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"

    # Check keys
    $keyName = "SchUseStrongCrypto"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }

    $keyName = "SystemDefaultTlsVersions"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }


    #-----------------------------------------------
    # SET TLS CLIENT 1.2
    #-----------------------------------------------

    # The way as activating TLS 1.2 here, could also be used to deactivate TLS1.0 or TLS1.1

    # Switch to registry - choose the current user to not need admin rights
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

    # Create sub item and switch to it
    $itemName = "TLS 1.2"
    If ( (Test-Path -Path $itemName) -eq $false) {
        New-Item -Path ".\" -Name $itemName
    }
    Set-Location -Path $itemName

    # Create another sub item and switch to it
    $itemName = "Client"
    If ( (Test-Path -Path $itemName) -eq $false) {
        New-Item -Path ".\" -Name $itemName
    }
    Set-Location -Path $itemName

    # Check keys
    $keyName = "DisabledByDefault"
    $value = 0
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }

    $keyName = "Enabled"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }


    #-----------------------------------------------
    # SET TLS SERVER 1.2
    #-----------------------------------------------

    # The way as activating TLS 1.2 here, could also be used to deactivate TLS1.0 or TLS1.1

    # Switch to registry - choose the current user to not need admin rights
    Set-Location -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

    # Create sub item and switch to it
    $itemName = "TLS 1.2"
    If ( (Test-Path -Path $itemName) -eq $false) {
        New-Item -Path ".\" -Name $itemName
    }
    Set-Location -Path $itemName

    # Create another sub item and switch to it
    $itemName = "Server"
    If ( (Test-Path -Path $itemName) -eq $false) {
        New-Item -Path ".\" -Name $itemName
    }
    Set-Location -Path $itemName

    # Check keys
    $keyName = "DisabledByDefault"
    $value = 0
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }

    $keyName = "Enabled"
    $value = 1
    $type = "DWord"
    If (  (Get-ItemProperty ".\" -Name $keyName -ErrorAction Ignore ) -eq $null  ) {
        New-ItemProperty -Path ".\" -Name $keyName -PropertyType $type -Value $value
    } else {
        Set-ItemProperty -Path ".\" -Name $keyName -Value $value
    }


    #-----------------------------------------------
    # GET BACK TO CURRENT LOCATION
    #-----------------------------------------------

    # Go back to original path
    Pop-Location


    #-----------------------------------------------
    # RESTART SERVER NOTICE
    #-----------------------------------------------

    Write-Warning "Please restart the server now"





#-----------------------------------------------
# ADD PROXY SETTINGS
#-----------------------------------------------

# Setup default credentials for proxy communication per default
$proxyUrl = $null
if ( $settings.proxy.proxyUrl ) {
    $proxyUrl = $settings.proxy.proxyUrl
    $useDefaultCredentials = $true

    if ( $settings.proxy.proxyUseDefaultCredentials ) {
        $proxyUseDefaultCredentials = $true
        [System.Net.WebRequest]::DefaultWebProxy.Credentials=[System.Net.CredentialCache]::DefaultCredentials
    } else {
        $proxyUseDefaultCredentials = $false
        $proxyCredentials = New-Object PSCredential $settings.proxy.credentials.username,( Get-SecureToPlaintext -String $settings.proxy.credentials.password )
    }

}

function Check-Proxy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][Hashtable]$invokeParams
    )
    
    begin {
        
    }
    
    process {
        if ( $script:proxyUrl ) {
            $invokeParams.Add("Proxy", $script:proxyUrl)
            $invokeParams.Add("UseDefaultCredentials", $script:useDefaultCredentials)
            if ( $script:proxyUseDefaultCredentials ) {
                $invokeParams.Add("ProxyUseDefaultCredentials", $true)
            } else {
                $invokeParams.Add("ProxyCredential", $script:proxyCredentials)         
            }
        }
    }
    
    end {
        
    }
}

<#
# Add proxy settings
if ( $proxyUrl ) {
    $paramsPost.Add("Proxy", $proxyUrl)
    $paramsPost.Add("UseDefaultCredentials", $useDefaultCredentials)
    if ( $proxyUseDefaultCredentials ) {
        $paramsPost.Add("ProxyUseDefaultCredentials", $true)
    } else {
        $paramsPost.Add("ProxyCredential", $proxyCredentials)         
    }
}
#>


<#
# The following can be added to api calls
if ( $proxyUrl ) {
    $paramsPost.Add("UseDefaultCredentials", $useDefaultCredentials)
    $paramsPost.Add("Proxy", $proxyUrl)
}
#if ( $settings.useDefaultCredentials ) {
#    $paramsPost.Add("UseDefaultCredentials", $true)
#}
$paramsPost.Add("ProxyCredential", pscredential)
if ( $settings.ProxyUseDefaultCredentials ) {
    $paramsPost.Add("ProxyUseDefaultCredentials", $true)
}
#>

#-----------------------------------------------
# DEACTIVATE CERTIFICATE CHECK IF WISHED
#-----------------------------------------------

<# 
Code to obtain certificate SHA256 hashes and also deactivate certificate checks, if wished

For PowerShell Core call URLs with invalid certificates like:

Invoke-RestMethod -Uri https://sachsenstation -SkipCertificateCheck

Got this code from: https://www.jeansnyman.com/posts/invoke-rest-method-self-signed-certificate-errors/

#>


if ( $settings.deactivateCertificateCheck -eq $true ) {

    # This is the way for PowerShell Core
    if ($PSEdition -ne 'Core'){

        Write-Host "Please add the flag -SkipCertificateCheck to your Invoke-RestMethod and Invoke-WebRequest calls"

    # This is the way for Windows PowerShell - only execute this time and call the APIs as usual
    } else {

        $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
        Add-Type $certCallback
    
        [ServerCertificateValidationCallback]::Ignore()

    }

}

