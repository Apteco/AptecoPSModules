

function Remove-TagsAtReceivers {

    [CmdletBinding()]
    param (
        #[Parameter(Mandatory=$false)][Hashtable] $InputHashtable
        [Parameter(Mandatory=$true)][String]$Source
        ,[Parameter(Mandatory=$true)][String]$Tag
    )

    begin {
        $uploadSize = $Script:settings.upload.uploadSize
    }

    process {

        #-----------------------------------------------
        # CHECK TAG
        #-----------------------------------------------

        Write-Log "Checking tag: $( $Source ).$( $Tag )"

        $receivers = @( Get-ReceiversWithTag -Source $Source -Tag $Tag )

        Write-Log "There are currently $( $receivers.count ) receivers for this tag"


        #-----------------------------------------------
        # REMOVE TAG IN BATCHES
        #-----------------------------------------------

        $uploads = [System.Collections.ArrayList]@()
        $receivers | Group-Object group_id | ForEach-Object {

            $groupId = $_.Name
            $groupCount = $_.Count

            Write-Log "Removing tag '$( $Source ).$( $Tag )' on group $( $groupId ) with count $( $groupCount )"

            # Calculate the batches
            $batches = 0
            $batches = [math]::Ceiling( $groupCount / $uploadSize )
            Write-Log "  Will do the changes in $( $batches ) batches"

            # Extract all receivers for group
            $groupReceivers = @( $receivers | Where-Object { $_.group_id -eq $groupId } )

            # Doing the removal in batches
            For ($i = 0 ; $i -lt $batches; $i += 1 ) {
                $start = $i * $uploadSize
                $end = $start + $uploadSize -1
                #$arr = [ArrayList]@()
                #$upsertBody = @( $groupReceivers[$start..$end] | Select email, @{ name="tags";expression={ [Array]@(,"-$( $Source ).$( $Tag )") }} )
                #Write-Verbose ( ConvertTo-Json $upsertBody ) -Verbose
                $upsertBody = @( $groupReceivers[$start..$end] | ForEach-Object { $rec =$_;[PSCustomObject]@{"email"=$rec.email;"tags"=[array]@("-$( $Source ).$( $Tag )")} } )
                $upload = @( Invoke-CR -Object "groups" -Path "/$( $groupId )/receivers/upsertplus" -Method POST -Verbose -Body $upsertBody )
                $uploads.addrange($upload)
            }

            # Log
            Write-Log "  Confirmed changes on $( $upload.count ) receivers for group $( $groupId )"

        }

        Write-Log "Confirmed changes on $( $uploads.count ) receivers"

        # return
        $uploads

    }

    end {

    }

}



