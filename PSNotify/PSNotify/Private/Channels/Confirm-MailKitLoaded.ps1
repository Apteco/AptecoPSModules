function Confirm-MailKitLoaded {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        
    }
    
    process {
        
        $success = $false

        # Check, if lib folder exists
        If ( (Test-Path -Path $Script:localLibFolder) -eq $false ) {
            throw "Local lib folder '$( $Script:localLibFolder )' does not exist"
        }

        # Load libs first
        If ( $Script:libFolderLoadedIndicator -eq $false ) {
            Import-LibFolder
        }

        # Check if Mailkit and Mimekit are properly loaded
        try {
            $smtp = [MailKit.Net.Smtp.SmtpClient]::new()
            $message = [MimeKit.MimeMessage]::new()
            $success = $true
        } catch {
            throw "Libraries are not properly loaded, please check or install first"
        }

        # return
        $success

    }
    
    end {
        
    }
}
