. .\CAS-Core.ps1

$context = Get-CasContext
$response = Invoke-CasMethod -MethodRelativeUrl "/export-plugins" -Context $context

if($response.plugins.Count -lt 1)
{
    Write-Host "No export plug-ins available!"
}
elseif($response.retCode -ne 0)
{
    Write-Host "Failed to get export plug-ins list: $($response.error)"
}
else
{
    Write-Host "Available export plug-ins [$($response.plugins.Count)]:"
    foreach($plugin in $response.plugins)
    {
        Write-Host "  $plugin"
    }
    Write-Host
    
    $nodeId = Read-Host -Prompt "Enter node ID to export"
    $exportPlugin = Read-Host -Prompt "Enter export plug-in (ENTER for default '$($response.plugins[0])')"
    
    if([string]::IsNullOrWhiteSpace($exportPlugin))
    {
        $exportPlugin = $response.plugins[0]
    }
    
    $response = Invoke-CasMethod -MethodRelativeUrl "/export/$($exportPlugin)?params=$($nodeId)" -Context $context
    if($response.retCode -ne 0)
    {
        Write-Host "Failed to export node: $($response.error)"
    }
    else 
    {
        #format XML output
        $doc=New-Object System.Xml.XmlDataDocument
        $doc.LoadXml($response.resultXML)
        $sw=New-Object System.Io.Stringwriter
        $writer=New-Object System.Xml.XmlTextWriter($sw)
        $writer.Formatting = [System.Xml.Formatting]::Indented
        $doc.WriteContentTo($writer)
        Write-Host $sw
    }
}


Invoke-CasLogout($context)