



function Invoke-Geocoding{

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][Hashtable] $InputHashtable
    )

    begin {


        #-----------------------------------------------
        # START TIMER
        #-----------------------------------------------

        $processStart = [datetime]::now
        #$inserts = 0


        #-----------------------------------------------
        # LOG
        #-----------------------------------------------

        $moduleName = "GEOCODE"

        # Start the log
        Write-Log -message $Script:logDivider
        Write-Log -message $moduleName -Severity INFO

        # Log the params, if existing
        Write-Log -message "INPUT:"
        if ( $InputHashtable ) {
            $InputHashtable.Keys | ForEach-Object {
                $param = $_
                Write-Log -message "    $( $param ) = '$( $InputHashtable[$param] )'" -writeToHostToo $false
            }
        }


        #-----------------------------------------------
        # DEBUG MODE
        #-----------------------------------------------

        Write-Log "Debug Mode: $( $Script:debug )"




        #-----------------------------------------------
        # DEFAULT VALUES
        #-----------------------------------------------



        #-----------------------------------------------
        # CHECK INPUT FILE
        #-----------------------------------------------

        # Checks input file automatically
        $file = Get-Item -Path $InputHashtable.Path
        Write-Log -Message "Got a file at $( $file.FullName )"

        # Count the rows
        # [ ] if this needs to much performance, this is not needed
        If ( $Script:settings.countRowsInputFile -eq $true ) {
            $rowsCount = Measure-Rows -Path $file.FullName -SkipFirstRow
            Write-Log -Message "Got a file with $( $rowsCount ) rows"
        } else {
            Write-Log -Message "RowCount of input file not activated"
        }
        #throw [System.IO.InvalidDataException] $msg

        #Write-Log -Message "Debug Mode: $( $Script:debugMode )"


        #-----------------------------------------------
        # CHECK CONNECTION
        #-----------------------------------------------

        # try {

        #     Test-CleverReachConnection

        # } catch {

        #     #$msg = "Failed to connect to CleverReach, unauthorized or token is expired"
        #     #Write-Log -Message $msg -Severity ERROR
        #     Write-Log -Message $_.Exception -Severity ERROR
        #     throw [System.IO.InvalidDataException] $msg
        #     exit 0

        # }

        #Write-Log -Message "Debug Mode: $( $Script:debugMode )"


    }

    process {


        try {

            ################################################
            #
            # PREPARE SQLITE DATABASE
            #
            ################################################


            #-----------------------------------------------
            # INITIATING A LOCAL DATABASE
            #-----------------------------------------------

            # Decide wether to use a local one or :memory:
            $tempDB = $script:settings.sqliteDB #"$( $Env:TEMP )/$( [Guid]::NewGuid().toString() ).sqlite" #New-TemporaryFile #":memory:" 

            # Create the connection
            #$connString = "Data Source=""$( $sqliteFile )"";Version=3;New=$( $new );Read Only=$( $readonly );$( $additionalParameters )"
            $additionalParameters = "Journal Mode=MEMORY;Cache Size=-4000;Page Size=4096;"
            $dbConnectionString = "Data Source=""$( $tempDB )"";$( $additionalParameters )"
            $dbConnection = [System.Data.SQLite.SQLiteConnection]::new($dbConnectionString)

            
            #-----------------------------------------------
            # OPEN THE DATABASE
            #-----------------------------------------------

            $retries = 10
            $retrycount = 0
            $secondsDelay = 2
            $completed = $false

            while (-not $completed) {
                try {
                    $dbConnection.open()
                    Write-Log -message "Connection succeeded."
                    $completed = $true
                } catch [System.Management.Automation.MethodInvocationException] {
                    if ($retrycount -ge $retries) {
                        Write-Log -message "Connection failed the maximum number of $( $retries ) times." -severity ([LogSeverity]::ERROR)
                        throw $_
                        exit 0
                    } else {
                        Write-Log -message "Connection failed $( $retrycount ) times. Retrying in $( $secondsDelay ) seconds." -severity ([LogSeverity]::WARNING)
                        Start-Sleep -Seconds $secondsDelay
                        $retrycount++
                    }
                }
            }

            
            #-----------------------------------------------
            # MORE DATABASE SETTINGS
            #-----------------------------------------------

            # Setting some pragmas for the connection
            $sqlitePragmaCommand = $dbConnection.CreateCommand()

            # With an unplanned event this can cause data loss, but in this case the database is not persistent, so good to go
            # Good explanation here: https://stackoverflow.com/questions/1711631/improve-insert-per-second-performance-of-sqlite
            $sqlitePragmaCommand.CommandText = "PRAGMA synchronous = OFF"
            [void]$sqlitePragmaCommand.ExecuteNonQuery()
            Write-Log -message "Setting the pragma '$( $sqlitePragmaCommand.CommandText )'"



            ################################################
            #
            # IMPORT FILE INTO SQLITE
            #
            ################################################


            #-----------------------------------------------
            # READ FILE
            #-----------------------------------------------

            # Reading first 200 rows for comparison, it is 201 to include the header
            $fileHead = Get-Content -Path $file.FullName -ReadCount 100 -TotalCount 201 -Encoding utf8
            $csv =  $fileHead | ConvertFrom-Csv  -Delimiter $Script:settings.delimiter
            $headers = $csv[0].psobject.properties.name
            Write-Log "Checking first $( $csv.count ) lines for comparison of columns"


            #-----------------------------------------------
            # CREATE TABLE AND COLUMNS
            #-----------------------------------------------

            # More preparation
            $tempTable = [guid]::NewGuid().toString()
            $sqliteCreateFields = [System.Collections.ArrayList]@()
            $sqliteInsertCommand = $dbConnection.CreateCommand()

            # Create database input parameters for CREATE AND INSERT statement
            $headers | ForEach {

                $header = $_

                $sqliteParameterObject = $sqliteInsertCommand.CreateParameter()
                $sqliteParameterObject.ParameterName = ":$( $header -replace '[^a-z0-9]', '' )"
                [void]$sqliteInsertCommand.Parameters.Add($sqliteParameterObject)
                #$sqliteParams.Add( $c, $sqliteParameterObject )

                [void]$sqliteCreateFields.Add( """$( $header )"" TEXT" )

            }

            # Create temporary table in database
            $sqliteCommand = $dbConnection.CreateCommand()
            $sqliteCommand.CommandText = @"
            CREATE TABLE IF NOT EXISTS "$( $tempTable )" (
                $( $sqliteCreateFields -join ",`n" )
            );
"@

            [void]$sqliteCommand.ExecuteNonQuery()


            #-----------------------------------------------
            # PREPARE INSERTION
            #-----------------------------------------------

            # Prepare the INSERT statement
            $sqliteInsertCommand.CommandText = "INSERT INTO ""$( $tempTable )"" (""$( $headers -join '" ,"' )"") VALUES ($( $sqliteInsertCommand.Parameters.ParameterName -join ', ' ))"

            # Initialize stream reader
            $reader = [System.IO.StreamReader]::new($file.FullName, [System.Text.Encoding]::UTF8)
            [void]$reader.ReadLine() # Skip first line.

            # Read data and put it into database as stream
            $sqliteTransaction = $dbConnection.BeginTransaction()
            $i = 0
            while ($reader.Peek() -ge 0) {
                $values = $reader.ReadLine().split($script:settings.delimiter)

                For ( $x = 0 ; $x -lt $values.Count ; $x++ ) {
                    $sqliteInsertCommand.Parameters[$x].Value = $values[$x]
                }
                [void]$sqliteInsertCommand.ExecuteNonQuery()
                $sqliteInsertCommand.Reset()

                $i+=1
                if ( $i % 50000 -eq 0 ) { # Commit every 50k records
                    $sqliteTransaction.Commit()
                    $sqliteTransaction = $dbConnection.BeginTransaction()
                }

            }
            $sqliteTransaction.Commit()
            $reader.Close()

            # Count the current amount of rows
            $rowCount = Invoke-SqliteData -connection $dbConnection -command "Select count(*) from ""$( $tempTable )"""
            Write-Host "Confirmed $( $rowCount[0] ) rows in sqlite"

            $addresses = [System.Collections.ArrayList]@()



            ################################################
            #
            # GEOCODE WITH OSM
            #
            ################################################

            #-----------------------------------------------
            # CREATE RESULTS TABLE AND COLUMNS
            #-----------------------------------------------

            # More preparation
            $tempTableResults = "$( $tempTable )_results"
            $sqliteCreateFields = [System.Collections.ArrayList]@()
            $sqliteInsertCommand = $dbConnection.CreateCommand()

            # Create database input parameters for CREATE AND INSERT statement
            $headers | ForEach {

                $header = $_

                $sqliteParameterObject = $sqliteInsertCommand.CreateParameter()
                $sqliteParameterObject.ParameterName = ":$( $header -replace '[^a-z0-9]', '' )"
                [void]$sqliteInsertCommand.Parameters.Add($sqliteParameterObject)
                #$sqliteParams.Add( $c, $sqliteParameterObject )

                [void]$sqliteCreateFields.Add( """$( $header )"" TEXT" )

            }

            # Create temporary table in database
            $sqliteCommand = $dbConnection.CreateCommand()
            $sqliteCommand.CommandText = @"
            CREATE TABLE IF NOT EXISTS "$( $tempTable )" (
                $( $sqliteCreateFields -join ",`n" )
            );
"@

            [void]$sqliteCommand.ExecuteNonQuery()



            #-----------------------------------------------
            # CREATE FIELD MAPPING
            #-----------------------------------------------

            Write-Log "This is the mapping of fields (left is source, right the openstreetmaps):" -Severity VERBOSE
            $paramMap = Convert-PSObjectToHashtable -InputObject $settings.map
            $reverseMap = [hashtable]@{}
            $paramMap.Keys | ForEach {
                $key = $_
                Write-Log "    $( $paramMap[$key] ) => $( $key )" -Severity VERBOSE        
                $reverseMap.Add($paramMap[$key], $key)
            }


            #-----------------------------------------------
            # LOOP THROUGH DATA
            #-----------------------------------------------

            $maxMillisecondsPerRequest = $settings.millisecondsPerRequest
            Write-Log "Will create 1 request per $( $maxMillisecondsPerRequest ) milliseconds" -Severity VERBOSE

            # calculate batches
            $totalCount = $rowCount[0]
            $batchSize = 50000  # TODO put into settings
            $batches = [math]::ceiling( $totalCount / $batchSize )

            # counter
            $counter = 0
            $succeeded = 0
            $failed = 0

            # go through batches
            For ( $i = 0 ; $i -lt $batches; $i++ ) {

                $limit = $batchSize
                $offset = $i * $batchSize
                $dataRows = Invoke-SqliteData -connection $dbConn -command "SELECT ""$( $headers -join '" ,"' )"" FROM ""$( $tempTable )"" LIMIT $( $limit ) OFFSET $( $offset )"
                $dataRows | ForEach-Object {

                    $counter += 1

                    $addr = $_
                    #$addr.ItemArray
                    
                    # Create address parameter string like streetSchaumainkai%2087&city=Frankfurt&postalcode=60589&countrycodes=de
                    $addrParams = [System.Collections.ArrayList]@()
                    $paramMap.Keys | ForEach {
                        $key = $_
                        $value = $addr[$paramMap[$key]]
                        [void]$addrParams.add("$( $key )=$( [uri]::EscapeDataString($value) )")
                    }

                    # Parameters for call
                    $restParams = @{
                        Uri = "$( $settings.base )/search?$( $addrParams -join "&" )&format=jsonv2&accept-language=$( $settings.resultsLanguage )&addressdetails=1&extratags=1"
                        Method = "Get"
                        UserAgent = $script:settings.useragent
                        Verbose = $false
                    }

                    # Request to OSM
                    $start = [datetime]::Now
                    $t = Measure-Command {
                        # TODO [ ] possibly implement proxy, if needed
                        # TODO add try catch here
                        $res = Invoke-RestMethod @restParams
                    }
                    $pl = ConvertTo-Json -InputObject $res -Depth 99 -Compress

                    
                    #$y += 1

                    If ( "" -eq $pl ) {

                        # Empty result -> do something with it?
                        $failed += 1
    
                        # Save data
                        $insertSqlReplacement = [Hashtable]@{
                            "#ID#"=$addr.Id
                            "#SUCCESS#"= 0
                            "#SRCHASH#"= "CAST('$( $data[0].AddressHash )' AS VARBINARY(MAX))" #$data[0].AddressHash
                            "#OSMHASH#"= @() #Get-StringHash $addressString -returnBytes -hashName "SHA256"
                            "#PAYLOAD#"= "{}" #ConvertTo-Json -InputObject $res -Depth 99 -Compress
                        }
                        $insertSql = Replace-Tokens -InputString $insertStatement -Replacements $insertSqlReplacement
                        #$customersSql | Set-Content ".\$( $rabatteSubfolder )\$( $evrGUID ).txt" -Encoding UTF8
    
                        # insert new address
                        $insertSqlResult = NonQueryScalar-SQLServer -connection $mssqlConnection -command "$( $insertSql )"
    
    
                    } else {
                        
                        # Got a result back
                        $succeeded += 1
    
                        # Create hash of address data
                        $address = $res.GetEnumerator().address
                        $addressString = "$( $address.road ) $( $address.house_number ), $( $address.postcode ) $( $address.city )" #, $( $address.country )"
                        $res | Add-Member -MemberType NoteProperty -Name "address_string" -Value $addressString
    
                        # Add address object to array
                        [void]$addresses.Add( $res )
    
                        # Save data
                        $insertSqlReplacement = [Hashtable]@{
                            "#ID#"=$addr.Id
                            "#SUCCESS#"= 1
                            #"#SRCHASH#"= "CAST('{$( $addr.AddressHash -join ", " )}' AS VARBINARY(MAX))"
                            #"#OSMHASH#"= "CAST('$( Get-StringHash $addressString -returnBytes -hashName "SHA256")' AS VARBINARY(MAX))" # Get-StringHash $addressString -returnBytes -hashName "SHA256"
                            "#PAYLOAD#"= "'$( $pl )'"
                        }
                        $insertSql = Replace-Tokens -InputString $insertStatement -Replacements $insertSqlReplacement
                        #$customersSql | Set-Content ".\$( $rabatteSubfolder )\$( $evrGUID ).txt" -Encoding UTF8
    
                        $mssqlCommand = $mssqlConnection.CreateCommand()
                        $mssqlCommand.CommandText = $insertSql
                        $mssqlCommand.CommandTimeout = $settings.commandTimeout
                        $mssqlCommand.Parameters.Add("@srcHash", [System.Data.SqlDbType]::VarBinary, 8000).Value = $addr.AddressHash
                        $mssqlCommand.Parameters.Add("@osmHash", [System.Data.SqlDbType]::VarBinary, 8000).Value = [Byte[]](Get-StringHash $addressString -returnBytes -hashName "SHA256")
                        $result = $mssqlCommand.ExecuteNonQuery()  #.ExecuteScalar()
                        
                        # insert new address
                        #$insertSqlResult = NonQueryScalar-SQLServer -connection $mssqlConnection -command "$( $insertSql )"
    
                    }

                    $end = [datetime]::Now

                    $ts = New-TimeSpan -Start $start -End $end

                    # Wait until 1 second is full, then proceed
                    If ( $ts.TotalMilliseconds -lt $maxMillisecondsPerRequest ) {
                        $waitLonger = [math]::ceiling( $maxMillisecondsPerRequest - $t.TotalMilliseconds )
                        "Waiting $( $waitLonger ) ms"
                        Start-Sleep -Milliseconds $waitLonger
                    }

                    If ( $counter % 1000 ) {
                        Write-Log -Message "Currently done $( $counter ) requests ($( $succeeded ) succeeded, $( $failed ) failed)" -Severity VERBOSE
                    }


                }
                #$writer.WriteLine($headerRowParsed)
            }

            #Invoke-RestMethod -Uri "https://nominatim.openstreetmap.org/search?street=Franz-Delheid-Stra%C3%9Fe%2054&city=Aachen&postalcode=52080&format=jsonv2&accept-language=de&countrycodes=de&addressdetails=1&extratags=1"

            Write-Log -Message "Finished! Done $( $counter ) requests ($( $succeeded ) succeeded, $( $failed ) failed)" -Severity INFO






            # Write-Log "Stats for upload"
            # Write-Log "  checked $( $i ) rows"
            # Write-Log "  $( $v ) valid rows"
            # Write-Log "  $( $j ) uploaded records"
            # Write-Log "  $( $k ) uploaded batches"




        } catch {

            $msg = "Error during uploading data. Abort!"
            Write-Log -Message $msg -Severity ERROR -WriteToHostToo $false
            Write-Log -Message $_.Exception -Severity ERROR
            throw $_.Exception

        } finally {


            # Close the file reader, if open
            # If the variable is not already declared, that shouldn't be a problem
            try {
                $reader.Close()
                $dbConnection.Close()
            } catch {

            }

            #-----------------------------------------------
            # STOP TIMER
            #-----------------------------------------------

            $processEnd = [datetime]::now
            $processDuration = New-TimeSpan -Start $processStart -End $processEnd
            Write-Log -Message "Needed $( [int]$processDuration.TotalSeconds ) seconds in total"

            # If ( $tags.length -gt 0 ) {
            #     Write-Log "Uploaded $( $j ) record. Confirmed $( $tagcount ) receivers with tag '$( $tags )'" -severity INFO
            # }

        }


        #-----------------------------------------------
        # RETURN VALUES 
        #-----------------------------------------------

        $true


    }

    end {

    }

}




