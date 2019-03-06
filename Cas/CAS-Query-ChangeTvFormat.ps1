. .\CAS-Core.ps1

#predefined TV format field
$fieldNum = 11

$nodeId = Read-Host -Prompt "Enter node ID"
$tvFormat = Read-Host -Prompt "Enter node new TV Format"

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl "/node/$($nodeId)?f=3" -Context $context

if($response.retCode -ne 0)
{
    Write-Host "Failed to locate node: $($response.error)"
}
else 
{
    Write-Host "Found node with ID: $($response.node.node._id._nodeid_id)"
    
    Write-host "Old TV Format: $($response.node.node.tvFormat)"

    $response = Invoke-CasMethod -MethodRelativeUrl "/setproperty?node=$($nodeId)&fieldnum=$($fieldNum)&value=$($tvFormat)" -Context $context -Method POST

    if($response.retCode -ne 0)
    {
        Write-Host "Failed to update node: $($response.error)"
    }
    else 
    {
        Write-Host "Node TV format is updated."
    }
}

Invoke-CasLogout($context)