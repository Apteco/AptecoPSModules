BeforeAll {
    Write-Host "Hello World 1"
    Import-Module "$PSScriptRoot/../SqlPipeline" -Force -Verbose
    # Create a test SQLite connection
    Write-Host "Hello World 2"
    Open-SQLiteConnection -DataSource "$PSScriptRoot/test.db" -Verbose
    Write-Host "Hello Worl3"

}

AfterAll {
    # Clean up test database and close connection
    Close-SqlConnection
    Remove-Item "$PSScriptRoot/test.db" -ErrorAction SilentlyContinue
    Remove-Module SqlPipeline -Force
    Remove-Module SimplySql -Force
}

Describe "Add-RowsToSql" {

    It "Inserts PSCustomObject rows into a new table" {
        $rows = @(
            [PSCustomObject]@{ Name = "Alice"; Age = 30 }
            [PSCustomObject]@{ Name = "Bob"; Age = 25 }
        )
        $result = $rows | Add-RowsToSql -TableName "People" -UseTransaction -Verbose
        $query = Invoke-SqlQuery -Query "SELECT * FROM People"
        $query.Name | Should -Contain "Alice"
        $query.Name | Should -Contain "Bob"
        $query.Age | Should -Contain 30
        $query.Age | Should -Contain 25
    }

    It "Inserts hashtable rows into a new table" {
        $rows = @(
            @{ City = "Berlin"; Country = "DE" }
            @{ City = "Paris"; Country = "FR" }
        )
        $result = $rows | Add-RowsToSql -TableName "Cities" -UseTransaction -Verbose
        $query = Invoke-SqlQuery -Query "SELECT * FROM Cities"
        $query.City | Should -Contain "Berlin"
        $query.City | Should -Contain "Paris"
        $query.Country | Should -Contain "DE"
        $query.Country | Should -Contain "FR"
    }

    It "Throws if connection is not valid" {
        { 
            [PSCustomObject]@{ Name = "Test" } | Add-RowsToSql -TableName "FailTable" -SQLConnectionName "notvalid"
        } | Should -Throw
    }

    It "Throws if input is not PSCustomObject or Hashtable and validation is not ignored" {
        {
            "string" | Add-RowsToSql -TableName "FailTable"
        } | Should -Throw
    }

    It "Allows non-object input when IgnoreInputValidation is set" {
        $result = "string" | Add-RowsToSql -TableName "StringTable" -IgnoreInputValidation
        $query = Invoke-SqlQuery -Query "SELECT * FROM StringTable"
        $query | Should -Not -BeNullOrEmpty
    }

    It "Passes input object to next pipeline step when PassThru is set" {
        $input = [PSCustomObject]@{ Name = "Charlie"; Age = 40 }
        $output = $input | Add-RowsToSql -TableName "PassThruTable" -PassThru
        $output | Should -Be $input
    }

    It "Creates new columns in existing table when CreateColumnsInExistingTable is set" {
        $row1 = [PSCustomObject]@{ Col1 = "A" }
        $row2 = [PSCustomObject]@{ Col1 = "B"; Col2 = "Extra" }
        $row1 | Add-RowsToSql -TableName "ColTest" -UseTransaction
        $row2 | Add-RowsToSql -TableName "ColTest" -UseTransaction -CreateColumnsInExistingTable
        $query = Invoke-SqlQuery -Query "SELECT * FROM ColTest"
        $query.Col2 | Should -Contain "Extra"
    }

    It "Formats nested objects as JSON when FormatObjectAsJson is set" {
        $row = [PSCustomObject]@{
            Name = "JsonTest"
            Data = [PSCustomObject]@{ Key = "Value"; Num = 123 }
        }
        $row | Add-RowsToSql -TableName "JsonTable" -FormatObjectAsJson
        $query = Invoke-SqlQuery -Query "SELECT Data FROM JsonTable WHERE Name = 'JsonTest'"
        $query.Data | Should -Match '"Key":"Value"'
        $query.Data | Should -Match '"Num":123'
    }
}