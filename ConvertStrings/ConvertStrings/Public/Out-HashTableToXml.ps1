Function Out-HashTableToXml {

    <#
    .SYNOPSIS
        Converts a nested Hashtable into an xml string (and optionally writes it to a file).

    .DESCRIPTION
        Apteco PS Modules - Convert Hashtable to XML

        The reverse direction of Convert-XMLtoPSObject: turns a Hashtable (nested Hashtables/arrays allowed)
        into an xml document under a given root element. Supports namespaces on the root element.

        Originally from https://gallery.technet.microsoft.com/scriptcenter/Export-Hashtable-to-xml-in-122fda31/view/Discussions#content,
        with namespace support on the root node added on top.

    .PARAMETER Root
        Name of the xml root element, e.g. "Config" or "ns:Config" when using -Namespaces.

    .PARAMETER InputObject
        The Hashtable to convert. Nested Hashtables become nested elements, arrays repeat the element.

    .PARAMETER Path
        Optional file path to also save the resulting xml to.

    .PARAMETER Namespaces
        Optional Hashtable of prefix -> uri namespace declarations, e.g. @{ ns = "http://example.com/ns" }.

    .EXAMPLE
        @{ Name = "Test"; Values = @{ A = 1; B = 2 } } | Out-HashTableToXml -Root "Config"

    .EXAMPLE
        Out-HashTableToXml -Root "ns:Config" -InputObject $ht -Namespaces @{ ns = "http://example.com/ns" } -Path "config.xml"

    .INPUTS
        System.Collections.Hashtable

    .OUTPUTS
        String (the xml)

    .NOTES
        Author:  florian.von.bracht@apteco.de
        Rescued from a local-only script

    #>

    [CmdletBinding(SupportsShouldProcess=$false)]
    Param(
         [ValidateNotNullOrEmpty()]
         [Parameter(Mandatory=$true)][System.String]$Root
        ,[Parameter(ValueFromPipeline=$true, Position=0)][System.Collections.Hashtable]$InputObject
        ,[Parameter(Mandatory=$false)][ValidateScript({ Test-Path $_ -IsValid })][System.String]$Path = ""
        ,[Parameter(Mandatory=$false)][System.Collections.Hashtable]$Namespaces = @{}
    )

    Begin {

        $ScriptBlock = {
            Param($Elem, $ElemRoot)
            If ( $Elem.Value -is [Array] ) {
                $Elem.Value | ForEach-Object {
                    $p = [System.Collections.DictionaryEntry]@{ "Key" = $Elem.Key; "Value" = $_ }
                    $ScriptBlock.Invoke($p, $ElemRoot)
                }
            } ElseIf ( $Elem.Value -is [System.Collections.Hashtable] ) {
                $childNode = $ElemRoot.AppendChild($Doc.CreateNode([System.Xml.XmlNodeType]::Element, $Elem.Key, $Null))
                $Elem.Value.GetEnumerator() | ForEach-Object {
                    $ScriptBlock.Invoke( @($_, $childNode) )
                }
            } Else {
                $Element = $Doc.CreateElement($Elem.Key)
                $p = If ( $Elem.Value -is [Array] ) {
                    $Elem.Value -join ','
                } Else {
                    $Elem.Value | Out-String
                }
                If ( $p -match '\S' ) { $Element.InnerText = $p.Trim() }
                $ElemRoot.AppendChild($Element) | Out-Null
            }
        }

    }

    Process {

        # Create empty xml document
        $Doc = New-Object System.XML.XMLDocument

        # Register namespaces
        $nsm = New-Object System.Xml.XmlNamespaceManager($Doc.NameTable)
        $Namespaces.Keys | ForEach-Object {
            $prefix = $_
            $uri = $Namespaces[$prefix]
            $nsm.AddNamespace($prefix, $uri)
        }

        # Resolve the root element's namespace, if any
        If ( $Root -like "*:*" ) {
            $rootPrefix = ( $Root -split ":" )[0]
        }
        $namespace = If ( $Namespaces.Count -gt 0 ) { $nsm.LookupNamespace($rootPrefix) } Else { $null }

        # Create root node
        $rootNode = $Doc.CreateNode([System.Xml.XmlNodeType]::Element, $Root, $namespace)
        $Doc.AppendChild($rootNode) | Out-Null

        # Add xml declaration
        $XD = $Doc.CreateXmlDeclaration("1.0", "UTF-8", "yes")
        $Doc.InsertBefore($XD, $Doc.DocumentElement) | Out-Null

        # Add subnodes recursively
        $InputObject.GetEnumerator() | ForEach-Object {
            $ScriptBlock.Invoke( @($_, $Doc.DocumentElement) )
        }

        # Save to file, if a path was provided
        If ( $Path -ne "" ) {
            $Doc.Save($Path)
        }

        return $Doc.OuterXml

    }

}
