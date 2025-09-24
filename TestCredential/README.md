# TestCredential PowerShell Module

*This page is written by AI and proved by a human afterwards*

## Overview

**TestCredential** is a PowerShell module for interactively or programmatically verifying user credentials on Windows systems.  
It is intended for scenarios where you want to check if a username and password are valid for the current machine or domain.

> **Note:**  
> This module is **Windows-only**. It uses features not available on Linux or macOS.

## Features

- Interactive credential prompt (`Get-Credential`)
- Non-interactive mode for automation
- Pipeline support for credentials
- Multiple retry attempts for interactive mode

## Usage

### Interactive Mode

Prompts for credentials and checks them:

```powershell
Test-Credential
```

### Non-Interactive Mode

Pass a credential object (e.g., from `Get-Credential`):

```powershell
$cred = Get-Credential
Test-Credential -Credentials $cred -NonInteractive
```

Or via pipeline:

```powershell
Get-Credential | Test-Credential
```

### Example

```powershell
if (Test-Credential) {
    Write-Host "Credentials are valid."
} else {
    Write-Host "Invalid credentials."
}
```

## Limitations

- **Windows only:** Uses `Start-Job -Credential`, which is not supported on Linux/macOS.
- Does not test remote credentials or accounts not accessible to the local machine.

## Installation

Copy the `TestCredential` module folder to a directory in your `$env:PSModulePath`, or import directly:

```powershell
Import-Module 'Path\To\TestCredential'
```

## License

(c) 2025 Apteco GmbH. All rights reserved.

---