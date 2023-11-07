
function Add-RowsToSql {
    [CmdletBinding()]

    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][ValidateScript({
            If ($_ -is [Hashtable] ) { #-or $_ -is [Array]) {
                [Hashtable]$_
            } ElseIf ($_ -is [PSCustomObject]) {
                [PSCustomObject]$_
            }
        })]$InputObject
        
        # Parameters for SimplySql
        ,[Parameter(Mandatory=$true)][String]$TableName                                 # Tablename to insert data into
        ,[Parameter(Mandatory=$false)][String]$SQLConnectionName = "default"            # Database connection to use
        ,[Parameter(Mandatory=$false)][Switch]$CloseConnection = $false                 # Close connection after everything is finished
        ,[Parameter(Mandatory=$false)][Switch]$UseTransaction = $false                  # Using a transaction improves your performance pretty much
        ,[Parameter(Mandatory=$false)][Int]$CommitEvery = 10000                         # COMMIT every n rows

        # Column specific parameters
        ,[Parameter(Mandatory=$false)][Switch]$CreateColumnsInExistingTable = $false    # Create new columns if there are new fields in the first row
        ,[Parameter(Mandatory=$false)][Switch]$FormatObjectAsJson = $false              # If column contents are hashtable or pscustomobject, they could be formatted and loaded as JSON

        # Return/Pipeline parameters
        ,[Parameter(Mandatory=$false)][Switch]$PassThru = $false                        # Pass the input object to the next pipeline step

    )
    
    begin {

        #-----------------------------------------------
        # INITIALISE
        #-----------------------------------------------

        [int]$recordsInserted = 0
        $columns = $null


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
            Start-SqlTransaction
        }


    }
    
    process {

        #-----------------------------------------------
        # CHECK THE INPUT FOR TABLE AND COLUMNS
        #-----------------------------------------------

        If ( $recordsInserted -eq 0 ) {

            # Load all columns
            #$columns = $null
            If ( $InputObject -is [Hashtable] ) { #-or $_ -is [Array]) {
                $columns = $InputObject.Keys
            } ElseIf ( $InputObject -is [PSCustomObject]) {
                $columns = $InputObject.PSObject.Properties.Name
            }

            #write-verbose "$(( $InputObject | ConvertTo-Json -Depth 99 ))"
            #write-verbose "$(( $columns -join "," ))"
            
            $columnCreationText = [Array]@()
            $columnParameterText = [Array]@()
            For ($c = 0; $c -lt $columns.Count; $c++) {
                $column = $columns[$c]
                $columnCreationText += """$( $column )"" TEXT" # TODO Later this could automatically check the DATATYPES
                $columnParameterText += "@$( $column )"
            }

            # Just try to find out if the table exists
            $isTableExisting = $false
            try {
                Invoke-sqlQuery -Query "SELECT * FROM ""$( $TableName )"" LIMIT 1"
                $isTableExisting = $true
            } catch {
                Write-Verbose "Table $( $TableName ) not existing" 
            }

            # Create table if it is not existing
            If ( $isTableExisting -eq $false ) {
                $createQueryText = "CREATE TABLE IF NOT EXISTS ""$( $TableName )"" ( $(( $columnCreationText -join ', ' )) )"
                Write-Verbose $createQueryText
                Invoke-SqlUpdate -Query $createQueryText | Out-Null
            } else {

                # Read a record from that table and return as PSObject
                $firstRow = Invoke-SqlQuery -Query "SELECT * FROM ""$( $TableName )"" LIMIT 1" -Stream
                $firstRowColumns = $firstRow.PSObject.Properties.Name

                # If the table is existing, create new columns, if parameter is set
                If ( $CreateColumnsInExistingTable -eq $true ) {

                    # Check the input colums against the existing table colums
                    For ($c = 0; $c -lt $columns.Count; $c++) {
                        $column = $columns[$c]
                        If ( $firstRowColumns -notcontains $column ) {
                            Invoke-SqlUpdate -Query "ALTER TABLE ""$( $TableName )"" ADD ""$( $column )""" | Out-Null
                        }
                    }

                } else {

                    # Otherwise just use existing columns for insert query
                    $columns = $firstRowColumns
                    $columnParameterText = [Array]@()
                    For ($c = 0; $c -lt $columns.Count; $c++) {
                        $column = $columns[$c]
                        $columnParameterText += "@$( $column )"
                    }

                }

            }

            # Create the insert query
            $insertQuery = "INSERT INTO ""$( $TableName )"" (""$(( $columns -join '", "' ))"") VALUES ($(( $columnParameterText -join ', ' )))"
            Write-Verbose $insertQuery

        }


        #-----------------------------------------------
        # INSERT THE DATA
        #-----------------------------------------------

        If ($InputObject -is [Hashtable] ) { #-or $_ -is [Array]) {

            # If it is a hashtable, we are trying to stay "raw" without converting the data into new objects
            If ($FormatObjectAsJson -eq $true ) {
                # Reformat the hashtable input
                $parameterObject = [Hashtable]@{}
                $InputObject.Keys | ForEach-Object {
                    $key = $_
                    $rawValue = $InputObject.$key
                    If ( $rawValue -is [Hashtable] -or $rawValue -is [PSCustomObject] ) {
                        $parameterObject[$key] = ConvertTo-Json $rawValue -Depth 99 -Compress
                    } else {
                        $parameterObject[$key] = $rawValue
                    }   
                }
                $recordsInserted += Invoke-SqlUpdate -Query $insertQuery -Parameters $parameterObject #| Out-Null
            } else {
                # Just use the raw hashtable input
                $recordsInserted += Invoke-SqlUpdate -Query $insertQuery -Parameters $InputObject #| Out-Null
            }

        } ElseIf ($InputObject -is [PSCustomObject]) {

            $parameterObject = [Hashtable]@{}
            For ( $i = 0; $i -lt $columns.Count; $i++ ) {
                $key = $columns[$i]

                If ($FormatObjectAsJson -eq $true ) {
                    $rawValue = $InputObject.$key
                    If ( $rawValue -is [Hashtable] -or $rawValue -is [PSCustomObject] ) {
                        $parameterObject[$key] = ConvertTo-Json $rawValue -Depth 99 -Compress
                    } else {
                        $parameterObject[$key] = $rawValue
                    }
                } else {
                    $parameterObject[$key] = $InputObject.$key
                }
            }
            $recordsInserted += Invoke-SqlUpdate -Query $insertQuery -Parameters $parameterObject #| Out-Null

        }


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
            Complete-SqlTransaction
            Start-SqlTransaction
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

        # Do last commit, if there is something to commit

        If ( $recordsInserted -gt 0 -and $UseTransaction -eq $true) {
            Complete-SqlTransaction
        }

        # Close Database connection
        If ( $CloseConnection -eq $true ) {
            Close-SqlConnection
        }

        Write-Verbose "Inserted $( $recordsInserted ) records"
        
    }
}