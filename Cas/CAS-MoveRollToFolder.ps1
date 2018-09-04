Param(
    [Parameter(Mandatory=$true)][string]$SourceRollId,
    [Parameter(Mandatory=$true)][string]$TargetFolder
)

. .\CAS-Core.ps1

$context = Get-CasContext

$targetChildren = Invoke-CasMethod -MethodRelativeUrl "/nodes/$($TargetFolder)?f=0" -Context $context

#when moving somewhere, it is required to indicate where the resulting object should be inserted among the existing children of the target location
if($targetChildren.nodes.Length -gt 0)
{
    #if the target has children, place this item after the last element
    $afterId = $targetChildren.nodes[$targetChildren.nodes.Length-1].node._id._nodeid_id
}
else
{
    #if there are no children, specify the ID of the containing folder (strange, but true)
    $afterId = $TargetFolder    
}
$moveResult = Invoke-CasMethod -MethodRelativeUrl "/move?node=$SourceRollId&parent=$TargetFolder&position=$afterId" -Context $context -Method POST 

if($moveResult.retCode -ne 0)
{
    Write-Host "Error moving object: $($moveResult.error)"
}

Invoke-CasLogout($context)