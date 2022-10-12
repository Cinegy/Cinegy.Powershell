Param(
    [string]$FolderId
)

. .\CAS-Core.ps1

if(!$FolderId)
{
    $FolderId = Read-Host -Prompt "Enter parent folder ID [default 'Default master clip folder']"
}

if([string]::IsNullOrEmpty($FolderId))
{
    # set parent folder id to 'Default master clip folder'
    $folderId = '5c731347-6360-489e-87ef-598b83ea96aa'
}

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl "/node/$($FolderId)?f=3" -Context $context

if($response.retCode -ne 0)
{
    Write-Host "Failed to locate node: $($response.error)"
    Exit
}
else 
{
    $parentName = $response.node.node.name
    Write-Host "Found node '$($parentName)' with ID: $($response.node.node._id._nodeid_id)"
    
    Write-Host "  Tags:"
    foreach($tag in $response.node.tags)
    {
        Write-Host "    $($tag)"
    }

    $nodeName = "Sample node from API"
    $nodeSubtype = 4004 #Folder subtype, can be checked in Cinegy Archive Manager in case custom one is required

    $response = Invoke-CasMethod -Method POST -MethodRelativeUrl "/createfolder?parent=$($FolderId)&subtype=$($nodeSubtype)&name=$($nodeName)" -Context $context
    if($response.retCode -eq 0)
    {
        Write-Host "Created sub-folder in sequence"
        Write-Host "Available children:"
        $children = Invoke-CasMethod -MethodRelativeUrl "/nodes/$($FolderId)?f=1" -Context $context
        $children.nodes | foreach { $_.node.name + " : " + $_.node._type + " : " + $_.node._subtype + " : " + $_.node._id._nodeid_id} | Write-Host
    }
    else 
    {
        Write-Host "Failed to create folder - return code $($response.retCode)"
    }
}

Invoke-CasLogout($context)