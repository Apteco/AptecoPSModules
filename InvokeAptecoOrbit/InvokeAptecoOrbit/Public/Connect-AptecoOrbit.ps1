function Connect-AptecoOrbit {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Establishes a session against an Apteco Orbit API instance.

    .DESCRIPTION
        Apteco PS Modules - Apteco Orbit API session handling

        Call this once before using Invoke-AptecoOrbit, Get-AptecoOrbitPagedData or
        Get-AptecoOrbitCampaigns. The session/access token is cached to disk (encrypted at rest
        via EncryptCredential by default) and reused until it expires, so repeated script runs
        do not need to log in every time.

    .PARAMETER BaseUrl
        Base url of the Orbit API, e.g. https://partner.apteco.io/OrbitAPI/

    .PARAMETER DataView
        The DataView to authenticate against

    .PARAMETER Credential
        Username/password to authenticate with

    .PARAMETER LoginType
        "SIMPLE" (default) or "SALTED", matching what the target Orbit instance expects.

    .PARAMETER SessionFile
        Where to cache the session. Defaults to a file in the temp folder.

    .PARAMETER Ttl
        Session time to live in minutes. Default 60.

    .PARAMETER EncryptToken
        Whether to encrypt the cached session token at rest via EncryptCredential. Default $true.

    .PARAMETER Force
        Ignore a cached session on disk and log in again.

    .EXAMPLE
        Connect-AptecoOrbit -BaseUrl "https://partner.apteco.io/OrbitAPI/" -DataView "Demo" -Credential (Get-Credential)

    .EXAMPLE
        Connect-AptecoOrbit -DataView "Demo" -Credential (Get-Credential) -Force

    .INPUTS
        None

    .OUTPUTS
        $null

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
         [Parameter(Mandatory=$false)][String]$BaseUrl = $Script:settings.base
        ,[Parameter(Mandatory=$true)][String]$DataView
        ,[Parameter(Mandatory=$true)]
         [System.Management.Automation.PSCredential]
         [System.Management.Automation.Credential()]$Credential
        ,[Parameter(Mandatory=$false)][ValidateSet("SIMPLE","SALTED")][String]$LoginType = $Script:settings.loginType
        ,[Parameter(Mandatory=$false)][String]$SessionFile = $Script:settings.sessionFile
        ,[Parameter(Mandatory=$false)][Int]$Ttl = $Script:settings.ttl
        ,[Parameter(Mandatory=$false)][Bool]$EncryptToken = $Script:settings.encryptToken
        ,[Parameter(Mandatory=$false)][Switch]$Force = $false
    )

    Set-OrbitTlsProtocol

    $Script:settings.base = $BaseUrl.TrimEnd("/") + "/"
    $Script:settings.dataView = $DataView
    $Script:settings.loginType = $LoginType
    $Script:settings.sessionFile = $SessionFile
    $Script:settings.ttl = $Ttl
    $Script:settings.encryptToken = $EncryptToken
    $Script:credential = $Credential
    $Script:endpoints = $null

    [void]( Get-OrbitEndpoints )
    Get-OrbitSession -Force:$Force

}
