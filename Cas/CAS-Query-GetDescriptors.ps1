. .\CAS-Core.ps1

$nodeType = Read-Host -Prompt "Enter node type"
$nodeSubType = Read-Host -Prompt "Enter node subtype"

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl "/descriptors?nt=$($nodeType)&nst=$($nodeSubType)" -Context $context

if($response.retCode -ne 0)
{
    Write-Host "Failed to get node descriptors for type [$($nodeType), $($nodeSubType)]: $($response.error)"
}
else 
{
    $response.descriptors
}

Invoke-CasLogout($context)