function Get-CurrentWindowsIdentity {
    <#
    .SYNOPSIS
    Gets the current Windows identity and elevation status.
    
    .DESCRIPTION
    Retrieves the current Windows user identity and checks if the current process
    has administrator (elevated) privileges.
    
    .OUTPUTS
    PSCustomObject with properties:
    - ExecutingUser: The current user's Windows identity name
    - IsElevated: Boolean indicating if running with administrator privileges
    
    .EXAMPLE
    PS> $identity = Get-CurrentWindowsIdentity
    PS> $identity.ExecutingUser
    PS> $identity.IsElevated
    #>
    
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $executingUser = $identity.Name
        $principal = [Security.Principal.WindowsPrincipal]::new($identity)
        $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        
        return [PSCustomObject]@{
            ExecutingUser = $executingUser
            IsElevated    = $isElevated
        }
    } catch {
        Write-Verbose "Could not determine Windows identity: $_"
        return [PSCustomObject]@{
            ExecutingUser = $null
            IsElevated    = $false
        }
    }
}
