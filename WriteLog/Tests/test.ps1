Import-Module .\WriteLog
Set-Logfile -Path ".\newtest.log"
#1..5 | Write-Log
get-Logfile