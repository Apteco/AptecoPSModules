
function Add-RowsToSql {
    [CmdletBinding()]

    <#
    .SYNOPSIS
        Wrapper for [SimplySql](https://github.com/mithrandyr/SimplySql/) to allow pipeline input and
        set the parameters automatically and it accepts also PSCustomObject input. It supports all the
        supported databases from SimplySql, but examples here are made with SQLite.

    .DESCRIPTION
        Apteco PS Modules - PowerShell SQL Pipeline

        Just open a database connection like

        Open-SQLiteConnection -DataSource ":memory:"

        and add rows from pipeline to the database

        get-childitem "*.*" | Add-RowsToSql -TableName "childitem" -UseTransaction -IgnoreInputValidation -verbose

        Then you can use a query like

        Invoke-SqlQuery -Query "SELECT * FROM childitem" | Out-GridView

    .PARAMETER InputObjects
        Can be PSCustomObject or Hashtable, this is the pipeline input parameter. But could also be used as a simple parameter

    .PARAMETER TableName
        Tablename to insert data into

    .PARAMETER SQLConnectionName
        Database connection to use for SimplySql. Default is "default". This needs to be used if you have multiple named database connections

    .PARAMETER CloseConnection
        Close connection after pipeline is finished. Otherwise you should close it with Close-SqlConnection

    .PARAMETER UseTransaction
        Using a transaction for your pipeline improves your performance about 30x times

    .PARAMETER CommitEvery
        When using a transaction, this parameter is used to commit the transaction every n records. Default is 10000

    .PARAMETER CreateColumnsInExistingTable
        If the table is already existing and your first object/row has more columns, they can be created with this flag
        Otherwise only existing columns will be used for a reference

    .PARAMETER FormatObjectAsJson
        If a column content is a PSCustomObject or Hashtable, it will automatically converted into JSON, when using this flag

    .PARAMETER IgnoreInputValidation
        Ignore validation on PSCustomObject or Hashtable to also allow input like processes or file items

    .PARAMETER DisableTrim
        Values will be trimmed automatically on input, you can turn this off with this flag

    .PARAMETER PassThru
        Using this flag passes the input object to the next pipeline step

    .PARAMETER Verbose
        Shows you the current status of INSERT AND COMMIT and a status at the end

    .EXAMPLE
        Open-SQLiteConnection -DataSource ":memory:"
        Import-csv -Encoding UTF8 -Path ".\Downloads\ac_adressen.csv" | Add-RowsToSql -TableName addresses -UseTransaction -verbose

    .EXAMPLE
        Get-ChildItem "*.*" | Add-RowsToSql -TableName "childitem" -UseTransaction -IgnoreInputValidation -verbose

    .EXAMPLE
        $psCustoms1 = @(
            [PSCustomObject]@{
                "firstname" = "Florian"
                "lastname" = "von Bracht"
                "score" = 10
                "object" = [PSCustomObject]@{

                }
            }
            [PSCustomObject]@{
                "firstname" = "Florian"
                #"lastname" = "von Bracht"
                "score" = 10
                "object" = [Hashtable]@{

                }
            }
        )
        $psCustoms2 = @(
            [PSCustomObject]@{
                "firstname" = "Bat"
                "lastname" = "Man"
                "score" = 11
                "object" = [PSCustomObject]@{
                    "street" = "Kaiserstrasse 35"
                    "city" = "Frankfurt"
                }
                "active" = "true" # test $true
            }
        )
        Import-Module SqlPipeline
        Open-SQLiteConnection -DataSource ":memory:"
        Add-RowsToSql -InputObject $psCustoms1 -TableName pscustoms -UseTransaction -FormatObjectAsJson -verbose
        $psCustoms2 | Add-RowsToSql -TableName pscustoms -UseTransaction -FormatObjectAsJson -verbose -CreateColumnsInExistingTable
        Invoke-SqlQuery -Query "Select * from pscustoms" | ft
        Close-SqlConnection

    .INPUTS
        Objects

    .OUTPUTS
        Objects

    .NOTES
        Author:  florian.von.bracht@apteco.de

    #>

    param (



         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         $InputObjects

        ,[Parameter(Mandatory=$false)]
         [Switch]$IgnoreInputValidation = $false           # Ignore validation on PSCustomObject or Hashtable to also allow
                                                                                        # input like processes or file items

        # Parameters for SimplySql
        ,[Parameter(Mandatory=$true)]
         [String]$TableName                                 # Tablename to insert data into
        
        ,[Parameter(Mandatory=$false)]
         [String]$SQLConnectionName = "default"            # Database connection to use
        
        ,[Parameter(Mandatory=$false)]
         [Switch]$CloseConnection = $false                 # Close connection after everything is finished
        
        ,[Parameter(Mandatory=$false)]
         [Switch]$UseTransaction = $false                  # Using a transaction improves your performance pretty much
        
        ,[Parameter(Mandatory=$false)]
         [Int]$CommitEvery = 10000                         # COMMIT every n rows

        # Column specific parameters
        ,[Parameter(Mandatory=$false)]
         [Switch]$CreateColumnsInExistingTable = $false    # Create new columns if there are new fields in the first row
        
        ,[Parameter(Mandatory=$false)]
         [Switch]$FormatObjectAsJson = $false              # If column contents are hashtable or pscustomobject, they could be formatted and loaded as JSON
        
        ,[Parameter(Mandatory=$false)]
         [Switch]$DisableTrim = $false                     # Values will be trimmed automatically on input, you can turn this off with this flag

        # Return/Pipeline parameters
        ,[Parameter(Mandatory=$false)][Switch]$PassThru = $false                        # Pass the input object to the next pipeline step

    )

    begin {

        #-----------------------------------------------
        # INITIALISE
        #-----------------------------------------------

        [int]$recordsInserted = 0
        $columns = $null
        $doUndo = $false
        $e = $null


        #-----------------------------------------------
        # CHECK THE CONNECTION
        #-----------------------------------------------

        $sqlTest = Test-SqlConnection -ConnectionName $SQLConnectionName

        If ( $sqlTest -eq $true ) {
            Write-Verbose "Connection test successful"
        } else {
            Write-Error "Connection test not successful"
            throw "Problem with SQL connection"
        }


        #-----------------------------------------------
        # START TRANSACTION, IF SET
        #-----------------------------------------------

        If ( $UseTransaction -eq $true ) {
            Start-SqlTransaction -ConnectionName $SQLConnectionName
        }


    }

    process {

        try {

            # Support for parameter input
            foreach ($InputObject in $InputObjects) {
            #for ( $x = 0; $x -lt $InputObjects.Count; $x++ ) {

                #$InputObject = $InputObjects[$x]

                #-----------------------------------------------
                # VALIDATE THE INPUT
                #-----------------------------------------------

                # Doing it here instead of parameters to set the undo
                # The validation can also be ignored to allow other objects as input
                If ( $IgnoreInputValidation -eq $false -and $InputObject.GetType().Name -notin @( "PSCustomObject", "Hashtable" ) ) {
                    throw "InputObject datatype could not be valitated"
                }


                #-----------------------------------------------
                # CHECK THE INPUT FOR TABLE AND COLUMNS
                #-----------------------------------------------

                If ( $recordsInserted -eq 0 ) {

                    # Load all columns
                    #$columns = $null
                    If ( $InputObject.GetType().Name -eq "Hashtable" ) { #-or $_ -is [Array]) {
                        $columns = [Array]@( $InputObject.Keys )
                    } ElseIf ( $InputObject.GetType().Name -eq "PSCustomObject" -or $IgnoreInputValidation -eq $true ) { # try to use it as a object, if validation is deactivated
                        $columns = [Array]@( $InputObject.PSObject.Properties.Name )
                    } else {
                        throw "No valid data input"
                    }

                    #write-verbose "$(( $InputObject | ConvertTo-Json -Depth 99 ))"
                    #write-verbose "$(( $columns -join "," ))"

                    $columnCreationText = [Array]@()
                    $columnParameterText = [Array]@()
                    For ($c = 0; $c -lt $columns.Count; $c++) {
                        $column = $columns[$c]
                        $columnCreationText += """$( $column )"" TEXT" # TODO Later this could automatically check the DATATYPES
                        $columnParameterText += "@f$( $c )" #"@$( $column )"
                    }

                    # Just try to find out if the table exists
                    # If it cannot be created, it automatically jumps into the catch part
                    # If it was able to create it, delete it directly for proper creation later
                    #
                    $isTableExisting = $false
                    $allTables = Invoke-SqlQuery -Query "SELECT * FROM sqlite_master WHERE type='table';"
                    If ( $null -ne $allTables ) {
                        If ( $allTables.name -contains $TableName ) {
                            $isTableExisting = $true
                        }
                    }

                    # Create table if it is not existing
                    If ( $isTableExisting -eq $false ) {
                        Write-Verbose "Create table ""$( $TableName )"""
                        $createQueryText = "CREATE TABLE IF NOT EXISTS ""$( $TableName )"" ( $(( $columnCreationText -join ', ' )) )"
                        #Write-Verbose $createQueryText
                        Invoke-SqlUpdate -Query $createQueryText -ConnectionName $SQLConnectionName | Out-Null
                    } else {

                        # Read the columns of the table
                        $tableColumnTable = Invoke-SqlQuery -Query "PRAGMA table_info(""$( $TableName )"");" -Stream -ConnectionName $SQLConnectionName
                        $tableColumns = @( $tableColumnTable.name )

                        # If the table is existing, create new columns, if parameter is set
                        If ( $CreateColumnsInExistingTable -eq $true -and $tableColumns.Count -gt 0 ) {

                            # Check the input colums against the existing table colums
                            For ($c = 0; $c -lt $columns.Count; $c++) {
                                $column = $columns[$c]
                                If ( $tableColumns -notcontains $column ) {
                                    Invoke-SqlUpdate -Query "ALTER TABLE ""$( $TableName )"" ADD ""$( $column )""" -ConnectionName $SQLConnectionName | Out-Null
                                }
                            }

                        }

                    }

                    # Create the insert query
                    $insertQuery = "INSERT INTO ""$( $TableName )"" (""$(( $columns -join '", "' ))"") VALUES ($(( $columnParameterText -join ', ' )))"
                    #Write-Verbose $insertQuery

                }


                #-----------------------------------------------
                # INSERT THE DATA
                #-----------------------------------------------

                $parameterObject = [Hashtable]@{}
                For ( $i = 0; $i -lt $columns.Count; $i++ ) {
                    $key = $columns[$i]

                    If ($FormatObjectAsJson -eq $true ) {
                        $rawValue = $InputObject.$key
                        If ( $null -ne $rawValue ) {
                            If ( $rawValue.GetType().Name -in @( "PSCustomObject", "Hashtable", "Object[]", "ArrayList" ) ) {
                                $parameterObject["@f$( $i )"] = ConvertTo-Json $rawValue -Depth 99 -Compress
                            } else {
                                If ($DisableTrim -eq $true -or $rawValue.GetType().Name -ne "String" ) {
                                    $parameterObject["@f$( $i )"] = $rawValue
                                } else {
                                    $parameterObject["@f$( $i )"] = $rawValue.trim()
                                }
                            }
                        } else {
                            $parameterObject["@f$( $i )"] = $null   # this is when some columns are missing in the processing
                        }

                    } else {
                        $parameterObject["@f$( $i )"] = $InputObject.$key
                    }
                }
                $recordsInserted += Invoke-SqlUpdate -Query $insertQuery -Parameters $parameterObject -ConnectionName $SQLConnectionName #| Out-Null


                #-----------------------------------------------
                # STATUS MESSAGE
                #-----------------------------------------------

                If ( $recordsInserted % 5000 -eq 0 ) {
                    Write-Verbose "Added $( $recordsInserted ) yet"
                }


                #-----------------------------------------------
                # DO COMMIT
                #-----------------------------------------------

                If ( $recordsInserted % $CommitEvery -eq 0 -and $UseTransaction -eq $true) {
                    Write-Verbose "COMMIT at $( $recordsInserted )"
                    Complete-SqlTransaction -ConnectionName $SQLConnectionName
                    Start-SqlTransaction -ConnectionName $SQLConnectionName
                }

            }

        } catch {

            Write-Warning "There is a problem at row $( $recordsInserted +1 ): $( $_.Exception.message )"
            $doUndo = $true
            $e = $_.Exception

            If ( $UseTransaction -eq $false ) {
                throw $e
            }


        }


        #-----------------------------------------------
        # RETURN
        #-----------------------------------------------

        # Return the input data
        If ( $PassThru -eq $true ) {
            $InputObject
        }

    }

    end {

        # Undo, if there is an error
        # Do last commit, if there is something to commit
        If ( $UseTransaction -eq $true ) {
            If ( $doUndo -eq $true) {
                Write-Warning "ROLLBACK/UNDO SQL Transaction"
                Undo-SqlTransaction -ConnectionName $SQLConnectionName
                $recordsInserted = 0
                throw $e
            } else {
                If ( $recordsInserted -gt 0) {
                    Complete-SqlTransaction -ConnectionName $SQLConnectionName
                }
            }
        }

        # Close Database connection
        If ( $CloseConnection -eq $true ) {
            Close-SqlConnection -ConnectionName $SQLConnectionName
        }

        Write-Verbose "Inserted $( $recordsInserted ) records"

    }
}