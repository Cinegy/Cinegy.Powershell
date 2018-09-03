Param([string]$sourceNodeId,[string]$targetParentId,[string]$positionId,[bool]$insertBefore=$false)

. .\CAS-Core.ps1

$context = Get-CasContext

# This is the URL template for sending a move request to the system

#"/move?node={node_id}&parent={parent_id}&position={pos}&befor={befor}

# $sourceNodeId / node_id - This should be the DB ID of the object to move. This object must be 'movable' to work (e.g. a Roll in a Folder will move to another folder

# $targetParentId / parent_id - this is the target folder to move the object into - it must be of a type that permits the object being moved as a child!

# $positionId / position - if the target folder is empty, then the 'after ID' should be the empty guid ([system.guid]::empty) - otherwise it should be the ID of the object that will be the item immediately preceding that item when viewed (e.g. in a clip bin or as the folder order).

# $insertBefore / befor - The 'before' flag is used to indicate the item should be inserted ahead of the item indicated by the 'position' ID. The default (or unspecified) action will result in the item being placed after that indicated item.

$movedResult = Invoke-CasMethod -MethodRelativeUrl "/move?node=$sourceNodeId&parent=$targetParentId&position=$positionId&befor=$insertBefore" -Context $context -Method POST

Invoke-CasLogout($context)
