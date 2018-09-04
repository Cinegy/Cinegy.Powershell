Write-Host "Welcome to the interactive credential setup script for creating a CAS Connection`n"
Write-Host "This script will ask for the connection parameters required to talk to CAS`n"
Write-Host "The password will be stored as a secure, encrypted value - but this will may only be decrypted by the user that runs this script!"

$defaultCasUrl = "http://localhost:8082/ICinegyDataAccessRestService/"

$encryptPasswordPrompt = Read-Host -Prompt "Encrypt Password (Y/N)?"

if($encryptPasswordPrompt.Equals("N","CurrentCultureIgnoreCase"))
{
    #if explicit request not to encrypt password is provided then store insecurely (useful when local system services might call script)
    $InsecurePassword = Read-Host -Prompt "Enter CAS account password (WARNING: Stored unencrypted)"
    $SecurePassword = ""
}
else {
    $SecurePassword = Read-Host -Prompt "Enter CAS account password (will be encrypted and readably only by currently logged on user)" -AsSecureString     
    $InsecurePassword = ""
}

$UserName = Read-Host -Prompt "Enter CAS account username"
$UserDomain = Read-Host -Prompt "Enter the domain name of the CAS account user" 
$DatabaseServer = Read-Host -Prompt "Enter Cinegy Archive server name"
$DatabaseName = Read-Host -Prompt "Enter the Cinegy Archive database name"
$CasBaseUrl = Read-Host -Prompt "Enter CAS REST URL (hit enter for default of $defaultCasUrl) "

if([string]::IsNullOrWhiteSpace($CasBaseUrl))
{
    $CasBaseUrl = $defaultCasUrl
}

if([string]::IsNullOrWhiteSpace($SecurePassword)) {    
    $SecureStringAsPlainText = "" 
}
else {
    $SecureStringAsPlainText = $SecurePassword | ConvertFrom-SecureString 
}

#create an object of minimum structure to send to ElasticSearch (this will be the second line sent to server)
$connectionDetails = [PSCustomObject]@{
    SecurePassword = $SecureStringAsPlainText
    InsecurePassword = $InsecurePassword
    UserName = $UserName
    UserDomain = $UserDomain
    DatabaseServer = $DatabaseServer
    DatabaseName = $DatabaseName
    CasBaseUrl = $CasBaseUrl
}

#convert the custom objects to JSON format, with each object on a single line
$jsonDoc = (ConvertTo-Json -InputObject $connectionDetails)

Write-Output $jsonDoc
$jsonDoc | Out-File -FilePath "ConnectionDetails.json" 