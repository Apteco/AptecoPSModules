function Get-SslCertificate {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Retrieves the SSL/TLS certificate presented by a given HTTPS url.

    .DESCRIPTION
        Apteco PS Modules - SSL certificate retrieval

        Captures the leaf certificate returned during the TLS handshake with a url, without
        relying on the connection actually being trusted (validation always succeeds, since the
        goal here is to inspect the certificate, not to enforce trust).

        Inspired by https://github.com/PowerShell/PowerShell/issues/7092

    .PARAMETER Url
        The https url to connect to

    .EXAMPLE
        Get-SslCertificate -Url "https://www.apteco.de"

    .EXAMPLE
        $cert = Get-SslCertificate "https://www.apteco.de"
        $cert | Format-List

    .INPUTS
        String

    .OUTPUTS
        System.Security.Cryptography.X509Certificates.X509Certificate2

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [Alias('FullName')]
        [String]$Url
    )

    process {

        $code = @'
            using System;
            using System.Collections.Generic;
            using System.Net.Http;
            using System.Net.Security;
            using System.Security.Cryptography.X509Certificates;

            namespace AptecoTestCertificate
            {
                public class Utility
                {
                    public static Func<HttpRequestMessage,X509Certificate2,X509Chain,SslPolicyErrors,Boolean> ValidationCallback =
                        (message, cert, chain, errors) => {
                            var newCert = new X509Certificate2(cert);
                            var newChain = new X509Chain();
                            newChain.Build(newCert);
                            CapturedCertificates.Add(new CapturedCertificate(){
                                Certificate = newCert,
                                CertificateChain = newChain,
                                PolicyErrors = errors,
                                URI = message.RequestUri
                            });
                            return true;
                        };
                    public static List<CapturedCertificate> CapturedCertificates = new List<CapturedCertificate>();
                }

                public class CapturedCertificate
                {
                    public X509Certificate2 Certificate { get; set; }
                    public X509Chain CertificateChain { get; set; }
                    public SslPolicyErrors PolicyErrors { get; set; }
                    public Uri URI { get; set; }
                }
            }
'@

        # Differentiate between PS Core and Desktop
        if ( $PSEdition -ne 'Core' ) {
            Add-Type -AssemblyName System.Net.Http
            if ( -not ( "AptecoTestCertificate.Utility" -as [Type] ) ) {
                Add-Type $code -ReferencedAssemblies System.Net.Http
            }
        } else {
            if ( -not ( "AptecoTestCertificate.Utility" -as [Type] ) ) {
                Add-Type $code
            }
        }

        $captured = [AptecoTestCertificate.Utility]::CapturedCertificates
        $countBefore = $captured.Count

        $handler = [System.Net.Http.HttpClientHandler]::new()
        $handler.ServerCertificateCustomValidationCallback = [AptecoTestCertificate.Utility]::ValidationCallback
        $client = [System.Net.Http.HttpClient]::new($handler)

        try {
            [void]$client.GetAsync($Url).Result
        } finally {
            $client.Dispose()
            $handler.Dispose()
        }

        if ( $captured.Count -le $countBefore ) {
            throw "Could not capture a certificate for '$( $Url )'. Is it reachable and does it use HTTPS?"
        }

        $certificate = $captured[-1].Certificate

        # CapturedCertificates is a static list for the lifetime of the PowerShell session -
        # trim it back down so repeated calls do not grow it unbounded
        $captured.RemoveRange( 0, $captured.Count )

        return $certificate

    }

}
