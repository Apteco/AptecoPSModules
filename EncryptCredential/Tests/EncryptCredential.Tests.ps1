#
# Pester 5 tests for EncryptCredential
#
# The tests never touch the real default keyfile in LocalAppData. A fresh random
# keyfile in a temp directory is generated and loaded via Import-Keyfile instead.
#
# Run with:  Invoke-Pester -Path .\EncryptCredential\Tests
#

BeforeAll {

    Import-Module "$( $PSScriptRoot )/../EncryptCredential" -Force

    $script:onWindows = ( $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows )

    # Isolated temp workspace with its own keyfile
    $script:testDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "EncryptCredentialTests_$( [Guid]::NewGuid().ToString('N') )"
    New-Item -Path $script:testDir -ItemType Directory | Out-Null

    $script:testKeyPath = Join-Path -Path $script:testDir -ChildPath "key.aes"
    $script:testKeyBytes = [byte[]]::new(32)
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($script:testKeyBytes)
    $rng.Dispose()
    [System.IO.File]::WriteAllBytes($script:testKeyPath, $script:testKeyBytes)

    Import-Keyfile -Path $script:testKeyPath

    # Helper: create a legacy (pre-0.4.0) ciphertext exactly like the old module did
    $script:NewLegacyCiphertext = {
        param( [String]$Plaintext, [byte[]]$KeyBytes )
        $secure = ConvertTo-SecureString -String $Plaintext -AsPlainText -Force
        ConvertFrom-SecureString -SecureString $secure -Key $KeyBytes
    }

}

