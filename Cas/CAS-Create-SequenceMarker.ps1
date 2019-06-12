Param(
    [string]$SequenceId
)

. .\CAS-Core.ps1

if(!$SequenceId)
{
    $SequenceId = Read-Host -Prompt "Enter sequence ID"
}

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl "/node/$($SequenceId)?f=3" -Context $context

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
}

#TODO: Add call to as-yet-not-existing CreateMarker function on CAS REST

Invoke-CasLogout($context)