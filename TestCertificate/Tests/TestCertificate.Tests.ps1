#
# Pester 5 tests for TestCertificate
#
# These make real outbound HTTPS calls to a couple of well-known, stable endpoints, since the
# module's whole job is inspecting a certificate returned by a live TLS handshake.
#
# Run with:  Invoke-Pester -Path .\TestCertificate\Tests
#

BeforeAll {
    Import-Module "$( $PSScriptRoot )/../TestCertificate" -Force
}

AfterAll {
    Remove-Module -Name TestCertificate -Force -ErrorAction SilentlyContinue
}

Describe "Get-SslCertificate" {

    It "returns a certificate with a non-empty subject and thumbprint" {
        $cert = Get-SslCertificate -Url "https://www.google.com"
        $cert | Should -Not -BeNullOrEmpty
        $cert.Subject | Should -Not -BeNullOrEmpty
        $cert.Thumbprint | Should -Not -BeNullOrEmpty
    }

    It "accepts the url from the pipeline" {
        $cert = "https://www.google.com" | Get-SslCertificate
        $cert.Thumbprint | Should -Not -BeNullOrEmpty
    }

    It "does not error out on repeated calls" {
        { Get-SslCertificate -Url "https://www.google.com" } | Should -Not -Throw
        { Get-SslCertificate -Url "https://www.google.com" } | Should -Not -Throw
    }

    It "throws for an unreachable host" {
        { Get-SslCertificate -Url "https://this-host-should-not-resolve.invalid" } | Should -Throw
    }

}

Describe "Get-SHA256Thumbprint" {

    It "returns a colon-separated SHA-256 hex string" {
        $thumbprint = Get-SHA256Thumbprint -Url "https://www.google.com"
        $thumbprint | Should -Match '^([0-9A-F]{2}:){31}[0-9A-F]{2}$'
    }

    It "returns the same thumbprint as computed directly from Get-SslCertificate" {
        $cert = Get-SslCertificate -Url "https://www.google.com"
        $expected = [BitConverter]::ToString( [System.Security.Cryptography.SHA256]::Create().ComputeHash( $cert.GetRawCertData() ) ).Replace('-', ':')

        $thumbprint = Get-SHA256Thumbprint -Url "https://www.google.com"
        $thumbprint | Should -Be $expected
    }

}
