Param(
    [Parameter(Mandatory=$true)][string]$TrafficId
)

. .\CAS-Core.ps1

$context = Get-CasContext

#this preset query locates the system field for traffic ID, and then will search for any objects of type 30 (Rolls) that have this ID
$query = "<ROOT><R M='traffic_programm_id' V='$TrafficId' E='EQ' I='0' A='1' Y='2' N='0'></R><R I='0' A='0' Y='101' N='0' S='(type in (30))'></R></ROOT>"

$response = Invoke-CasMethod -MethodRelativeUrl "/search?q=$query" -Context $context

Write-Host "Search for $query returned $($response.total) results"

if ($response.total -gt 1)
{
    Write-Host "Too many placeholder matches ($response.total) - please resolve duplicate placeholder issue for ID $TrafficId"
}
elseif ($response.total -eq 0)
{
    Write-Host "No placeholder matched for ID $TrafficId"
    
    Invoke-CasLogout -context $context
    return;
}
else
{
    $containerRollId = $response.nodes[0].node.parentID._nodeid_id;
    $rollResponse = Invoke-CasMethod -MethodRelativeUrl "/node/$containerRollId" -Context $context
    
    if ($rollResponse.node.node._subtype -ne 540)
    {
        Write-Host "Clip found with traffic ID $TrafficId inside roll: $($response.nodes[0].node.name) (GUID: $($rollResponse.node.node._id._nodeid_id))"
        Invoke-CasLogout -context $context
        return;
    }
    
    Write-Host "Placeholder roll only found waiting for ingest: $($response.nodes[0].node.name) (GUID: $($rollResponse.node.node._id._nodeid_id))"
}
