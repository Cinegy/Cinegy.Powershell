#some variable values to use within the script
$airServerAddress = "127.0.0.1"
$airChannelNumber = 0
$onScreenText = "This Advertisement is not suitable"

$fineTimeLimit = @{
    startTime = "06:00"
    endTime = "20:00"
}

$startTime = [datetime]::ParseExact($fineTimeLimit.startTime, 'HH:mm', $null)
$endTime = [datetime]::ParseExact($fineTimeLimit.endTime, 'HH:mm', $null)
$timeNow = Get-Date

#make a Type PostRequest XML document using .Net XML document object
$xmlDoc = New-Object System.Xml.XmlDocument;

#add root element for request - which is a 'PostRequest' element
$xmlRootElem =  $xmlDoc.AppendChild($xmlDoc.CreateElement('PostRequest'));



if (($timeNow -ge $startTime) -and ($timeNow -le $endTime)) {
    #create the first SetAttribute element (you can submit many in a request)
    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", "Main.Visible");
    $xmlSetValueElem.SetAttribute("Type",'Bool');
    $xmlSetValueElem.SetAttribute("Value", "true");

    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", "On-Air Volume");
    $xmlSetValueElem.SetAttribute("Type",'Float');
    $xmlSetValueElem.SetAttribute("Value", "-60.00");

    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", "Text.Text");
    $xmlSetValueElem.SetAttribute("Type",'String');
    $xmlSetValueElem.SetAttribute("Value", $onScreenText);    
}
else {
    #create the first SetAttribute element (you can submit many in a request)
    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", "Main.Visible");
    $xmlSetValueElem.SetAttribute("Type",'Bool');
    $xmlSetValueElem.SetAttribute("Value", "false");

    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", "On-Air Volume");
    $xmlSetValueElem.SetAttribute("Type",'Float');
    $xmlSetValueElem.SetAttribute("Value", "00.00");

    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", "Text.Text");
    $xmlSetValueElem.SetAttribute("Type",'String');
    $xmlSetValueElem.SetAttribute("Value", "");  
    
}

#create a .Net webclient which will be used to perform the HTTP POST
$web = New-Object Net.WebClient

#Air requires that the data is in XML format and declared properly - so add the HTTP Header to state this
$web.Headers.Add("Content-Type", "text/xml; charset=utf-8")

#perform the actual HTTP post to the IP and port (which is 5521 + instance number) of the XML data
$web.UploadString("http://$($airServerAddress):$(5521+$airChannelNumber)/postbox", $xmlDoc.OuterXml)