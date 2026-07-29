Function Set-KeyfilePermission {

<#
    Restricts file access of a keyfile to the current user only.
    Windows: removes inherited ACEs and grants only the current user full control.
    Linux/macOS: chmod 600 (owner read/write only).
#>

    param(
        [Parameter(Mandatory=$true)][String]$Path
    )

    If ( $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows ) {

        # Build a fresh security descriptor containing only the DACL, so that owner/group
        # sections are not rewritten (Set-Acl would require SeSecurityPrivilege for that
        # in some situations, e.g. when overwriting an already protected file)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
            "FullControl",
            [System.Security.AccessControl.AccessControlType]::Allow
        )
        $fileSecurity = New-Object System.Security.AccessControl.FileSecurity
        $fileSecurity.SetAccessRuleProtection($true, $false)
        $fileSecurity.AddAccessRule($rule)

        $fileInfo = Get-Item -Path $Path
        If ( $PSVersionTable.PSEdition -eq 'Desktop' ) {
            $fileInfo.SetAccessControl($fileSecurity)
        } else {
            [System.IO.FileSystemAclExtensions]::SetAccessControl($fileInfo, $fileSecurity)
        }

    } else {

        & chmod 600 $Path

    }

}
