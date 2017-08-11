FUNCTION Disable-AdditionalAccounts {
<#
.SYNOPSIS
Check for additional accounts associated with a user and 
attempt to disable and move them.

.DESCRIPTION
Checks for additional accounts associated with a user such as 
priviledged or administrative accounts. Attempts to disable and 
move them to the Quitters OU. 

Sends an email to the account's manager(s) as well as OpsTeam 
informing of disabled accounts. In the case of failure, a separate 
email is sent only to OpsTeam informing of need to manually disable 
certain accounts. The activity is logged in 
.\ARCHIVE\ActivityLog-$($user.SamAccountName).txt

Requires the HTMLmailMessage Function.

.PARAMETER user
The user's primary account. Only one account may be processed 
by the function at a time.

.INPUTS
An AD user object can be piped in.

.OUTPUTS
An activity log .txt file will be created in the current directory.

.EXAMPLE
Get-aduser tstark | Disable-AdditionalAccounts

.EXAMPLE
Disable-AdditionalAccounts -user tstark

.NOTES
Author: Sarah Milam
Created: 2017/06/21

UPDATE NOTES:
-------------

#>


    [CmdletBinding()]
    Param(
        [parameter(
        ValueFromPipeline=$true
        , Mandatory=$true
        )]
        $user
    )
    
    PROCESS{

        #REGION BEGIN SCRIPT # # # # # # # # # # # # # # # # # # # # # # # # #

            . C:\SCRIPTS\COMMON\DefaultVariables.ps1

            #Get all user accounts that have a nRELobjectOwnerSID property
            $user = Get-ADUser $user
            $Accounts = Get-ADObject -Properties objectOwnerSID,objectOversightSID,objectGUID,CanonicalName,Name,SamAccountName -Filter 'objectOwnerSID -like "*"'
            $OwnerSID = (Get-ADUser $user -Properties SID -ErrorAction Stop | Select -ExpandProperty SID ) 
            $PrimaryUser = $($user.Name)
            $AccMatches = @()
            [string[]]$OversightEmail = @()
            $today = Get-Date -Format "MM/dd/yyyy"

            $ActivityLog = ".\ARCHIVE\ActivityLog-$($user.SamAccountName).txt"
                IF (Test-Path $ActivityLog -PathType Leaf) { 
                    Remove-Item $ActivityLog 
                    sleep -Seconds 2
                }
        
            Add-Content -Path $ActivityLog -Value "$(get-date -Format s)`t|`tStarting the script: Disable-AdditionalAccounts.ps1" 
            Add-Content -Path $ActivityLog -Value "Searching for additional accounts for $PrimaryUser."

        #ENDREGION BEGIN SCRIPT


        #REGION GET DATA # # # # # # # # # # # # # # # # # # # # # # # #

            IF ($OwnerSID -in $Accounts.objectOwnerSID) {
                $AccMatches = @($Accounts | Where-Object objectOwnerSID -eq $OwnerSID)
                $OversightEmail += $($AccMatches.objectOversightSID)

                Add-Content -Path $ActivityLog -Value "$($AccMatches.count) additional accounts found for user $($user.SamAccountName)."
                Add-Content -Path $ActivityLog -Value $($AccMatches | sort SamAccountName `
                    | Format-List -Property SamAccountName,Name,objectOversightSID,CanonicalName,objectGUID | Out-String -Width 4096 )
            } ##END IF

            Else {
                Write "No additional accounts found for user $($user.SamAccountName)."
                Add-Content -Path $ActivityLog -Value "No additional accounts found for user $($user.SamAccountName)."
            } ##END ELSE

        #ENDREGION GET DATA

      
        #REGION PROCESS DATA # # # # # # # # # # # # # # # # # # # # # # # # # #
        IF ($AccMatches) {
        
            ##Disable Additional Accounts 
            $DeleteDate = $(([datetime]($today)).AddDays(5) | Get-Date -UFormat "%Y-%m-%d")
            $OGUID = $null
            $Note = $null

            foreach ($I in $AccMatches) {

                TRY {
                    Get-ADUser $I -Properties Description -OutVariable ADUP | Out-Null
                    $OGUID = $ADUP.ObjectGUID
                    $Note = "Delete $DeleteDate - Additional Account auto-disabled due to Primary Account status change"
                    $MoveError = $null

                    Set-ADUser -Identity $OGUID -Description $Note -PassThru -ErrorAction Stop | Out-Null
                    Disable-ADAccount -Identity $OGUID -PassThru -ErrorAction Stop | Out-Null
                    Move-ADObject -Identity $OGUID -TargetPath "OU=Quitters,DC=FancyPants,DC=com" -ErrorAction Stop | Out-Null
                    Sleep -Seconds 1

                } #TRY

                CATCH {
        
                    $MoveError = (($_.Exception.Message) + ": <br> $($_.InvocationInfo.Line)")

                    Add-Content -Path $ActivityLog -Value "$I must be manually modified, due to an error."
                    Add-Content -Path $ActivityLog -Value "The error was: $MoveError"

        		    $mmSMTP = 'Letters.FancyPants.com'
		            $mmFrom = "Robot@FancyPants.com"
		            $mmTo = "OpsTeam@FancyPants.com"
        		    $mmSubject = "[NOTIFICATION] Disable Additional Account"
		            $mmTitle = "Information Technology Services"
        		    $mmHeading = "Disable Additional Account"
		            $mmBody = @"
                            The primary account for $PrimaryUser has been disabled due to an employment status change. <br /><br />
                            The script encountered an error and was unable to automatically disable one or more of the user's additional acounts.
                            All additional accounts associated with this user need to be disabled and/or deleted unless an alternative action is requested. <br /><br />
                            <strong>The user's additional account that needs to be manually modified is: $I. </strong>  <br /><br />
                            The error was: $MoveError
"@

        		    $parameters = @{
        			    SMTPserver = $mmSMTP
    	    		    From = $mmFrom
    		    	    To = $mmTo
        			    Subject = $mmSubject
        			    Title = $mmTitle
    	    		    Heading = $mmHeading
    		    	    Body = $mmBody
    		        }
    		        HTMLmailMessage @parameters
                        #splatting in action!
                    $mmBody = $null
                    $mmHeading = $null

                } ## END CATCH
            } ## End Foreach ($I in $AccMatches)


            ## Email final activity log to cyberops and all manager's involved
            
            $OversightEmail += "OpsTeam@FancyPants.com"
            $OversightEmail = @($OversightEmail.split(",",[System.StringSplitOptions]::RemoveEmptyEntries) | sort -unique)
        	$mmSMTP = 'Letters.FancyPants.com'
		    $mmFrom = "Robot@FancyPants.com"
		    $mmTo = $OversightEmail.Split(',')
    	    $mmSubject = "[NOTIFICATION] Additional Accounts Disabled for Terminated Employee"
            $mmTitle = "Information Technology Services"
    	    $mmHeading = "Your Employee's Additional Login Account(s)"
	        $mmBody = @"
                    The primary account for $PrimaryUser has been disabled due to an employment status change. 
                    Additional accounts associated with this user have been disabled and marked to be deleted 
                    in 5 days unless an alternative action is requested. Please contact OpsTeam@FancyPants.com
                    if you would like a different action to be taken.
                    <br /><br />
                    Please see the Log .txt attachment for a list of the user's additional accounts that were 
                    disabled as well as any accounts that may need further attention from the Operations team.
"@

            $parameters = @{
        	    SMTPserver = $mmSMTP
    		    From = $mmFrom
		        To = $mmTo
        	    Subject = $mmSubject
    		    Title = $mmTitle
    	        Heading = $mmHeading
        	    Body = $mmBody
                Attachments = $ActivityLog
                Color = "blue"
            }
    	    HTMLmailMessage @parameters

            $mmBody = $null
            $mmHeading = $null

        } ## END IF ($AccMatches)
    
        #ENDREGION PROCESS DATA 

    } ## END Process

} #END FUNCTION DISABLE-ADDITIONALACCOUNTS
