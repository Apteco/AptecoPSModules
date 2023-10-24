function Send-Mailnotification {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][String]$Name                                # The email channel to use
        ,[Parameter(Mandatory=$true)][String]$Target                                # The email target to use
        ,[Parameter(Mandatory=$true)][String]$Subject                                # The telegram channel to use
        ,[Parameter(Mandatory=$true)][String]$Text                                # The telegram channel to use
    )
    
    begin {
        
    }
    
    process {
        
        # Get the right target for this channel
        $channel = Get-Channel -Name $Name 
        $channelTarget = $channel.Targets | where-object { $_.TargetName -eq $Target }
        #$Script:debug = $target

        # Load mailkit lib
        If ( ( Confirm-MailKitLoaded ) -eq $true ) {
            Write-Verbose "MailKit loaded successfully"
        } else {
            throw "You need to install MailKit first. Please execute Install-Mailkit!" # TODO maybe the throw is not needed here
        }

        # Try connect to server
        try {
            Write-Verbose "Connecting to mailserver"
            $smtpClient = [MailKit.Net.Smtp.SmtpClient]::new()
            $smtpClient.Connect($channel.Definition.host, $channel.Definition.port, $channel.Definition.ssl) # $SMTP.Connect('smtp.gmail.com', 587, $False)
        } catch {
            throw "Connection to host '$( $Host )' failed!"
        }

        # Try to authenticate
        try {
            Write-Verbose "Authentication to mailserver"
            $smtpClient.Authenticate($channel.Definition.username, ( Convert-SecureToPlaintext -String $channel.Definition.password)) # $SMTP.Authenticate('myemail1@gmail.com', 'appspecificpassword' )
        } catch {
            throw "Authentication to host '$( $Host )' failed!"
        }

        # Create the mail        
        $message = [MimeKit.MimeMessage]::new()
        $message.From.Add($channel.Definition.from)
        $channelTarget.Definition.Receivers | ForEach-Object {
            $message.To.Add($_) # TODO not checking if the email is valid
        }
        $message.Subject = $Subject
        $textPart = [MimeKit.TextPart]::new("plain")
        $textPart.Text = $Text
        $message.Body = $TextPart
        
        # Send the message
        $msg = $smtpClient.Send($message)
        Write-Verbose $msg

        # Kill that connection
        $smtpClient.Disconnect($true)
        $smtpClient.Dispose()

    }
    
    end {
        
    }
}