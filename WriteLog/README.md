
# Apteco PS Modules - PowerShell logging script

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

