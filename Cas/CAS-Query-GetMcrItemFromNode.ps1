Param(
    [Parameter(Mandatory=$true)][string]$SourceNodeId
)

. .\CAS-Core.ps1

$context = Get-CasContext
#Template: "/export/{plugin_id}?params={export_params}". 
$result = Invoke-CasMethod -MethodRelativeUrl "export/CinegyInventoryExport?params=$SourceNodeId" -Context $context

if($result.retCode -ne 0)
{
    Write-Host "Error getting MCR XML for object: $($result.error)"
}
else {
    Write-Host "Selected node MCR XML: $($result.resultXML)"
}

Invoke-CasLogout -Context $context
