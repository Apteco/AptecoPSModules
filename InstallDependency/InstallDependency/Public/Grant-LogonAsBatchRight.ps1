Function Grant-LogonAsBatchRight {

    <#
    .SYNOPSIS
        Grants a local or domain account the "Log on as a batch job" (SeBatchLogonRight) security policy right.
    .DESCRIPTION
        Needed when a scheduled task that runs one of the Apteco PS modules must run under a service account
        that is not an interactive user -- Windows Task Scheduler refuses to start such a task until the
        account has been granted this right. Must be run elevated (as Administrator). Windows only, no-op
        elsewhere.
    .PARAMETER UserName
        Account to grant the right to, as "domain\account" or just "account" for a local account.
    .EXAMPLE
        Grant-LogonAsBatchRight -UserName "svc-apteco"
    .EXAMPLE
        Grant-LogonAsBatchRight -UserName "CONTOSO\svc-apteco"
    .NOTES
        Adapted from https://github.com/zloeber/Powershell/blob/master/Supplemental/Add-UserToLoginAsBatch.ps1
        which itself credits http://www.morgantechspace.com/2014/03/Set-Logon-as-batch-job-rights-to-User-by-Powershell-CSharp-CMD.html
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [String]$UserName
    )

    Process {

        If ( $Script:os -ne "Windows" ) {
            Write-Verbose "Logon-as-batch-job rights are only relevant on Windows, skipping"
            return
        }

        $CSharpCode = @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class LsaWrapper
{
    [DllImport("advapi32.dll", PreserveSig = true)]
    private static extern UInt32 LsaOpenPolicy(
        ref LSA_UNICODE_STRING SystemName,
        ref LSA_OBJECT_ATTRIBUTES ObjectAttributes,
        Int32 DesiredAccess,
        out IntPtr PolicyHandle
        );

    [DllImport("advapi32.dll", SetLastError = true, PreserveSig = true)]
    private static extern long LsaAddAccountRights(
        IntPtr PolicyHandle,
        IntPtr AccountSid,
        LSA_UNICODE_STRING[] UserRights,
        long CountOfRights);

    [DllImport("advapi32")]
    public static extern void FreeSid(IntPtr pSid);

    [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true, PreserveSig = true)]
    private static extern bool LookupAccountName(
        string lpSystemName, string lpAccountName,
        IntPtr psid,
        ref int cbsid,
        StringBuilder domainName, ref int cbdomainLength, ref int use);

    [DllImport("advapi32.dll")]
    private static extern bool IsValidSid(IntPtr pSid);

    [DllImport("advapi32.dll")]
    private static extern long LsaClose(IntPtr ObjectHandle);

    [DllImport("kernel32.dll")]
    private static extern int GetLastError();

    [DllImport("advapi32.dll")]
    private static extern long LsaNtStatusToWinError(long status);

    private enum LSA_AccessPolicy : long
    {
        POLICY_VIEW_LOCAL_INFORMATION = 0x00000001L,
        POLICY_VIEW_AUDIT_INFORMATION = 0x00000002L,
        POLICY_GET_PRIVATE_INFORMATION = 0x00000004L,
        POLICY_TRUST_ADMIN = 0x00000008L,
        POLICY_CREATE_ACCOUNT = 0x00000010L,
        POLICY_CREATE_SECRET = 0x00000020L,
        POLICY_CREATE_PRIVILEGE = 0x00000040L,
        POLICY_SET_DEFAULT_QUOTA_LIMITS = 0x00000080L,
        POLICY_SET_AUDIT_REQUIREMENTS = 0x00000100L,
        POLICY_AUDIT_LOG_ADMIN = 0x00000200L,
        POLICY_SERVER_ADMIN = 0x00000400L,
        POLICY_LOOKUP_NAMES = 0x00000800L,
        POLICY_NOTIFICATION = 0x00001000L
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct LSA_OBJECT_ATTRIBUTES
    {
        public int Length;
        public IntPtr RootDirectory;
        public readonly LSA_UNICODE_STRING ObjectName;
        public UInt32 Attributes;
        public IntPtr SecurityDescriptor;
        public IntPtr SecurityQualityOfService;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct LSA_UNICODE_STRING
    {
        public UInt16 Length;
        public UInt16 MaximumLength;
        public IntPtr Buffer;
    }

    public long SetRight(String accountName, String privilegeName)
    {
        long winErrorCode = 0;

        IntPtr sid = IntPtr.Zero;
        int sidSize = 0;
        var domainName = new StringBuilder();
        int nameSize = 0;
        int accountType = 0;

        LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize, ref accountType);

        domainName = new StringBuilder(nameSize);
        sid = Marshal.AllocHGlobal(sidSize);

        bool result = LookupAccountName(String.Empty, accountName, sid, ref sidSize, domainName, ref nameSize,
                                        ref accountType);

        if (!result)
        {
            winErrorCode = GetLastError();
        }
        else
        {
            var systemName = new LSA_UNICODE_STRING();
            var access = (int) (
                                    LSA_AccessPolicy.POLICY_AUDIT_LOG_ADMIN |
                                    LSA_AccessPolicy.POLICY_CREATE_ACCOUNT |
                                    LSA_AccessPolicy.POLICY_CREATE_PRIVILEGE |
                                    LSA_AccessPolicy.POLICY_CREATE_SECRET |
                                    LSA_AccessPolicy.POLICY_GET_PRIVATE_INFORMATION |
                                    LSA_AccessPolicy.POLICY_LOOKUP_NAMES |
                                    LSA_AccessPolicy.POLICY_NOTIFICATION |
                                    LSA_AccessPolicy.POLICY_SERVER_ADMIN |
                                    LSA_AccessPolicy.POLICY_SET_AUDIT_REQUIREMENTS |
                                    LSA_AccessPolicy.POLICY_SET_DEFAULT_QUOTA_LIMITS |
                                    LSA_AccessPolicy.POLICY_TRUST_ADMIN |
                                    LSA_AccessPolicy.POLICY_VIEW_AUDIT_INFORMATION |
                                    LSA_AccessPolicy.POLICY_VIEW_LOCAL_INFORMATION
                                );
            IntPtr policyHandle = IntPtr.Zero;

            var ObjectAttributes = new LSA_OBJECT_ATTRIBUTES();
            ObjectAttributes.Length = 0;
            ObjectAttributes.RootDirectory = IntPtr.Zero;
            ObjectAttributes.Attributes = 0;
            ObjectAttributes.SecurityDescriptor = IntPtr.Zero;
            ObjectAttributes.SecurityQualityOfService = IntPtr.Zero;

            uint resultPolicy = LsaOpenPolicy(ref systemName, ref ObjectAttributes, access, out policyHandle);
            winErrorCode = LsaNtStatusToWinError(resultPolicy);

            if (winErrorCode == 0)
            {
                var userRights = new LSA_UNICODE_STRING[1];
                userRights[0] = new LSA_UNICODE_STRING();
                userRights[0].Buffer = Marshal.StringToHGlobalUni(privilegeName);
                userRights[0].Length = (UInt16) (privilegeName.Length*UnicodeEncoding.CharSize);
                userRights[0].MaximumLength = (UInt16) ((privilegeName.Length + 1)*UnicodeEncoding.CharSize);

                long res = LsaAddAccountRights(policyHandle, sid, userRights, 1);
                winErrorCode = LsaNtStatusToWinError(res);

                LsaClose(policyHandle);
            }
            FreeSid(sid);
        }

        return winErrorCode;
    }
}

public class AddUserToLoginAsBatch
{
    public static long GrantUserLogonAsBatchJob(string userName)
    {
        LsaWrapper lsaUtility = new LsaWrapper();
        return lsaUtility.SetRight(userName, "SeBatchLogonRight");
    }
}
'@

        if ( -not ( [System.Management.Automation.PSTypeName]'AddUserToLoginAsBatch' ).Type ) {
            try {
                Add-Type -ErrorAction Stop -Language:CSharpVersion3 -TypeDefinition $CSharpCode
            } catch {
                Write-Error "Failed to compile the LSA helper type: $( $_.Exception.Message )"
                return
            }
        }

        Write-Verbose "Granting 'Log on as a batch job' right to $UserName"
        $winErrorCode = [AddUserToLoginAsBatch]::GrantUserLogonAsBatchJob($UserName)

        If ( $winErrorCode -ne 0 ) {
            Write-Error "Failed to grant 'Log on as a batch job' right to $( $UserName ): Win32 error code $winErrorCode"
        } else {
            Write-Verbose "'Log on as a batch job' right granted successfully to $UserName"
        }

    }

}
