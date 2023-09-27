function Send-Email {


    [CmdletBinding()]
    param (
        # [Parameter(Mandatory = $true)][string]$Name        # Give the channel a name, this is the "identifier for this channel"
        #,[Parameter(Mandatory = $true)][string]$Message 
    )
    
    begin {
        
    }
    
    process {
        
        # Load libs first
        If ( $Script:libFolderLoadedIndicator -eq $false ) {
            Load-LibFolder
        }

        #Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MailKit.2.8.0\lib\netstandard2.0\MailKit.dll"
        #Add-Type -Path "C:\Program Files\PackageManagement\NuGet\Packages\MimeKit.2.9.1\lib\netstandard2.0\MimeKit.dll"
        $SMTP     = New-Object MailKit.Net.Smtp.SmtpClient
        $Message  = New-Object MimeKit.MimeMessage
        $TextPart = [MimeKit.TextPart]::new("plain")
        $TextPart.Text = "This is a test."
        $Message.From.Add("myemail1@gmail.com")
        $Message.To.Add("myemail2@somewhereelse.com")
        $Message.Subject = 'Test Message'
        $Message.Body    = $TextPart
        $SMTP.Connect('smtp.gmail.com', 587, $False)
        $SMTP.Authenticate('myemail1@gmail.com', 'appspecificpassword' )
        $SMTP.Send($Message)
        $SMTP.Disconnect($true)
        $SMTP.Dispose()

    }
    
    end {
        
    }
}