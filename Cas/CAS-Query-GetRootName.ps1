. .\CAS-Core.ps1

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl '/' -Context $context  
Write-Host $response.node.name 
Invoke-CasLogout -Context $context
