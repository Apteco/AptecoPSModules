function Send-GroupNotification {

    [CmdletBinding()]
    param (

         [Parameter(Mandatory = $true)]
         [String]$Name        # Give the channel a name, this is the "identifier for this channel"

        ,[Parameter(Mandatory = $true)]
         [String]$Message     # Main message to send

        ,[Parameter(Mandatory = $false)]
         [String]$Subject    # Used for teams and email

    )

    process {

        $group = Get-NotificationGroups | Where-Object { $_.Name -eq $Name }

        # Check
        if ( $group.count -eq 0 ) {
            throw "Group $( $Name ) does not exist"
        } elseif ( $group.count -gt 1 ) {
            throw "More than 1 group $( $Name ) with this name"
        }

        $targets = Get-NotificationTargets | where-object { $_.MemberOf -contains $group.GroupId }

        # Send a message to each target
        # Every channel type is expected to expose a "Send-<Type>Notification" function.
        # Which of the candidate arguments below actually get passed is derived from that
        # function's own parameter list, so new channel types plug in here automatically.
        foreach ( $target in $targets ) {

            $commandName = "Send-$( $target.type )Notification"
            $command = Get-Command -Name $commandName -CommandType Function -ErrorAction SilentlyContinue

            If ( $null -eq $command ) {
                throw "No notification function found for channel type '$( $target.type )' (expected '$( $commandName )')"
            }

            $candidateArgs = [Ordered]@{
                "Name" = $target.Name
                "Target" = $target.targetname
                "Text" = $Message
                "Subject" = $Subject
                "Title" = $Subject
            }

            $callArgs = @{}
            foreach ( $key in $candidateArgs.Keys ) {
                If ( $command.Parameters.ContainsKey($key) -and [String]::IsNullOrEmpty($candidateArgs[$key]) -eq $false ) {
                    $callArgs[$key] = $candidateArgs[$key]
                }
            }

            & $commandName @callArgs

        }

    }

}