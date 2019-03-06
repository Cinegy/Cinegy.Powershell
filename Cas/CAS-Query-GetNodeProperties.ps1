. .\CAS-Core.ps1

$nodeId = Read-Host -Prompt "Enter node ID"

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl "/node/$($nodeId)?f=3" -Context $context

if($response.retCode -ne 0)
{
    Write-Host "Failed to locate node: $($response.error)"
}
else 
{
    Write-Host "Found node with ID: $($response.node.node._id._nodeid_id)"
    
    Write-Host "  Tags:"
    foreach($tag in $response.node.tags)
    {
        Write-Host "    $($tag)"
    }

    Write-Host "  Node:"
    Write-Host ($response.node.node | Format-List | Out-String)
}

Invoke-CasLogout($context)