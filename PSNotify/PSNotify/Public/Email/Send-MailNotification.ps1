function Send-Mailnotification {

    [CmdletBinding()]
    param (
        
         [Parameter(Mandatory=$true)]
         [ValidateNotNullOrEmpty()]
         [String]$Name                                # The email channel to use
        
        ,[Parameter(Mandatory=$true)]
         [ValidateNotNullOrEmpty()]
         [String]$Target                                # The email target to use
        
        ,[Parameter(Mandatory=$true)]
         [ValidateNotNullOrEmpty()]
         [String]$Subject                                # The email subject
        
        ,[Parameter(Mandatory=$true)]
         [ValidateNotNullOrEmpty()]
         [String]$Text                                # The email text
        
        ,[Parameter(Mandatory=$false)]
         [String[]]$Attachment = [Array]@()
    
    )

    begin {

        # Check Attachment parameter
        If ( $Attachment -isnot [Array] ) {
            $Attachment = @($Attachment)
        }

        # Check path of attachments
        foreach ( $att in $Attachment ) {
            If ( ( Test-Path -Path $att ) -ne $true ) {
                throw "Attachment path '$( $att )' is not valid. Aborting now"
            }
        }

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
        
        #$textPart = [MimeKit.TextPart]::new("plain")
        #$textPart.Text = $Text
        #$message.Body = $TextPart

        $builder = [MimeKit.BodyBuilder]::new()
        $builder.TextBody = $Text
        $Attachments | ForEach-Object {
            $builder.Attachments.Add($_)
        }
        $message.Body = $builder.ToMessageBody()
        
        # Add attachment if provided
        <#
        If ( $Attachment -ne $null ) {
            $attachmentPart = [MimeKit.MimePart]::new("application", "octet-stream")
            $attachmentPart.Content = [MimeKit.MimeContent]::new([System.IO.File]::OpenRead($Attachment), [MimeKit.ContentEncoding]::Base64)
            $attachmentPart.ContentDisposition = [MimeKit.ContentDisposition]::new([MimeKit.ContentDispositionType]::Attachment)
            $attachmentPart.FileName = [System.IO.Path]::GetFileName($Attachment)

            $multipart = [MimeKit.Multipart]::new("mixed")
            $multipart.Add($textPart)
            $multipart.Add($attachmentPart)

            $message.Body = $multipart
        }
        #>

        # Send the message
        $msg = $smtpClient.Send($message)
        Write-Verbose $msg

        # Kill that connection
        $smtpClient.Disconnect($true)
        $smtpClient.Dispose()

    }

}