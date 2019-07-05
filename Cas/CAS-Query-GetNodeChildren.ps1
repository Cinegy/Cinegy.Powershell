Param(
    [string]$NodeId
)

. .\CAS-Core.ps1

if(!$NodeId)
{
    $NodeId = Read-Host -Prompt "Enter Node ID"
}

$context = Get-CasContext

#first look up the parent object
$response = Invoke-CasMethod -MethodRelativeUrl "/node/$($NodeId)?f=3" -Context $context

if($response.retCode -ne 0)
{
    Write-Host "Failed to locate node: $($response.error)"
    Exit
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

    #now query the child nodes
    
    $childResponse = Invoke-CasMethod -MethodRelativeUrl "/nodes/$($NodeId)?f=3" -Context $context

    Write-Host "Found $($childResponse.nodes.Count) children"
    
    foreach($child in $childResponse.nodes)
    {
        Write-Host "    $($child.node.name) - $($child.node._id._nodeid_id) -($($child.node._type))"
    }
}

Invoke-CasLogout($context)