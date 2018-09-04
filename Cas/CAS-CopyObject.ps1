Param(
    [Parameter(Mandatory=$true)][string]$SourceNodeId,
    [Parameter(Mandatory=$true)][string]$TargetParentId,
    [Parameter(Mandatory=$true)][string]$PositionId,
    [bool]$InsertBefore=$false)

. .\CAS-Core.ps1

# This script demonstrates a generic copy of an object - for a more concrete example, see CAS-CopySequenceToFolder which adds some more sane default handling

$context = Get-CasContext

# This is the URL template for sending a move request to the system

#"/move?node={node_id}&parent={parent_id}&position={pos}&befor={befor}

# $SourceNodeId / node_id - This should be the DB ID of the object to copy. This object must be 'copyable' to work (e.g. a sequence in a folder to copy to another folder)

# $TargetParentId / parent_id - this is the target folder to move the object into - it must be of a type that permits the object being moved as a child!

# $PositionId / position - if the target folder is empty, specify the ID of the containing folder (strange, but true) - otherwise it should be the ID of the object that will be the item immediately preceding that item when viewed (e.g. in a clip bin or as the folder order).

# $InsertBefore / befor - The 'before' flag is used to indicate the item should be inserted ahead of the item indicated by the 'position' ID. The default (or unspecified) action will result in the item being placed after that indicated item.

$moveResult = Invoke-CasMethod -MethodRelativeUrl "/copy?node=$SourceNodeId&parent=$TargetParentId&position=$PositionId&befor=$InsertBefore" -Context $context -Method POST 

if($moveResult.retCode -ne 0)
{
    Write-Host "Error copying object: $($moveResult.error)"
}

Invoke-CasLogout($context)
