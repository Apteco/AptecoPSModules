
# This is called from the registry entry through the browser

# TODO read this filename from a central json file
"$( $args[0] )" | Set-Content -Path "$( $env:TEMP )\callback.txt" -Encoding utf8

################################################
#
# WAIT FOR KEY
#
################################################
<#
Write-Host -NoNewLine 'Press any key to continue...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

exit 0
#>