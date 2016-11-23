. .\CAS-Core.ps1

$context = Get-CasContext
$root = Invoke-CasMethod -MethodRelativeUrl '/' -Context $context
$rootchildren = Invoke-CasMethod -MethodRelativeUrl "/nodes/$($root.node._id._nodeid_id)?f=1" -Context $context
$rootchildren.nodes | foreach { $_.node.name + " : " + $_.node._type + " : " + $_.node._subtype + " : " + $_.node._id._nodeid_id} | Write-Host

Invoke-CasLogout($context)