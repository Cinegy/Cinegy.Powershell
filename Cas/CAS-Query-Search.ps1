. .\CAS-Core.ps1

$context = Get-CasContext

$query = "<ROOT><R M='traffic_programm_id' V='VTVACMV1092' E='EQ' I='0' A='1' Y='2' N='0'></R><R I='0' A='0' Y='101' N='0' S='(type in (30))'></R></ROOT>"

$response = Invoke-CasMethod -MethodRelativeUrl "/search?q=$query" -Context $context

Write-Host "Search for $query returned $($response.total) results"

if ($response.total -gt 1)
{
    Write-Host "Too many placeholder matches ($response.total) - please resolve duplicate placeholder issue for ID XYZ"
    #todo move away file from 'query' folder to cause job to fail
}
elseif ($response.total -eq 0)
{
    Write-Host "No placeholder matched - just a normal ingest then..."
    
    Invoke-CasLogout -context $context
    return;
}
else
{
    $containerRollId = $response.nodes[0].node.parentID._nodeid_id;
    $rollResponse = Invoke-CasMethod -MethodRelativeUrl "/node/$containerRollId" -Context $context
    
    if ($rollResponse.node.node._subtype -ne 540)
    {
        Write-Host "Traffic ID for this item already exists as a clip inside a roll - abandoning import"
        Invoke-CasLogout -context $context
        return;
    }
    
    Write-Host "Placeholder to ingest against: $($response.nodes[0].node.name) (GUID: $($rollResponse.node.node._id._nodeid_id))"
}


$fidef = New-Object XML
$fidef.Load("T:\VTVACMV1092.mov.FIdef");


#create a GlobalParam element, and add attributes to steer this import to a specific placeholder
$xmlGlobalParamRollDestElem = $fidef.FileImport.Global.AppendChild($fidef.CreateElement('GlobalParam'));

$xmlNameAttr = $fidef.CreateAttribute('name');
$xmlNameAttr.Value = 'RollDest'; 
$xmlGlobalParamRollDestElem.Attributes.Append($xmlNameAttr)| Out-Null; 

$xmlValueAttr = $fidef.CreateAttribute('value');
$xmlValueAttr.Value = $rollResponse.node.node._id._nodeid_id; 
$xmlGlobalParamRollDestElem.Attributes.Append($xmlValueAttr) | Out-Null;
$fidef.Save("T:\VTVACMV1092.mov.edited.FIdef");

Invoke-CasLogout -context $context