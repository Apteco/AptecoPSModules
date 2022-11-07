# AptecoPSModules
Apteco PowerShell Modules


Name|Module|Script
-|-|-
[WriteLog](WriteLog/)|x
[SyncExtractOptions](SyncExtractOptions/)||x
[EncryptCredential](EncryptCredential/)|x|
[ConverUnixTimestamp](ConverUnixTimestamp/)|x
[MeasureRows](MeasureRows/)|x

## WriteLog

This script allows to write log files pretty easy without any fuzz. It retries the write commands if parallel processes want to write into the same logfile.

Execute commands like

```PowerShell
Write-Log -message "Hello World"
Write-Log -message "Hello World" -severity ([LogSeverity]::ERROR)
"Hello World" | Write-Log
```

Then the logfile getting written looks like

```
20220217134552	a6f3eda5-1b50-4841-861e-010174784e8c	INFO	This is a general information
20220217134617	a6f3eda5-1b50-4841-861e-010174784e8c	ERROR	Note! This is an error
20220217134618	a6f3eda5-1b50-4841-861e-010174784e8c	VERBOSE	This is the verbose/debug information
20220217134619	a6f3eda5-1b50-4841-861e-010174784e8c	WARNING	And please look at this warning

```

separated by tabs.

Click on the folder for more information.

## SyncExtractOptions

This script is used to switch off or switch on some data sources in FastStats Designer to allow a build with only a few tables (like customer data)
and then later do a bigger build with customer and transactional data.

This example just changes the behaviour of the extract options and saves it in the same xml

```PowerShell
SyncExtractOptions -DesignFile "C:\Apteco\Build\20220714\designs\20220714.xml" -Include "Bookings", "People"
```

## EncryptCredential

This module is used to double encrypt sensitive data like credentials, tokens etc. They cannot be stolen pretty easily as it uses SecureStrings.

Execute commands like

```PowerShell
"Hello World" | Convert-PlaintextToSecure
```

to get a string like

```
76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=
```

This string can be decrypted by calling

```PowerShell
"76492d1116743f0423413b16050a5345MgB8AEEAYQBmAEEAOABPAEEAYQBmAEYAKwBuAGQAegBxACsASQBRAGIAaQA0AEEAPQA9AHwANAAxAGEAYQBhADAAYwA3ADQAYwBiADkAYwAzADEAZgBkAGUAZQBkADQAOABhADIAMgA5AGUAMAAyADkANwBiADcAMQAyADgAOAAzADkAMwBiADAANAA0ADcAMwA3ADQANgAxADMAYwBmADQAZQAyADIAMwBkAGQAMQBhADUAMAA=" | Convert-SecureToPlaintext
```

and get back

```
Hello World
```

## ConverUnixTimestamp

Converts a `[DateTime]` into a numeric unix timestamp as `[UInt64]` and vice versa.

To get a unix timestamp from a `[DateTime]::Now` or `(Get-Date)` just do it like in these examples

```PowerShell
Get-Unixtime
Get-Unixtime -InMilliseconds
Get-Unixtime -InMilliseconds -Timestamp ( Get-Date ).AddDays(-2)
```

To convert a timestamp back, just do it like here

```PowerShell
ConvertFrom-UnixTime -Unixtime 1591775090
ConvertFrom-UnixTime -Unixtime 1591775090 -ConvertToLocalTimezone
ConvertFrom-UnixTime -Unixtime 1591775146091 -InMilliseconds
( ConvertFrom-UnixTime -Unixtime $lastSession.timestamp ).ToString("yyyy-MM-ddTHH:mm:ssK")
```

## MeasureRows

Just use

```PowerShell
Measure-Rows -Path "C:\Temp\Example.csv"
```

or

```PowerShell
"C:\Temp\Example.csv" | Measure-Rows -SkipFirstRow
```

or

```PowerShell
Measure-Rows -Path "C:\Temp\Example.csv" -Encoding UTF8
```

or even

```PowerShell
"C:\Users\Florian\Downloads\adressen.csv", "C:\Users\Florian\Downloads\italian.csv" | Measure-Rows -SkipFirstRow -Encoding ([System.Text.Encoding]::UTF8)
```

to count the rows in a csv file. It uses a .NET streamreader and is extremly fast.