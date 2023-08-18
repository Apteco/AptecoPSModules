<#
$m = [MailingList]@{mailingListId=123;mailingListName="MailingName"}
$m.toString()

Good hints here: https://xainey.github.io/2016/powershell-classes-and-concepts/

# Play around with different constructors
([MailingList]@{mailingListId=123;mailingListName="abc"}).toString()
([MailingList]::new("123 / abc")).toString()


#>
class MailingList {

    #-----------------------------------------------
    # PROPERTIES (can be public by default, static or hidden)
    #-----------------------------------------------

    [String]$mailingListId
    [String]$mailingListName = ""
    hidden [String]$nameConcatChar = " / "


    #-----------------------------------------------
    # CONSTRUCTORS
    #-----------------------------------------------

    <#
    Notes from: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_object_creation?view=powershell-7
    You can create an object from a hash table of properties and property values.

    The syntax is as follows:

    [<class-name>]@{
    <property-name>=<property-value>
    <property-name>=<property-value>
    }

    This method works only for classes that have a parameterless constructor. The object properties must be public and settable.

    #>

    MailingList () {

        # If we have a nameconcat char in the settings variable, just use it
        if ( $script:settings.nameConcatChar ) {
            $this.nameConcatChar = $script:settings.nameConcatChar
        }

    } # empty default constructor needed to support hashtable constructor

    MailingList ( [String]$mailingId, [String]$mailingName ) {

        $this.mailingListId = $mailingId
        $this.mailingListName = $mailingName

        # If we have a nameconcat char in the settings variable, just use it
        if ( $script:settings.nameConcatChar ) {
            $this.nameConcatChar = $script:settings.nameConcatChar
        }

    }

    MailingList ( [String]$mailingString ) {

        # If we have a nameconcat char in the settings variable, just use it
        if ( $script:settings.nameConcatChar ) {
            $this.nameConcatChar = $script:settings.nameConcatChar
        }

        # Use the 2 in the split as a parameter so it only breaks the string on the first occurence
        $stringParts = $mailingString -split $this.nameConcatChar.trim(),2,"simplematch"
        $this.mailingListId = $stringParts[0].trim()
        $this.mailingListName = $stringParts[1].trim()

    }


    #-----------------------------------------------
    # METHODS
    #-----------------------------------------------

    [String] toString()
    {
        # If we have a nameconcat char in the settings variable, just use it
        # if ( $script:settings.nameConcatChar ) {
        #     $this.nameConcatChar = $script:settings.nameConcatChar
        # }
        return $this.mailingListId, $this.mailingListName -join $this.nameConcatChar
    }

}