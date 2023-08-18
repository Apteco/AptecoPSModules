
# Apteco PS Modules - PowerShell merge Hashtable

This module merges two hashtables into one. It is able to handle nested structures like hashtables, arrays and PSCustomObjects. Please see the examples below.

```PowerShell
$left = [hashtable]@{
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

$right = [hashtable]@{
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

Merge-Hashtable -Left $left -right $right -AddKeysFromRight -MergeArrays -MergePSCustomObjects -MergeHashtables

```

will result to

```
Name                           Value
----                           -----
firstname                      Florian
lastname                       von Bracht
product                        @{name=Orbit; owner=Apteco Ltd.; sprint=106}
Street                         Schaumainkai 87
tags                           {company, nice, wow}
address                        {[Postcode, 60596], [Street, Schaumainkai 87]}
```

This module is dependent on MergePSCustomObject if you need to merge nested PSCustomObjects. So you either need to install `MergePSCustomObject` which installs the two modules or install this module and manually `Install-Module MergePSCustomObject`. This module will give you a hint automatically when it is missing something.

# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "MergeHashtable" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule MergeHashtable
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
Find-Module -Repository LocalRepo -Name MergeHashtable -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name MergeHashtable
```



## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location MergeHashtable
Import-Module .\MergeHashtable
```

# Examples

## Example 1

```PowerShell
$left = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
}

$right = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
}

Merge-Hashtable -Left $left -right $right
```

results to

```
Name                           Value
----                           -----
lastname                       von Bracht
firstname                      Florian
```

So it replaces all values on left with the ones from right

## Example 2

```PowerShell
$left = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
}

$right = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
}

Merge-Hashtable -Left $left -right $right -AddKeysFromRight
```

results to

```
Name                           Value
----                           -----
Street                         Schaumainkai 87
lastname                       von Bracht
firstname                      Florian
```

So it adds key from right to left that are not existing in left

## Example 3

```PowerShell
$left = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [hashtable]@{
        "Street" = "Schaumainkai 87"
    }
}

$right = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [hashtable]@{
        "Postcode" = 60596
    }
}

Merge-Hashtable -Left $left -right $right
```
        
results to 

```
Name                           Value
----                           -----
lastname                       von Bracht
address                        {[Postcode, 60596]}
firstname                      Florian
```

So it replaces the hashtable from left with the one from right. Using the `-MergeHashtables` flag will merge the child hashtables as well


## Example 4

```PowerShell
$left = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [hashtable]@{
        "Street" = "Schaumainkai 87"
    }
}

$right = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [hashtable]@{
        "Street" = "Kaiserstraße 35"
        "Postcode" = 60596
    }
}

Merge-Hashtable -Left $left -right $right -MergeHashtables
```

So it replaces the also nested hashtables from left with the one from right. Using the `-AddKeysFromRight` flag will add keys from right to left, also in nested hashtables


It results to
        
```
Name                           Value
----                           -----
lastname                       von Bracht
address                        {[Street, Kaiserstraße 35]}
firstname                      Florian
```


## Example 5

```PowerShell
$left = [hashtable]@{
    "firstname" = "Florian"
    "lastname" = "Friedrichs"
    "address" = [hashtable]@{
        "Street" = "Schaumainkai 87"
    }
}

$right = [hashtable]@{
    "lastname" = "von Bracht"
    "Street" = "Schaumainkai 87"
    "address" = [hashtable]@{
        "Street" = "Kaiserstraße 35"
        "Postcode" = 60596
    }
}

Merge-Hashtable -Left $left -right $right -MergeHashtables -AddKeysFromRight
```

will result to

```
Name                           Value
----                           -----
Street                         Schaumainkai 87
lastname                       von Bracht
address                        {[Postcode, 60596], [Street, Kaiserstraße 35]}
firstname                      Florian
```
