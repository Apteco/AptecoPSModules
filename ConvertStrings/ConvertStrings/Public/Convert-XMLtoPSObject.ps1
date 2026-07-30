Function Convert-XMLtoPSObject {

    <#
    .SYNOPSIS
        Converts an [xml] object into a nested PSCustomObject, so it can easily be turned into JSON.

    .DESCRIPTION
        Apteco PS Modules - Convert XML to PSCustomObject

        Recursively walks an xml tree and turns tags into NoteProperties and attributes into NoteProperties
        prefixed with -AttributesPrefix (default "@"). A tag name used multiple times at the same level is
        collected into an array.

        Inspired by the C# example from https://dev.to/adamkdean/xml-to-hashtable-59dg

        Example call:

        $xmlInputString = @"
        <?xml version="1.0" encoding="utf-8"?>
        <XmlSerialisationWrapper xmlns:xsd="http://www.w3.org/2001/XMLSchema"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xml:space="preserve">
            <CurrentDate>20201130</CurrentDate>
            <Location>Germany</Location>
            <Messages errors="0" warnings="0" info="1">All fine!</Messages>
            <Obj xsi:type="TablePersistentState">
                <Book id="123">
                    <Title>Book Nr 1</Title>
                    <Author>Author Nr 1</Author>
                    <Recommendations positive="10" neutral="5" negative="1"/>
                </Book>
                <Book id="456">
                    <Title>Book Nr 2</Title>
                    <Author>Author Nr 2</Author>
                    <Recommendations positive="0" neutral="5" negative="10"/>
                </Book>
            </Obj>
        </XmlSerialisationWrapper>
        "@

        $xmlObj = [xml]$xmlInputString
        $pscustom = $xmlObj | Convert-XMLtoPSObject
        $json = $pscustom | ConvertTo-Json -Depth 20

        # ... results in a json like this one
        {
            "xml": "version=\"1.0\" encoding=\"utf-8\"",
            "XmlSerialisationWrapper": {
                "CurrentDate": "20201130",
                "Location": "Germany",
                "Messages": {
                    "@errors": "0",
                    "@warnings": "0",
                    "@info": "1",
                    "value": "All fine!"
                },
                "Obj": {
                    "@type": "TablePersistentState",
                    "Book": [
                        {
                            "@id": "123",
                            "Title": "Book Nr 1",
                            "Author": "Author Nr 1",
                            "Recommendations": { "@positive": "10", "@neutral": "5", "@negative": "1" }
                        },
                        {
                            "@id": "456",
                            "Title": "Book Nr 2",
                            "Author": "Author Nr 2",
                            "Recommendations": { "@positive": "0", "@neutral": "5", "@negative": "10" }
                        }
                    ]
                }
            }
        }

    .PARAMETER XML
        The xml node to convert. Load it first as [xml]$xmlString, then pipe it in or pass -XML.

    .PARAMETER AttributesPrefix
        Prefix used for the NoteProperty created from an xml attribute. Default is "@".

    .EXAMPLE
        [xml]$xmlObj = Get-Content "file.xml"
        $xmlObj | Convert-XMLtoPSObject | ConvertTo-Json -Depth 20

    .EXAMPLE
        Convert-XMLtoPSObject -XML ([xml]"<root><a>1</a><a>2</a></root>")

    .INPUTS
        System.Xml.XmlNode

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:  florian.von.bracht@apteco.de
        Rescued from a 2020-11-30 local-only script

    #>

    [CmdletBinding()]
    Param (
         [Parameter(Mandatory=$true, ValueFromPipeline=$true)] $XML
        ,[Parameter(Mandatory=$false)][String]$AttributesPrefix = "@"
    )

    Begin {

        # xml attributes that are always excluded (namespace/schema noise, not real data)
        $excludeAttributes = @("xsd", "xsi", "space", "xmlns", "nil")

    }

    Process {

        $return = New-Object -TypeName PSCustomObject

        # Handle attributes of the xml tag itself
        If ( $XML.Attributes.Count -gt 0 ) {
            $XML.Attributes | ForEach-Object {
                $a = $_
                $attName = $a.LocalName
                $attValue = $a.'#text'
                If ( $attName -notin $excludeAttributes ) {
                    $return | Add-Member -MemberType NoteProperty -Name "$( $AttributesPrefix )$( $attName )" -Value $attValue
                }
            }
        }

        # Loop through all child nodes and save them to the object, or recurse into them
        $XML.ChildNodes | Where-Object { $_.NodeType -notin @([System.Xml.XmlNodeType]::SignificantWhitespace) } | ForEach-Object {

            $n = $_
            $name = $n.Get_name() # Using Get_name() rather than .Name, since an attribute literally named "name" would shadow .Name

            # Decide if we go recursively or use the current value
            If ( $n.HasChildNodes ) {
                If ( $n.ChildNodes.Count -gt 1 ) {
                    $value = [PSCustomObject]( Convert-XMLtoPSObject -XML $n -AttributesPrefix $AttributesPrefix )
                } Else {
                    If ( $n.ChildNodes[0].NodeType -eq [System.Xml.XmlNodeType]::Text ) {
                        # Handle attributes on a tag that only has a single text child
                        If ( $n.Attributes.Count -gt 0 ) {
                            $value = New-Object -TypeName PSCustomObject
                            $n.Attributes | ForEach-Object {
                                $a = $_
                                $attName = $a.LocalName
                                $attValue = $a.'#text'
                                If ( $attName -notin $excludeAttributes ) {
                                    $value | Add-Member -MemberType NoteProperty -Name "$( $AttributesPrefix )$( $attName )" -Value $attValue
                                }
                            }
                            $v = $n.ChildNodes[0].Value
                            If ( $null -ne $v ) {
                                $value | Add-Member -MemberType NoteProperty -Name "value" -Value $v
                            }
                        } Else {
                            $value = $n.ChildNodes[0].Value
                        }
                    } Else {
                        $value = [PSCustomObject]( Convert-XMLtoPSObject -XML $n -AttributesPrefix $AttributesPrefix )
                    }
                }
            } Else {
                # Handle attributes on a childless tag
                If ( $n.Attributes.Count -gt 0 ) {
                    $value = New-Object -TypeName PSCustomObject
                    $n.Attributes | ForEach-Object {
                        $a = $_
                        $attName = $a.LocalName
                        $attValue = $a.'#text'
                        If ( $attName -notin $excludeAttributes ) {
                            $value | Add-Member -MemberType NoteProperty -Name "$( $AttributesPrefix )$( $attName )" -Value $attValue
                        }
                    }
                    $v = $n.ChildNodes[0].Value
                    If ( $null -ne $v ) {
                        $value | Add-Member -MemberType NoteProperty -Name "value" -Value $v
                    }
                } Else {
                    $value = $n.Value
                }
            }

            # A tag name can occur multiple times at the same level -- collect those into an array
            If ( ( $return | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -eq $name } ).Count -ge 1 ) {

                If ( $return.$name -is [System.Collections.ArrayList] ) {
                    # An array already exists, add to it
                    $list = $return.$name
                    $list.Add($value) | Out-Null # Out-Null is important here -- without it, .Add()'s return value leaks into the recursive function's output
                    $return.$name = $list
                } Else {
                    # A single value exists (scalar or PSCustomObject), turn it into an array
                    $list = [System.Collections.ArrayList]@()
                    $list.Add($return.$name) | Out-Null
                    $list.Add($value) | Out-Null
                    $return.$name = $list
                }

            } Else {
                $return | Add-Member -MemberType NoteProperty -Name $name -Value $value
            }

        }

        return $return

    }

}
