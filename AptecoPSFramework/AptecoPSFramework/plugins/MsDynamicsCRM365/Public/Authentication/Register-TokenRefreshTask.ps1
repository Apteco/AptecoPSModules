# TODO not implemented yet

function Register-TokenRefreshTask {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory=$true)][String]$SettingsFile
        #,[Parameter(Mandatory=$true)][String]$TokenSettingsFile
    )

    begin {

        #-----------------------------------------------
        # CHECK SETTINGS FILE
        #-----------------------------------------------

        # Check if filename is valid
        if(Test-Path -LiteralPath $SettingsFile -IsValid ) {

            Write-Log "SettingsFile '$( $SettingsFile )' is valid"

            # Check if files exists
            if(Test-Path -LiteralPath $SettingsFile ) {
                Write-Log "SettingsFile '$( $SettingsFile )' is existing"
            } else {
                $msg = "SettingsFile '$( $SettingsFile )' is not existing"
                Write-Log -Message $msg -Severity ERROR
                throw $msg
            }

        } else {

            $msg = "SettingsFile '$( $SettingsFile )' contains invalid characters"
            Write-Log -Message $msg -Severity ERROR
            throw $msg

        }


        #-----------------------------------------------
        # MORE CHECKS
        #-----------------------------------------------

        # Get absolute paths
        $settingsFileAbsolute = ( Get-Item -Path $SettingsFile ).FullName
        #$tokenSettingsFileAbsolute = ( Get-Item -Path $TokenSettingsFile ).FullName


    }

    process {



        #-----------------------------------------------
        # CREATE THE TASK
        #-----------------------------------------------

        # Confirm you want a scheduled task
        $createTask = $Host.UI.PromptForChoice("Confirmation", "Do you want to create a scheduled task for the check and refreshment?", @('&Yes'; '&No'), 0)

        If ( $createTask -eq "0" ) {

            # Means yes and proceed
            Write-Log -message "Creating a scheduled task to check the token hourly"

            # Default task name
            $taskNameDefault = $Script:settings.token.taskDefaultName

            # Replace task?
            $replaceTask = $Host.UI.PromptForChoice("Replace Task", "Do you want to replace the existing task if it exists?", @('&Yes'; '&No'), 0)

            # Means yes and proceed
            If ( $replaceTask -eq "0" ) {

                # Check if the task already exists
                $matchingTasks = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskNameDefault }

                If ( $matchingTasks.count -ge 1 ) {
                    Write-Log -message "Removing the previous scheduled task for recreation"
                    # To replace the task, remove it without confirmation
                    Unregister-ScheduledTask -TaskName $taskNameDefault -Confirm:$false
                }

                # Set the task name to default
                $taskName = $taskNameDefault

            } else {

                # Ask for task name or use default value
                $taskName  = Read-Host -Prompt "Which name should the task have? [$( $taskNameDefault )]"
                if ( $taskName -eq "" -or $null -eq $taskName) {
                    $taskName = $taskNameDefault
                }

            }

            Write-Log -message "Using name '$( $taskName )' for the task"

            # Check batch rights
            # TODO [ ] Find a reliable method for credentials testing
            # TODO [ ] Check if a user has BatchJobrights ##[System.Security.Principal.WindowsIdentity]::GrantUserLogonAsBatchJob

            # Enter username and password so it can run without being logged on
            $credCounter = 0
            Do {
                $taskCred = Get-Credential -UserName $env:Username -Message "Credentials for executing the task"
                $taskCredTest = Test-Credential -Credentials $taskCred
                $credCounter += 1
            } Until ( $taskCredTest -eq $true -or $credCounter -ge 3) # max 3 tries

            If ( $taskCredTest -eq $false ) {
                $msg = "There is a problem with your entered credentials. Please try again later."
                Write-Log -Message $msg -Severity ERROR
                throw $msg
            }

            # $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            # $principal = [Security.Principal.WindowsPrincipal]::new($identity)
            # $isElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
            # Write-Log -Message "User: $( $identity.Name )"
            # Write-Log -Message "Elevated: $( $isElevated )"

            # Parameters for scheduled task
            $taskParams = [Hashtable]@{
                TaskPath = "\Apteco\"
                TaskName = $taskname
                Description = "Refreshes the token for Salesforce every 30 minutes because it is only valid for 1 hour"
                Action = New-ScheduledTaskAction -Execute "$( $Script:settings.token.powershellExePath )" -Argument "-ExecutionPolicy Bypass -File ""$( $Script:pluginRoot )/bin/refresh_token.ps1"" -SettingsFile ""$( $settingsFileAbsolute )"""
                #Principal = New-ScheduledTaskPrincipal -UserId $taskCred.Name -LogonType "ServiceAccount" # Using this one is always interactive mode and NOT running in the background
                Trigger = ( 0..47 | ForEach-Object { New-ScheduledTaskTrigger -at ([Datetime]::Today.AddDays(0).AddMinutes($_*30)) -Daily } ) # Starting every 30 minutes
                Settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -MultipleInstances "Parallel" # Max runtime of 3 minutes
                User = $taskCred.UserName
                Password = $taskCred.GetNetworkCredential().Password
                #AsJob = $true
            }

            # Create the scheduled task
            try {
                Write-Log -message "Creating the scheduled task now"
                $newTask = Register-ScheduledTask @taskParams #T1 -InputObject $task
            } catch {
                Write-Log -message "Creation of task failed or is not completed, please check your scheduled tasks and try again"
                throw $_.Exception
            }

            # Check the scheduled task
            $task = $newTask #Get-ScheduledTask | where { $_.TaskName -eq $taskName }
            $taskInfo = $task | Get-ScheduledTaskInfo
            Write-Host "Task with name '$( $task.TaskName )' in '$( $task.TaskPath )' was created"
            Write-Host "Next run '$( $taskInfo.NextRunTime.ToLocalTime().ToString() )' local time"
            # The task will only be created if valid. Make sure it was created successfully

        }

        #Write-Log -message "Done with task creation"


    }

    end {

    }
}