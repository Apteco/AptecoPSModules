


function Import-LibFolder {
    [CmdletBinding()]
    param (

    )

    begin {

    }

    process {

        #install-script install-dependencies, import-dependencies -force -verbose
        #Install-Dependencies -LocalPackage MailKit -verbose

        # This installation includes Mimekit
        #Import-Dependencies -LocalPackage MailKit -LocalPackageFolder "$( $Script:localLibFolder )" #-verbose
        Import-Dependencies -LoadWholePackageFolder -LocalPackageFolder "$( $Script:localLibFolder )"

        # TODO save an indikator or bool flag, if it already has been installed
        $Script:libFolderLoadedIndicator = $true

    }

    end {

    }
}
