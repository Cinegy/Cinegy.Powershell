$clientId = Get-ItemProperty 'HKLM:\SOFTWARE\Wow6432Node\TeamViewer' -Name ClientID 

#Creating a Mail object
$msg = new-object Net.Mail.MailMessage

#Email structure 
$msg.From = "demoscript@cinegy.com"
$msg.ReplyTo = "demoscript@cinegy.com"
$msg.To.Add("lewis-demo@cinegy.com")
$msg.subject = "Templated Cinegy Machine Booted" 
$msg.body = "A templated machine has booted, 
    and has run up with Teamviewer ID " + $clientId.ClientID

#SMTP server name
$smtpServer = "smtp.lab.local"

#Creating SMTP server object
$smtp = new-object Net.Mail.SmtpClient($smtpServer)

#Sending email 
Write-Host "Sending Email"
$smtp.Send($msg)
