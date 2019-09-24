. .\CAS-Core.ps1

$context = Get-CasContext

#specify the search parameters
$filter="voiceover"
$creationDateFrom = "2010-09-23T10:00:00"
$creationDateTo = "2019-09-23T10:00:00"
$creationDateInclude = "yes"

$query = "q=$($filter)&cd_f=$($creationDateFrom)&cd_t=$($creationDateTo)&cd_x=$($creationDateInclude)"

$response = Invoke-CasMethod -MethodRelativeUrl "/search2?$query" -Context $context

Write-Host "Search query returned $($response.total) results"

foreach($node in $response.nodes)
{
    Write-Host "    $($node.node.name) - $($node.node._id._nodeid_id) - ($($node.node._type))"
}

Invoke-CasLogout -context $context
