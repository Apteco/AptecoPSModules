# Introduction

Wrapper for [SimplySql](https://github.com/mithrandyr/SimplySql/) to allow pipeline input and set the parameters automatically and it accepts also PSCustomObject input. It supports all the supported databases from SimplySql, but examples here are made with SQLite.

# Performance

Please think about using the `-UseTransaction` flag. E.g. for a Sqlite import and a file of around 45k rows you can see the difference here. I have measured it like in this command:

```PowerShell
Import-Module SqlPipeline, SimplySql
Open-SQLiteConnection -DataSource ".\db.sqlite"
$t = Measure-Command {
    import-csv -Path '.ac_adressen.csv' -Encoding UTF8 -Delimiter "," | Add-RowsToSql -verbose -TableName "addresses" -UseTransaction
}
Close-SqlConnection
```

And you can see the difference, it is around 10x times faster to use a transaction when inserting data

Type|Time
-|-
Without transaction|596s
With transaction|20s

You can influence the number of records per transaction via the `-CommitEvery` parameter where the default is 10.000.

Btw. opening a temporary in-memory database like

```PowerShell
Open-SQLiteConnection -DataSource ":memory:"
```

made my import then in 18 seconds, which is still a nice improvement!

# Examples

## Close the connection after everything is done

With the `-CloseConnection` you can close the connection automatically after the import is done:

```PowerShell
import-csv -Path '.ac_adressen.csv' -Encoding UTF8 -Delimiter "," | Select-Object -first 100 | Add-RowsToSql -verbose -TableName "addresses" -UseTransaction -CloseConnection
```

So then `Test-SqlConnection` should be false

## Use the input data in further steps in pipeline

Use the `-PassThru` parameter switch to forward the input object to the next pipeline step, so this could be something like showing the first 100 records and output it in a table

```PowerShell
import-csv -Path '.ac_adressen.csv' -Encoding UTF8 -Delimiter "," | Select-Object -first 100 | Add-RowsToSql -TableName "addresses" -PassThru | Out-GridView
```

# Using in-memory database

This is also supported with SQLite, which can be done through SimplySql. So just open the database connection like

```PowerShell
Open-SQLiteConnection -DataSource ":memory:"
```


