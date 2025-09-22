
# Apteco PS Modules - PowerShell String Conversion


This module contains multiple helpful string conversion functions like

- Set-Token
- Get-StringHash
- Convert-StringEncoding
- Get-RandomString



# Installation

You can just download the whole repository here and pick this script or your can use PSGallery through PowerShell commands directly.

## PSGallery

### Installation via Install-Module

For installation execute this for all users scope

```PowerShell
Find-Module -Repository "PSGallery" -Name "ConvertStrings" -IncludeDependencies | Install-Module -Verbose -Scope AllUsers
```

You can check the installed module with

```PowerShell
Get-InstalledModule ConvertStrings
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
Find-Module -Repository LocalRepo -Name ConvertStrings -IncludeDependencies | Install-Module -Scope CurrentUser -Verbose
```

That way you can exchange the `.nupkg` files and update them manually from time to time.

### Uninstall

If you don't want to use the script anymore, just remove it with 

```PowerShell
Uninstall-Module -Name ConvertStrings
```



## Github

Download the whole repository and to load the module, just execute

```PowerShell
Set-Location ConvertStrings
Import-Module .\ConvertStrings
```

# Examples

Here are more detailed examples

## Set Token

Doing this

```PowerShell
$string = "Hello, this is a #PLACEHOLDER1# great world to #VERB#"

$ht = [hashtable]@{
    "#PLACEHOLDER1#" = "really"
    "#VERB#" = "live"
}

Set-Token -InputString $string -Replacements $ht
```

Gives you the output

```
Hello, this is a really great world to live
```
So it replaces the in the string the keys with the values

## Get-StringHash

Gives you a hash of the input string. Tested with:

- MD5
- SHA1
- SHA256
- SHA384
- SHA512
- HMACSHA256
- HMACSHA384
- HMACSHA512

This is how you use it with MD5 and SHA

```PowerShell
# This results in 872e4e50ce9990d8b041330c47c9ddd11bec6b503ae9386a99da8584e9bb12c4
Get-StringHash -inputString "HelloWorld" -hashName "SHA256"
```

For HMACSHA you need an additional key

```PowerShell
# This results in b9e217df88dc1bc96c1e69e1b09a798d6efe0ef69cd3511e7f4becd319fe6036
Get-StringHash -inputString "HelloWorld" -hashName "HMACSHA256" -key "GoGoGo"
```

You can also use additional parameters for

- Salt
- Uppercase
- $KeyIsHex
- ReturnBytes


## Convert-StringEncoding

Converts a string between different encodings. This is useful e.g. if you have APIs, that deliver UTF8 data, but does not deliver the encoding information, so PowerShell (especially 5.1 and before) is interpreting it in the default encoding which is not always UTF8.

```PowerShell
Convert-StringEncoding -string "žluťoučký kůň úpěl ďábelské ódy" -inputEncoding "Windows-1252" -outputEncoding "utf-8"

Convert-StringEncoding -string "žluťoučký kůň úpěl ďábelské ódy" -inputEncoding ([Console]::OutputEncoding.HeaderName) -outputEncoding ([System.Text.Encoding]::UTF8.HeaderName)
```

Use one of these encodings header names for input and output: `[System.Text.Encoding]::GetEncodings()``
Especially for Pwsh7 make sure to use the HeaderName of the encoding like `Windows-1252` instead of `iso-8859-1`
        
You can see more information in the help of this function

       

## Get-RandomString

```PowerShell
# Output a random string with length of 24 characters
Get-RandomString -length 24

# Output a random string with length of 32 characters without special characters, numbers and lowercase
Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase

# Output a random string with length 32, consisting of a, b, c and *
Get-RandomString -length 32 -AllowedCharacters @("a","b","c","*")

# Same as before, but shows all parameters
Get-RandomString -length 32 -ExcludeSpecialChars -ExcludeNumbers -ExcludeLowerCase -ExcludeUpperCase -AllowedCharacters @("a","b","c","*")

# Output just two random strings
10,20 | Get-RandomString

# Output 10 random strings
1..10 | Get-RandomString

# Output 10 random string with length of 20 characters
1..10 | % { Get-RandomString -length 20 }

```
