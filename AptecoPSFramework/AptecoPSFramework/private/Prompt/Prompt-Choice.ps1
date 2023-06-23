

<#

Example to use

$stringArray = @("Frankfurt","Aachen","Braunschweig")
$choice = Prompt-Choice -title "City" -message "Which city would you prefer?" -choices $stringArray
$choiceMatchedWithArray = $stringArray[$choice -1]

# TODO [ ] put this into a module

#>

Function Prompt-Choice {

    param(
         [Parameter(Mandatory=$true)][string]$title
        ,[Parameter(Mandatory=$true)][string]$message
        ,[Parameter(Mandatory=$true)][string[]]$choices
        ,[Parameter(Mandatory=$false)][int]$defaultChoice = 0
    )

    $i = 1
    $choicesConverted = [System.Collections.ArrayList]@()
    $choices | ForEach {
        $choice = $_
        [void]$choicesConverted.add((New-Object System.Management.Automation.Host.ChoiceDescription "`b&$( $i ) - $( $choice )`n" )) # putting a string afterwards shows it as a help message
        $i += 1
    }
    $options = [System.Management.Automation.Host.ChoiceDescription[]]$choicesConverted
    $result = $host.ui.PromptForChoice($title, $message, $options, $defaultChoice) 

    return $result +1 # add one for index

}