AfterAll {

    Remove-Module -Name EncryptCredential -Force -ErrorAction SilentlyContinue
    If ( $null -ne $script:testDir -and ( Test-Path -Path $script:testDir ) ) {
        Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

}

Describe "Convert-PlaintextToSecure" {

    It "returns a non-empty string that does not contain the plaintext" {
        $enc = Convert-PlaintextToSecure -String "MySecretPassword123!"
        $enc | Should -Not -BeNullOrEmpty
        $enc | Should -Not -Match "MySecretPassword123!"
    }

    It "uses the machine-bound format by default" {
        $enc = Convert-PlaintextToSecure -String "hello"
        $enc | Should -BeLike "ApSec2|Machine|*"
    }

    It "uses the user-bound format with -Scope User" {
        $enc = Convert-PlaintextToSecure -String "hello" -Scope User
        $enc | Should -BeLike "ApSec2|User|*"
    }

    It "produces the legacy single-layer format with -Scope Portable" {
        $enc = Convert-PlaintextToSecure -String "hello" -Scope Portable
        $enc | Should -Not -BeLike "ApSec2|*"
        # legacy key-based SecureString export has a fixed header
        $enc | Should -BeLike "76492d1116743f0423413b16050a5345*"
    }

    It "accepts pipeline input" {
        $enc = "PipedSecret" | Convert-PlaintextToSecure
        $enc | Should -BeLike "ApSec2|*"
    }

    It "produces a different ciphertext on every call (random IV)" {
        $enc1 = Convert-PlaintextToSecure -String "same input"
        $enc2 = Convert-PlaintextToSecure -String "same input"
        $enc1 | Should -Not -Be $enc2
    }

}

Describe "Convert-SecureToPlaintext" {

    It "roundtrips with the default machine scope" {
        "RoundTrip!" | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be "RoundTrip!"
    }

    It "roundtrips with -Scope User" {
        Convert-PlaintextToSecure -String "UserBound!" -Scope User | Convert-SecureToPlaintext | Should -Be "UserBound!"
    }

    It "roundtrips with -Scope Portable" {
        Convert-PlaintextToSecure -String "Portable!" -Scope Portable | Convert-SecureToPlaintext | Should -Be "Portable!"
    }

    It "roundtrips special characters and umlauts" {
        $value = 'P@ss!"$%&/()=?`´ +#-.,;:_<>|^°ÄÖÜäöüß€'
        $value | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be $value
    }

    It "roundtrips a long string" {
        $value = "x" * 5000
        $value | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be $value
    }

    It "decrypts legacy strings from versions before 0.4.0 (downwards compatibility)" {
        $legacy = & $script:NewLegacyCiphertext "OldFormatSecret" $script:testKeyBytes
        $legacy | Convert-SecureToPlaintext | Should -Be "OldFormatSecret"
    }

    It "throws on a tampered machine-bound ciphertext" {
        $enc = Convert-PlaintextToSecure -String "TamperMe"
        # flip a byte at the end of the payload (encrypted data on Windows, MAC on Linux)
        $parts = $enc -split '\|', 3
        $bytes = [Convert]::FromBase64String($parts[2])
        $bytes[$bytes.Length - 1] = $bytes[$bytes.Length - 1] -bxor 0xFF
        $tampered = "$( $parts[0] )|$( $parts[1] )|$( [Convert]::ToBase64String($bytes) )"
        { $tampered | Convert-SecureToPlaintext } | Should -Throw
    }

    It "throws on garbage input" {
        { "this is not encrypted at all" | Convert-SecureToPlaintext } | Should -Throw
    }

    It "throws with a helpful message when the wrong keyfile is loaded" {
        $enc = Convert-PlaintextToSecure -String "KeyfileBound"
        # temporarily switch to a different keyfile
        $otherKeyPath = Join-Path -Path $script:testDir -ChildPath "other.aes"
        $otherKey = [byte[]]::new(32)
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($otherKey)
        $rng.Dispose()
        [System.IO.File]::WriteAllBytes($otherKeyPath, $otherKey)
        Try {
            Import-Keyfile -Path $otherKeyPath
            { $enc | Convert-SecureToPlaintext } | Should -Throw
        } Finally {
            Import-Keyfile -Path $script:testKeyPath
        }
    }

}

Describe "Keyfile handling" {

    It "still supports the legacy text keyfile format (decimal byte per line)" {
        $legacyKeyPath = Join-Path -Path $script:testDir -ChildPath "legacy.aes"
        $legacyKeyBytes = [byte[]]::new(32)
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($legacyKeyBytes)
        $rng.Dispose()
        # old module wrote the key as UTF8 text, one decimal number per line
        Set-Content -Path $legacyKeyPath -Value ( $legacyKeyBytes -join [Environment]::NewLine ) -Encoding UTF8
        Try {
            Import-Keyfile -Path $legacyKeyPath
            "LegacyKeyfile" | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be "LegacyKeyfile"
        } Finally {
            Import-Keyfile -Path $script:testKeyPath
        }
    }

    It "Import-Keyfile fails for a nonexistent path" {
        { Import-Keyfile -Path ( Join-Path -Path $script:testDir -ChildPath "does-not-exist.aes" ) -ErrorAction Stop } | Should -Throw
    }

    It "Import-Keyfile rejects a file that is not a valid key" {
        $invalidPath = Join-Path -Path $script:testDir -ChildPath "invalid.key"
        Set-Content -Path $invalidPath -Value "this is definitely not a keyfile" -Encoding UTF8
        { Import-Keyfile -Path $invalidPath -ErrorAction Stop } | Should -Throw
        # and the previously loaded keyfile must still work
        "StillWorks" | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be "StillWorks"
    }

    It "auto-creates a keyfile with 32 random bytes on first encryption" {
        $autoKeyPath = Join-Path -Path $script:testDir -ChildPath "autocreated.aes"
        Try {
            # point the module at a not-yet-existing keyfile
            InModuleScope EncryptCredential -Parameters @{ Path = $autoKeyPath } {
                $Script:keyfile = $Path
            }
            $enc = Convert-PlaintextToSecure -String "AutoCreate"
            Test-Path -Path $autoKeyPath | Should -BeTrue
            ( [System.IO.File]::ReadAllBytes($autoKeyPath) ).Length | Should -Be 32
            $enc | Convert-SecureToPlaintext | Should -Be "AutoCreate"
        } Finally {
            Import-Keyfile -Path $script:testKeyPath
        }
    }

    It "restricts an auto-created keyfile to the current user" -Skip:( -not ( $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows ) ) {
        $autoKeyPath = Join-Path -Path $script:testDir -ChildPath "autocreated.aes"
        $acl = Get-Acl -Path $autoKeyPath
        $acl.AreAccessRulesProtected | Should -BeTrue
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $acl.Access | Should -HaveCount 1
        $acl.Access[0].IdentityReference.Value | Should -Be $currentUser
    }

    It "New-Keyfile regenerates the key so old ciphertexts become invalid" {
        # work on a scratch copy so the shared test key survives
        $scratchKeyPath = Join-Path -Path $script:testDir -ChildPath "scratch.aes"
        Copy-Item -Path $script:testKeyPath -Destination $scratchKeyPath -Force
        Try {
            Import-Keyfile -Path $scratchKeyPath
            $enc = Convert-PlaintextToSecure -String "BeforeRotation"
            New-Keyfile -Confirm:$false | Out-Null
            { $enc | Convert-SecureToPlaintext } | Should -Throw
            # new encryptions work with the rotated key
            "AfterRotation" | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be "AfterRotation"
        } Finally {
            Import-Keyfile -Path $script:testKeyPath
        }
    }

}

Describe "Export-Keyfile" {

    It "copies the keyfile to a new path and uses it from there" {
        $exportPath = Join-Path -Path $script:testDir -ChildPath "exported.aes"
        Try {
            $item = Export-Keyfile -Path $exportPath
            $item.FullName | Should -Be ( Get-Item -Path $exportPath ).FullName
            [System.IO.File]::ReadAllBytes($exportPath) | Should -Be ( [System.IO.File]::ReadAllBytes($script:testKeyPath) )
            # ciphertexts created before the export must still decrypt
            "ExportedKey" | Convert-PlaintextToSecure | Convert-SecureToPlaintext | Should -Be "ExportedKey"
        } Finally {
            Import-Keyfile -Path $script:testKeyPath
        }
    }

    It "restricts the exported copy to the current user" -Skip:( -not ( $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows ) ) {
        $exportPath = Join-Path -Path $script:testDir -ChildPath "exported.aes"
        $acl = Get-Acl -Path $exportPath
        $acl.AreAccessRulesProtected | Should -BeTrue
        $acl.Access | Should -HaveCount 1
        $acl.Access[0].IdentityReference.Value | Should -Be ( [System.Security.Principal.WindowsIdentity]::GetCurrent().Name )
    }

    It "refuses to overwrite an existing file without -Force" {
        $exportPath = Join-Path -Path $script:testDir -ChildPath "exported.aes"
        { Export-Keyfile -Path $exportPath -ErrorAction Stop } | Should -Throw
    }

    It "overwrites an existing file with -Force" {
        $exportPath = Join-Path -Path $script:testDir -ChildPath "exported.aes"
        Try {
            $item = Export-Keyfile -Path $exportPath -Force
            $item | Should -Not -BeNullOrEmpty
        } Finally {
            Import-Keyfile -Path $script:testKeyPath
        }
    }

}

Describe "Migration from pre-0.4.0" {

    # Walks the migration path documented in the README:
    # $newString = $oldString | Convert-SecureToPlaintext | Convert-PlaintextToSecure

    It "re-encrypts a legacy string into the machine-bound format with the documented one-liner" {
        $oldString = & $script:NewLegacyCiphertext "MigrateMe!" $script:testKeyBytes
        $newString = $oldString | Convert-SecureToPlaintext | Convert-PlaintextToSecure
        $newString | Should -BeLike "ApSec2|Machine|*"
        $newString | Convert-SecureToPlaintext | Should -Be "MigrateMe!"
    }

    It "migration works with the same keyfile - no key rotation required" {
        $oldString = & $script:NewLegacyCiphertext "KeepTheKey" $script:testKeyBytes
        $newString = $oldString | Convert-SecureToPlaintext | Convert-PlaintextToSecure
        # both formats stay decryptable side by side with the unchanged keyfile
        $oldString | Convert-SecureToPlaintext | Should -Be "KeepTheKey"
        $newString | Convert-SecureToPlaintext | Should -Be "KeepTheKey"
    }

    It "a migrated string gains machine binding (keyfile alone is no longer enough)" {
        $oldString = & $script:NewLegacyCiphertext "NowBound" $script:testKeyBytes
        # the legacy string is decryptable with the stolen keyfile alone...
        { ConvertTo-SecureString -String $oldString -Key $script:testKeyBytes -ErrorAction Stop } | Should -Not -Throw
        # ...but after migration it is not
        $newString = $oldString | Convert-SecureToPlaintext | Convert-PlaintextToSecure
        { ConvertTo-SecureString -String $newString -Key $script:testKeyBytes -ErrorAction Stop } | Should -Throw
    }

    It "legacy and migrated strings are distinguishable by the documented prefixes" {
        $oldString = & $script:NewLegacyCiphertext "PrefixCheck" $script:testKeyBytes
        $newString = $oldString | Convert-SecureToPlaintext | Convert-PlaintextToSecure
        $oldString | Should -BeLike "76492d1116743f0423413b16050a5345*"
        $oldString | Should -Not -BeLike "ApSec2|*"
        $newString | Should -BeLike "ApSec2|*"
    }

}

Describe "Machine binding" {

    # A real cross-machine test is not possible here, but we can verify the layer
    # behaves as designed: the payload is not decryptable with the keyfile alone.

    It "machine-bound payload is not just the keyfile encryption in disguise" {
        $enc = Convert-PlaintextToSecure -String "TwoLayers"
        $payload = ( $enc -split '\|', 3 )[2]
        # trying to treat the outer payload directly as a key-based SecureString must fail
        { ConvertTo-SecureString -String $payload -Key $script:testKeyBytes -ErrorAction Stop } | Should -Throw
    }

    It "machine-bound ciphertext cannot be decrypted by ConvertTo-SecureString with the stolen keyfile" {
        $enc = Convert-PlaintextToSecure -String "StolenTogether"
        { ConvertTo-SecureString -String $enc -Key $script:testKeyBytes -ErrorAction Stop } | Should -Throw
    }

}
