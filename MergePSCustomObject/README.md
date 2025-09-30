
# Apteco PS Modules - PowerShell merge PSCustomObject

This module merges two PSCustomObjects into one. It is able to handle nested structures like hashtables, arrays and PSCustomObjects. Please see the examples below.

```PowerShell
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [hashtable]@{
        "Street" = "Kaiserstraße 35"
    }
    "tags" = [Array]@("nice","company")
    "product" = [PSCustomObject]@{
        "name" = "Orbit"
        "owner" = "Apteco Ltd."
    }
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [hashtable]@{
        "Street" = "Schaumainkai 87"
        "Postcode" = 60596
    }
    "tags" = [Array]@("wow")
    "product" = [PSCustomObject]@{
        "sprint" = 106
    }
}

Merge-PSCustomObject -Left $left -right $right -AddPropertiesFromRight -MergeArrays -MergePSCustomObjects -MergeHashtables

```

will result to

```
firstname : Florian
Street    : Schaumainkai 87
lastname  : von Bracht
address   : {[Postcode, 60596], [Street, Schaumainkai 87]}
tags      : {company, nice, wow}
product   : @{name=Orbit; owner=Apteco Ltd.; sprint=106}
```

This module is dependent on MergeHashtable so you only need to install either this one or the other.

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "MergePSCustomObject" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule MergePSCustomObject
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

Then put your downloaded `.nupkg` file into the new created `PSRepo` folder and you should see the module via 

```PowerShell
Find-Module -Repository LocalRepo
```

Then install the script like 

```PowerShell
Find-Module -Repository LocalRepo -Name "MergePSCustomObject" -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name MergePSCustomObject
```



## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location MergePSCustomObject
Import-Module .\MergePSCustomObject
```

# Examples

## Example 1

```PowerShell
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
}

Merge-PSCustomObject -Left $left -right $right
```

results to

```
firstname lastname
--------- --------
Florian   von Bracht
```

So it replaces all values on left with the ones from right

## Example 2

```PowerShell
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
}

Merge-PSCustomObject -Left $left -right $right -AddPropertiesFromRight
```

results to

```
firstname Street          lastname
--------- ------          --------
Florian   Schaumainkai 87 von Bracht
```

So it adds properties from right to left that are not existing in left

## Example 3

```PowerShell
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [PSCustomObject]@{
        "Street" = "Schaumainkai 87"
    }
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [PSCustomObject]@{
        "Postcode" = 60596
    }
}

Merge-PSCustomObject -Left $left -right $right
```
        
results to 

```
firstname lastname   address
--------- --------   -------
Florian   von Bracht @{Postcode=60596}
```

So it replaces the PSCustomObject from left with the one from right. Using the `-MergeHashtables` flag will merge the child PSCustomObject as well


## Example 4

```PowerShell
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [PSCustomObject]@{
        "Street" = "Schaumainkai 87"
    }
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [PSCustomObject]@{
        "Street" = "Kaiserstraße 35"
        "Postcode" = 60596
    }
}

Merge-PSCustomObject -Left $left -right $right -MergePSCustomObjects
```

So it replaces the also nested PSCustomObjects from left with the one from right. Using the `-AddPropertiesFromRight` flag will add properties from right to left, also in nested PSCustomObjects


It results to
        
```
firstname lastname   address
--------- --------   -------
Florian   von Bracht @{Street=Kaiserstraße 35}
```


## Example 5

```PowerShell
$left = [PSCustomObject]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [PSCustomObject]@{
        "Street" = "Schaumainkai 87"
    }
}

$right = [PSCustomObject]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [PSCustomObject]@{
        "Street" = "Kaiserstraße 35"
        "Postcode" = 60596
    }
}

Merge-PSCustomObject -Left $left -right $right -MergePSCustomObjects -AddPropertiesFromRight
```

will result to

```
firstname Street          lastname   address
--------- ------          --------   -------
Florian   Schaumainkai 87 von Bracht @{Postcode=60596; Street=Kaiserstraße 35}
```
