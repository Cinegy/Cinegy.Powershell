Param(
    [Parameter(Mandatory=$true)][string]$SourceSequenceId,
    [Parameter(Mandatory=$true)][string]$TargetFolderId
)

. .\CAS-Core.ps1

$context = Get-CasContext

$targetChildren = Invoke-CasMethod -MethodRelativeUrl "/nodes/$($TargetFolderId)?f=0" -Context $context

#when copying somewhere, it is required to indicate where the resulting object should be inserted among the existing children of the target location
if($targetChildren.nodes.Length -gt 0)
{
    #if the target has children, place this item after the last element
    $afterId = $targetChildren.nodes[$targetChildren.nodes.Length-1].node._id._nodeid_id
}
else
{
    #if there are no children, specify the ID of the containing folder (strange, but true)
    $afterId = $TargetFolderId    
}

$moveResult = Invoke-CasMethod -MethodRelativeUrl "/copy?node=$SourceSequenceId&parent=$TargetFolderId&position=$afterId" -Context $context -Method POST 

if($moveResult.retCode -ne 0)
{
    Write-Host "Error copying object: $($moveResult.error)"
}
else {
    Write-Host "Created new sequence from source with ID: $($moveResult.node._id._nodeid_id)"
}

Invoke-CasLogout($context)