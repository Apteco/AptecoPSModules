Function Install-VcRedist {

    <#
    .SYNOPSIS
        Checks whether the Visual C++ Redistributable (x64) is installed and installs it if missing.
    .DESCRIPTION
        Needed for DuckDB (and other native NuGet packages) to load correctly. Checks the registry for an
        installed x64 Visual C++ Redistributable. If it's missing, downloads the newest x64 vc_redist from
        Microsoft and installs it quietly. By default this asks for confirmation before installing; use
        -Force to skip that prompt for unattended/automated installs.

        Returns $true if vcredist x64 is installed by the end of the call (whether it already was, or was
        just installed), $false otherwise.
    .PARAMETER Force
        Skip the interactive "do you want to install?" prompt and install directly if missing.
    .PARAMETER DownloadUri
        Where to download vc_redist.x64.exe from. Defaults to the official Microsoft permalink for the
        latest x64 Visual C++ Redistributable.
    .EXAMPLE
        Install-VcRedist -Verbose
    .EXAMPLE
        Install-VcRedist -Force
    .NOTES
        Created by : gitfvb
    #>

    [CmdletBinding()]
    Param(

         [Parameter(Mandatory=$false)]
         [Switch]$Force = $false

        ,[Parameter(Mandatory=$false)]
         [String]$DownloadUri = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

    )

    Process {

        If ( $Script:os -ne "Windows" ) {
            Write-Verbose "vcredist is only relevant on Windows, skipping"
            return $true
        }

        Write-Verbose "Checking vcredist"
        $status = Get-VcRedistStatus

        If ( $status.Installed -eq $true -and $status.Is64Bit -eq $true ) {
            Write-Verbose "vcredist x64 is already installed"
            return $true
        }

        If ( $Force -ne $true ) {

            Write-Warning "vcredist x64 is not installed. This is needed for DuckDB, but not to run this module in general."
            $vcredistChoice = Request-Choice -title "Install vcredist?" -message "Do you want to install the newest x64 vcredist?" -choices @("Yes", "No")

            If ( $vcredistChoice -ne 1 ) {
                Write-Verbose "Not installing vcredist"
                return $false
            }

        }

        Write-Verbose "Installing vcredist... This will need a few minutes"

        $vcredistTargetFile = Join-Path -Path ( [System.Environment]::GetEnvironmentVariable("TMP") ) -ChildPath "vc_redist.x64.exe"

        # Downloading with Bits as this package is windows only
        Start-BitsTransfer -Destination $vcredistTargetFile -Source $DownloadUri

        # Install/Update file quietly
        Start-Process -FilePath $vcredistTargetFile -ArgumentList "/install /q /norestart" -Verb RunAs -Wait

        Write-Verbose "vcredist installer finished, re-checking"
        $status = Get-VcRedistStatus

        If ( $status.Installed -eq $true -and $status.Is64Bit -eq $true ) {
            Write-Verbose "vcredist x64 successfully installed"
        } else {
            Write-Warning "vcredist installation could not be verified"
        }

        return ( $status.Installed -eq $true -and $status.Is64Bit -eq $true )

    }

}
