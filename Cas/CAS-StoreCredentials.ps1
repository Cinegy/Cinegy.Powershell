Write-Host "Welcome to the interactive credential setup script for creating a CAS Connection`n"
Write-Host "This script will ask for the connection parameters required to talk to CAS`n"
Write-Host "The password will be stored as a secure, encrypted value - but this will may only be decrypted by the user that runs this script!"


$Username = Read-Host -Prompt "Enter CAS account username"
$Userdomain = Read-Host -Prompt "Enter the domain name of the CAS account user" 
$SecurePassword = Read-Host -Prompt "Enter CAS account password" -AsSecureString 
$DatabaseServer = Read-Host -Prompt "Enter Cinegy Archive server name"
$DatabaseName = Read-Host -Prompt "Enter the Cinegy Archive database name"

$SecureStringAsPlainText = $SecurePassword | ConvertFrom-SecureString 

#create an object of minimum structure to send to ElasticSearch (this will be the second line sent to server)
$connectionDetails = [PSCustomObject]@{
    SecurePassword = $SecureStringAsPlainText
    Username = $Username
    Userdomain = $Userdomain
    DatabaseServer = $DatabaseServer
    DatabaseName = $DatabaseName
}

#convert the custom objects to JSON format, with each object on a single line
$jsonDoc = (ConvertTo-Json -InputObject $connectionDetails)

Write-Output $jsonDoc
$jsonDoc | Out-File -FilePath "ConnectionDetails.json" 