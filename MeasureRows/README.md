
# Apteco PS Modules - PowerShell file rows count


Just use

```PowerShell
Measure-Row -Path "C:\Temp\Example.csv"
```

or

```PowerShell
"C:\Temp\Example.csv" | Measure-Row -SkipFirstRow
```

or

```PowerShell
Measure-Row -Path "C:\Temp\Example.csv" -Encoding UTF8
```

or even

```PowerShell
"C:\Users\Florian\Downloads\adressen.csv", "C:\Users\Florian\Downloads\italian.csv" | Measure-Row -SkipFirstRow -Encoding ([System.Text.Encoding]::UTF8)
```

to count the rows in a csv file. It uses a .NET streamreader and is extremly fast.

The default encoding is UTF8, but it uses the ones available in [System.Text.Encoding]

If you want to skip the first line, just use this Switch -SkipFirstRow

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "EncryptCredential" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule EncryptCredential
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
Find-Module -Repository LocalRepo -Name MeasureRows -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name MeasureRows
```

## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location MeasureRows
Import-Module .\MeasureRows
```

