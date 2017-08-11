FUNCTION Send-HTMLmailMessage {
    <#
    .SYNOPSIS
    Send mail messages with a preformatted HTML body. 
    .DESCRIPTION
    This function utilizes the "Send-MailMessage -BodyAsHTML" cmdlet to send an
    HTML table formatted message with a clearly visible title, heading, and
    HTML formatable body text for easy to read email notification messages. 
    
    NOTE: This function assumes that you are relaying messages without authentication.
    .PARAMETER SMTPserver
    Same as 'Send-MailMessage -SmtpServer $SMTPserver'
    This is the AD computer name or DNS host name of the mail server. 
    .PARAMETER From
    Same as 'Send-MailMessage -From $From'
    This is the email address that will appear on the From line of the header. 
    When relaying messages I generally use the format of 'computername@example.com'
    .PARAMETER To
    Same as 'Send-MailMessage -To $To'
    This is the distribution list or email address(es) that the message will be sent to 
    using the format '"user01@example.com"' or '"user02@example.com","user03@example.com"' 
    .PARAMETER Subject
    Same as 'Send-MailMessage -Subject $Subject'
    .PARAMETER Title
    This is a custom parameter in this function. 
    The "Title" will be an H1 header with white text on a dark background at the top of 
    the message. Recommended useage would be to indicate the script sending the message. 
    .PARAMETER Heading
    This is a custom parameter in this function. 
    The "Heading" will be a H2 header with dark text on a white background under the 
    title. Recommended usage would be to indicate the purpose of the message. 
    .PARAMETER Body
    This is a modified parameter in this function. 
    The "Body" can be as simple as an unformatted string of text, or as complicated as 
    you can get with inline HTML tags. 
    .PARAMETER Priority
    Same as 'Send-MailMessage -Priority $Priority'
    Set the priority of the email message. If left unused, defaults to High. 
    .PARAMETER Attachments
    Same as 'Send-MailMessage -Attachments $Attachments'
    You can optionally send the email with (an) attachment(s)
    .PARAMETER Color
    This is a custom parameter in this function. Entering a plain color in quotes chooses from the 
    preset color schemes for the Light and Dark colors of the email. The current color choices are: 
    "red","blue"
    When this parameter is left unused or an undefined color is chosen, the default color scheme is red. 
    DarkColor: Title border and Heading  
    LightColor: Title background 
    .EXAMPLE
    $name='uidiot'
    $name2='uidiot1'
    $mmSMTP = 'mailserver.example.com'
    $mmFrom = 'computer@example.com'
    $mmTo = 'user@example.com'
    $mmSubject = 'HTMLmailMessage Test message'
    $mmTitle = 'Title'
    $mmHeading = 'Heading'
    $mmBody = "The assigned username <strong>$name</strong>, has been changed to <strong>$name2</strong>."

    Send-HTMLmailMessage -SMTPserver $mmSMTP -From $mmFrom -To $mmTo -Subject $mmSubject -Title $mmTitle -Heading $mmHeading -Body $mmBody

    .NOTES
    Authors: James Weigel and Sarah Milam

    #>
    [CmdletBinding()]
	param(
        [parameter(Mandatory=$True)][string]$SMTPserver,
        [parameter(Mandatory=$True)][string]$From,
        [parameter(Mandatory=$True)][string[]]$To,
        [parameter(Mandatory=$True)][string]$Subject,
        [string]$Title,
        [string]$Heading,
        [string[]]$Body,
        [string]$Priority="High",
        [string[]]$Attachments,
        [string]$Color="red"
    )
    Switch ($Color) {
        {$_ -imatch "red"}       {$DarkColor='#4d0000'; $LightColor='#990000'}
        {$_ -imatch "blue"}      {$DarkColor='#000066'; $LightColor='#20497f'}
        default                  {$DarkColor='#4d0000'; $LightColor='#990000'} ##default (ie a bad color choice) is the red scheme
    } ##END $Color switch

	$mmHTMLbody = 
@"
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
    <html>
	    <body>
		    <table align="center" border="0" cellspacing="0" width="95%" style="font-family:Verdana, Arial, Helvetica, sans-serif;"> 
			    <tr> <td style="display: block; clear: both; background-color:$DarkColor;height:6px;"> </td> </tr>
			    <tr> <td style="background-color:$LightColor;"> 
                    <h1 style="font-family:Verdana, Arial, Helvetica, sans-serif; color:#ffffff; margin:16px;">$Title</h1> 
                </td> </tr>
			    <tr> <td style="display: block; clear: both; background-color:$DarkColor;height:3px;"> </td> </tr>
			    <tr> <td style="padding:10px; border:solid thick #eeeeee;border-top:0;display: block; clear: both;"> 
                    <h2 style="color:$DarkColor; font-family:Verdana, Arial, Helvetica, sans-serif; ">$Heading</h2> 
                    <p style="margin-top:0; font-family:Verdana, Arial, Helvetica, sans-serif; ">$Body</p>
				</td></tr>
		    </table>
	    </body>
    </html>
"@
    If ($Attachments) { Send-MailMessage $To $Subject $mmHTMLbody $SMTPserver -From $From -BodyAsHtml -Priority $Priority -Attachments $Attachments }
    Else { Send-MailMessage $To $Subject $mmHTMLbody $SMTPserver -From $From -BodyAsHtml -Priority $Priority }
} ##END FUNCTION Send-HTMLmailMessage

