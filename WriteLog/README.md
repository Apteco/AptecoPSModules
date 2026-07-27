
# Apteco PS Modules - PowerShell logging script

Execute commands like

```PowerShell
Write-Log -message "Hello World"
Write-Log -message "Hello World" -severity ERROR
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


Make sure, after `Import-Module WriteLog` the module to call `Set-Logfile -Path .\file.log` and/or `Set-ProcessId -Id abc`. Otherwise the logfile and the processId will be created automatically and you are notified about the location and the current process id.

The process id is good for parallel calls/processes so you know they belong together.

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "WriteLog" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule WriteLog
```

If you want to find more [Apteco scripts in PSGallery](https://www.powershellgallery.com/packages?q=Tags%3A%22Apteco%22), please search with

```PowerShell
Find-Module -Repository "PSGallery" -Tag "Apteco"
```

### Installation via local Repository

If your machine does not have an online connection you can use another machine to save the script from PSGallery website as a local file via your browser. You should have download a file with an `.nupkg` extension. Please don't forget to download all dependencies, too. You could simply unzip the file(s) and put the script somewhere you need it OR do it in an updatable manner and create a local repository if you don't have it already with

```PowerShell
Set-Location "$( $env:USERPROFILE )\Downloads"
New-Item -Name "PSRepo" -ItemType Directory
Register-PSRepository -Name "LocalRepo" -SourceLocation "$( $env:USERPROFILE )\Downloads\PSRepo"
Get-PSRepository
```

On Linux you would use `Set-Location "$( $env:Home )/Downloads"` or create the `.\Downloads` directory.

To trust a local repository, use

```PowerShell
Set-PSRepository -Name LocalRepo  -InstallationPolicy Trusted
```

To remove the trust, just put it back to `Untrusted`

```PowerShell
Set-PSRepository -Name LocalRepo  -InstallationPolicy Untrusted
```

Then put your downloaded `.nupkg` file into the new created `PSRepo` folder and you should see the module via 

```PowerShell
Find-Module -Repository LocalRepo
```

Then install the script like 

```PowerShell
Find-Module -Repository LocalRepo -Name WriteLog -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name WriteLogfile
```



## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location WriteLog
Import-Module .\WriteLog
```

## Example 1

```PowerShell
Write-Log -message "Hello World"
```

Uses the internal `$logfile` and `$processId` variables and redirects the message to your console and creates a line in your logfile like

```
20220217134552	a6f3eda5-1b50-4841-861e-010174784e8c	INFO	Hello World
```

## Example 2

```PowerShell
Write-Log -message "Note! This is an error" -severity ([LogSeverity]::ERROR)
```

outputs red characters at the console and creates a line in your logfile like

```
20220217134617	a6f3eda5-1b50-4841-861e-010174784e8c	ERROR	Note! This is an error
```

## Example 3

```PowerShell
"Hello World" | Write-Log -WriteToHostToo $false
```

Works like the previous examples but also works with the pipeline and in this example do not output to the console

# Best Practise

Normally I use a settings at the beginning of the script to allow debugging without writing into a production log like:

```PowerShell

# debug switch
$debug = $true

Import-Module WriteLog
Set-Logfile -Path ".\script.log"

# append a suffix, if in debug mode
if ( $debug ) {
    Set-Logfile -Path "$( (Get-Logfile).FullName ).debug"
}

```

# Change of Formats

With version 0.10.0 WriteLog introduced the possibilty to use more variables to create the log. With `Set-TimestampFormat` you can override the default timestamp output format and with `Set-LogFormat` you can create a string like `"TIMESTAMP`tPROCESSID`tSEVERITY`tMESSAGE"` to add more information. Here you can see all possible variables:

Name|Explanation
-|-
TIMESTAMP|A timestamp value defaulted to yyyyMMddHHmmSS which can be changed by Set-TimestampFormat
PROCESSID|A guid for the current powershell logging process
SEVERITY|The severity, currently VERBOSE, INFO, WARNING or ERROR
MESSAGE|The logged message
64BITOS|Either 64BitOs or 32BitOs
64BITPROC|Either 64BitProcess or 32BitProcess
USER|Currently executing user of the powershell session
MACHINE|Machine name
PSVERSION|Currently used PSVersion like 5.1.0 or 7.6.4
ISELEVATED|Either Elevated or NotElevated
SYSTEMPROCESSID|Process id of this session in the OS
PROCRAM|RAM usage of current process
PROCCPU|CPU usage of current process

## Example

So with these simple commands you can set the timestamp format and the output columns

```PowerShell
Set-TimestampFormat -Format "yyyy-MM-dd HH:mm:ss.fff" -verbose
Set-LogFormat -Format "TIMESTAMP`tPROCESSID`tSEVERITY`t64BITOS`t64BITPROC`tUSER`tMACHINE`tPSVERSION`tISELEVATED`tSYSTEMPROCESSID`tPROCRAM`tPROCCPU`tMESSAGE"
```

# Additional log targets

With version 0.10.0 WriteLog introduced additional logfiles. So you can log the same message into multiple logfiles at the same time. Just add files with

```PowerShell
Add-AdditionalLogfile -Path "C:\Temp\test1.txt" -verbose
Add-AdditionalLogfile -Path "C:\Temp\test2.txt" -verbose
```

or show them with

```PowerShell
Get-AdditionalLog

Type     Name       Options
----     ----       -------
textfile Textfile_1 @{Path=C:\Temp\test.txt}
textfile Textfile_2 @{Path=C:\Temp\test2.txt}
```

or delete them with one of these options

```PowerShell
Remove-AdditionalLogfile -Name "Textfile_1"
Remove-AdditionalLogfile -Path "C:\Temp\test.txt"
```

## Logging into a database

With version 0.10.4 WriteLog introduced `Add-AdditionalDatabase`. Unlike `Add-AdditionalLogfile`, WriteLog has no built-in knowledge of any particular database - you supply a `-Writer` scriptblock that receives every log entry as a hashtable (`TIMESTAMP`, `PROCESSID`, `SEVERITY`, `MESSAGE`, `PROCRAM`, `PROCCPU`, ...) and is responsible for writing it wherever you like. This keeps WriteLog itself free of any database dependency - load whatever driver/module you need lazily inside the scriptblock.

Here is an example writing into a local SQLite database using [Microsoft.Data.Sqlite](https://www.nuget.org/packages/Microsoft.Data.Sqlite.Core) pulled in as a plain NuGet package via [InstallDependency](https://github.com/Apteco/AptecoPSModules/tree/main/InstallDependency)/[ImportDependency](https://github.com/Apteco/AptecoPSModules/tree/main/ImportDependency), instead of a wrapper module like PSSQLite. This is deliberate: PSSQLite (and any other `System.Data.SQLite`-based option) bundles native binaries only for win-x86/win-x64/linux-x64/osx-x64 - there is no ARM64 build, so it fails outright on native ARM64 pwsh (e.g. Copilot+ PCs). `Microsoft.Data.Sqlite`'s native layer (`SQLitePCLRaw.lib.e_sqlite3`) does ship `win-arm64`, and both editions below were verified end-to-end on real Windows PowerShell 5.1 and ARM64 pwsh:

```PowerShell
Import-Module WriteLog
Set-Logfile -Path ".\script.log"

# Lazily install/import InstallDependency and ImportDependency, then use them to fetch the SQLite
# packages as plain NuGet packages into a local lib folder
If ( -not ( Get-Module -Name "InstallDependency" -ListAvailable ) ) { Install-Module -Name "InstallDependency" -Scope CurrentUser -Force }
If ( -not ( Get-Module -Name "ImportDependency"  -ListAvailable ) ) { Install-Module -Name "ImportDependency"  -Scope CurrentUser -Force }
Import-Module -Name "InstallDependency"
Import-Module -Name "ImportDependency"

# Microsoft.Data.Sqlite.Core + the SQLitePCLRaw pieces (ADO.NET provider + its native SQLite
# binary), plus the BCL polyfills SQLitePCLRaw's netstandard2.0 build needs on Windows PowerShell
$sqlitePackages = @(
    "Microsoft.Data.Sqlite.Core"
    "SQLitePCLRaw.core"
    "SQLitePCLRaw.provider.e_sqlite3"
    "SQLitePCLRaw.lib.e_sqlite3"
    "SQLitePCLRaw.config.e_sqlite3"
    "System.Memory"
    "System.Buffers"
    "System.Numerics.Vectors"
    "System.Runtime.CompilerServices.Unsafe"
)

Install-Dependency -LocalPackage $sqlitePackages -LocalPackageFolder ".\lib"
Import-Dependency   -LocalPackage $sqlitePackages -LocalPackageFolder ".\lib"

# Windows PowerShell (.NET Framework) does not unify differing exact assembly versions the way
# pwsh does -- SQLitePCLRaw's provider and Microsoft.Data.Sqlite were each built against a
# slightly different exact System.Memory version, so redirect any request to whichever copy is
# already loaded. Not needed on pwsh, so only registered on Desktop.
If ( $PSVersionTable.PSEdition -eq "Desktop" ) {
    [AppDomain]::CurrentDomain.add_AssemblyResolve({
        param($resolveSender, $resolveArgs)
        $requestedName = ([Reflection.AssemblyName]$resolveArgs.Name).Name
        [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq $requestedName } | Select-Object -First 1
    })
}

[SQLitePCL.Batteries_V2]::Init()

$dbPath = ".\logs.sqlite"

# Create the table once, before registering the writer
$conn = New-Object Microsoft.Data.Sqlite.SqliteConnection("Data Source=$dbPath")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "CREATE TABLE IF NOT EXISTS logs (Timestamp TEXT, ProcessId TEXT, Severity TEXT, Message TEXT)"
[void]$cmd.ExecuteNonQuery()
$conn.Close()

Add-AdditionalDatabase -Name "SqliteLog" -Writer {
    param($LogEntry)
    $conn = New-Object Microsoft.Data.Sqlite.SqliteConnection("Data Source=$dbPath")
    $conn.Open()
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "INSERT INTO logs (Timestamp, ProcessId, Severity, Message) VALUES (@Timestamp, @ProcessId, @Severity, @Message)"
    [void]$cmd.Parameters.AddWithValue("@Timestamp", $LogEntry.TIMESTAMP)
    [void]$cmd.Parameters.AddWithValue("@ProcessId", $LogEntry.PROCESSID)
    [void]$cmd.Parameters.AddWithValue("@Severity", $LogEntry.SEVERITY)
    [void]$cmd.Parameters.AddWithValue("@Message", $LogEntry.MESSAGE)
    [void]$cmd.ExecuteNonQuery()
    $conn.Close()
}

Write-Log -Message "Hello SQLite" -Severity INFO
```

Every `Write-Log` call now also inserts a row into `logs.sqlite`. If the writer throws (e.g. the database is locked or unreachable), `Write-Log` catches it and emits a warning instead of failing the log call, so a broken database target never breaks the caller.

Remove it again the same way as a textfile target, by name:

```PowerShell
Remove-AdditionalLogfile -Name "SqliteLog"
```

# Resizing log files

Log files can grow large over time. Use `Resize-Logfile` to trim a log file down to its last n lines.

## Resize the main log file

```PowerShell
Resize-Logfile -RowsToKeep 200000
```

Rewrites `$Script:logfile` keeping only the last 200000 lines.

## Resize a specific log file

```PowerShell
Resize-Logfile -RowsToKeep 200000 -Path "C:\Logs\myapp.log"
```

The `-Path` parameter lets you target any log file directly, independent of `$Script:logfile`.

## Resize all registered log files at once

```PowerShell
Resize-Logfile -RowsToKeep 200000 -All
```

Resizes the main log file and all additional textfile log files registered via `Add-AdditionalLogfile` in one call.