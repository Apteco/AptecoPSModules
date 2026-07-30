BeforeAll {
    Import-Module "$PSScriptRoot/../ConvertStrings" -Force
}

Describe "Convert-XMLtoPSObject" {

    It "Converts a simple element into a NoteProperty" {
        [xml]$xml = "<Root><Name>Test</Name></Root>"
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.Name | Should -Be "Test"
    }

    It "Converts an attribute into a NoteProperty prefixed with the default '@'" {
        [xml]$xml = "<Root id='123'><Name>Test</Name></Root>"
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.'@id' | Should -Be "123"
    }

    It "Respects a custom -AttributesPrefix" {
        [xml]$xml = "<Root id='123'></Root>"
        $obj = $xml | Convert-XMLtoPSObject -AttributesPrefix "attr_"
        $obj.Root.'attr_id' | Should -Be "123"
    }

    It "Excludes namespace/schema noise attributes (xsd, xsi, space, xmlns, nil)" {
        [xml]$xml = '<Root xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xml:space="preserve"><Name>Test</Name></Root>'
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.PSObject.Properties.Name | Where-Object { $_ -like "@*" } | Should -BeNullOrEmpty
    }

    It "Recurses into nested elements" {
        [xml]$xml = "<Root><Book><Title>Book 1</Title><Author>Author 1</Author></Book></Root>"
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.Book.Title  | Should -Be "Book 1"
        $obj.Root.Book.Author | Should -Be "Author 1"
    }

    It "Collects repeated scalar sibling tags into an array" {
        [xml]$xml = "<Root><Item>a</Item><Item>b</Item><Item>c</Item></Root>"
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.Item.Count | Should -Be 3
        $obj.Root.Item       | Should -Be @("a", "b", "c")
    }

    It "Collects repeated complex (nested) sibling tags into an array" {
        [xml]$xml = "<Root><Book id='1'><Title>Book 1</Title></Book><Book id='2'><Title>Book 2</Title></Book></Root>"
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.Book.Count      | Should -Be 2
        $obj.Root.Book[0].'@id'   | Should -Be "1"
        $obj.Root.Book[1].Title   | Should -Be "Book 2"
    }

    It "Adds a 'value' property alongside attributes when a tag has both text and attributes" {
        [xml]$xml = '<Root><Messages errors="0" info="1">All fine!</Messages></Root>'
        $obj = $xml | Convert-XMLtoPSObject
        $obj.Root.Messages.'@errors' | Should -Be "0"
        $obj.Root.Messages.'@info'   | Should -Be "1"
        $obj.Root.Messages.value     | Should -Be "All fine!"
    }

    It "Round-trips through ConvertTo-Json without throwing" {
        [xml]$xml = "<Root><Book id='1'><Title>Book 1</Title></Book><Book id='2'><Title>Book 2</Title></Book></Root>"
        { ( $xml | Convert-XMLtoPSObject ) | ConvertTo-Json -Depth 20 } | Should -Not -Throw
    }

}

Describe "Out-HashTableToXml" {

    It "Produces a root element with the given name" {
        $xml = Out-HashTableToXml -Root "Config" -InputObject @{}
        ([xml]$xml).DocumentElement.Name | Should -Be "Config"
    }

    It "Converts flat Hashtable keys into child elements with the correct text" {
        $xml = Out-HashTableToXml -Root "Config" -InputObject @{ Name = "Test" }
        ([xml]$xml).Config.Name | Should -Be "Test"
    }

    It "Converts a nested Hashtable into nested elements" {
        $xml = Out-HashTableToXml -Root "Config" -InputObject @{ Values = @{ A = 1; B = 2 } }
        $parsed = [xml]$xml
        $parsed.Config.Values.A | Should -Be "1"
        $parsed.Config.Values.B | Should -Be "2"
    }

    It "Converts an array value into repeated sibling elements" {
        $xml = Out-HashTableToXml -Root "Config" -InputObject @{ Item = @("a", "b", "c") }
        $parsed = [xml]$xml
        @($parsed.Config.Item).Count | Should -Be 3
        @($parsed.Config.Item)       | Should -Be @("a", "b", "c")
    }

    It "Works without -Namespaces (no null-reference error)" {
        { Out-HashTableToXml -Root "Config" -InputObject @{ X = 1 } } | Should -Not -Throw
    }

    It "Applies a namespace prefix to the root element when -Namespaces is specified" {
        $xml = Out-HashTableToXml -Root "ns:Config" -InputObject @{ X = 1 } -Namespaces @{ ns = "http://example.com/ns" }
        $parsed = [xml]$xml
        $parsed.DocumentElement.LocalName        | Should -Be "Config"
        $parsed.DocumentElement.NamespaceURI      | Should -Be "http://example.com/ns"
    }

    It "Writes the xml to file when -Path is specified" {
        $tmpFile = Join-Path ([System.IO.Path]::GetTempPath()) "pester_hashxml_$(Get-Random).xml"
        try {
            Out-HashTableToXml -Root "Config" -InputObject @{ Name = "Test" } -Path $tmpFile | Out-Null
            Test-Path $tmpFile | Should -Be $true
            ([xml](Get-Content $tmpFile -Raw)).Config.Name | Should -Be "Test"
        } finally {
            Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
        }
    }

    It "Round-trips through Convert-XMLtoPSObject" {
        $ht = @{ Name = "Test"; Values = @{ A = 1; B = 2 } }
        $xml = Out-HashTableToXml -Root "Config" -InputObject $ht
        $obj = ([xml]$xml) | Convert-XMLtoPSObject

        $obj.Config.Name     | Should -Be "Test"
        $obj.Config.Values.A | Should -Be "1"
        $obj.Config.Values.B | Should -Be "2"
    }

}
