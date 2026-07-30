# TestCertificate PowerShell Module

## Overview

**TestCertificate** retrieves the SSL/TLS certificate presented by a HTTPS url - without
needing that connection to be trusted first - so you can inspect it or pin its thumbprint,
e.g. before rolling out a certificate change.

## Usage

```powershell
Get-SslCertificate -Url "https://www.apteco.de"
```

```
Subject      : CN=www.apteco.co.uk, O=Apteco Limited, L=Warwick, C=GB
Issuer       : CN=DigiCert TLS RSA SHA256 2020 CA1, O=DigiCert Inc, C=US
Thumbprint   : D82B04907EA06A23E53A4053B3AB40F48CE6490A
NotBefore    : 26.01.2022 01:00:00
NotAfter     : 25.02.2023 00:59:59
```

```powershell
Get-SHA256Thumbprint -Url "https://www.apteco.de"
# 12:34:56:...
```

Both functions accept the url via the pipeline too:

```powershell
"https://www.apteco.de" | Get-SHA256Thumbprint
```

## Installation

```powershell
Install-Module TestCertificate
```

## License

(c) 2026 Apteco GmbH. All rights reserved.
