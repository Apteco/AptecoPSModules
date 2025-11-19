
function Install-MailKit {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        #install-script install-dependencies, import-dependencies -force -verbose
        #Install-Dependencies -LocalPackage MailKit -verbose
        #Import-Dependencies.ps1 -LoadWholePackageFolder -LocalPackageFolder "./lib"

        # This installation includes Mimekit
        Install-Dependencies -LocalPackage MailKitLite -LocalPackageFolder "$( $Script:localLibFolder )" #-verbose

        # TODO save an indikator or bool flag, if it already has been installed

    }

    end {

    }
}
