function Add-EmailChannel {


    [CmdletBinding()]
    param (
         [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        ,[Parameter(Mandatory = $true)][string]$From
        ,[Parameter(Mandatory = $true)][string]$Username
        ,[Parameter(Mandatory = $true)][string]$Password
        ,[Parameter(Mandatory = $true)][string]$Host
        ,[Parameter(Mandatory = $false)][int]$Port = 587
        ,[Parameter(Mandatory = $false)][Switch]$UseSSL = $false
        #,[Parameter(Mandatory = $true)][string]$Token
    )

    begin {

    }

    process {

        # Load mailkit lib
        If ( ( Confirm-MailKitLoaded ) -eq $true ) {
            Write-Verbose "MailKit loaded successfully"
        } else {
            Write-Error $_.Exception
            throw "You need to install MailKit first. Please execute Install-Mailkit!" # TODO maybe the throw is not needed here
        }

        # Try connect to server
        try {
            Write-Verbose "Connecting to mailserver"
            $smtpClient = [MailKit.Net.Smtp.SmtpClient]::new()
            $smtpClient.Connect($Host, $Port, $UseSSL) # $SMTP.Connect('smtp.gmail.com', 587, $False)
        } catch {
            Write-Error $_.Exception
            throw "Connection to host '$( $Host )' failed!"
        }

        # Try to authenticate
        try {
            Write-Verbose "Authentication to mailserver"
            $smtpClient.Authenticate($Username, $Password) # $SMTP.Authenticate('myemail1@gmail.com', 'appspecificpassword' )
        } catch {
            Write-Error $_.Exception
            throw "Authentication to host '$( $Host )' failed!"
        }

        # Kill that connection
        $smtpClient.Disconnect($true)
        $smtpClient.Dispose()

        # This is customised for email
        $valueUseSSL = $false
        If ( $UseSSL -eq $true ) {
            $valueUseSSL = $true
        }
        $definition = [PSCustomObject]@{
            "from" = $From
            "username" = $Username
            "password" = Convert-PlaintextToSecure -String $Password
            "port" = $Port
            "host" = $Host
            "ssl" = $valueUseSSL
        }

        # Add the channel
        Add-Channel -Type "Email" -Name $Name -Definition $definition

    }

    end {

    }

}