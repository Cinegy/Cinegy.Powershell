#some variable values to use within the script
$airServerAddress = "127.0.0.1"
$airChannelNumber = 0
$variableName = "DemoVariableName"
$variableValue = "Test Demo Value"

#make a Type PostRequest XML document using .Net XML document object
$xmlDoc = New-Object System.Xml.XmlDocument;

#add root element for request - which is a 'PostRequest' element
$xmlRootElem =  $xmlDoc.AppendChild($xmlDoc.CreateElement('PostRequest'));

#create the first SetAttribute element (you can submit many in a request)
$xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

#SetAttribute elements must have 3 attributes, the name, type and value
$xmlSetValueElem.SetAttribute("Name", $variableName);
$xmlSetValueElem.SetAttribute("Type",'Text');
$xmlSetValueElem.SetAttribute("Value", $variableValue);

#uncomment the below line to print the XML into a file to inspect it
#Out-File -FilePath PostXMLLog.xml -InputObject $xmlDoc.OuterXml

#create a .Net webclient which will be used to perform the HTTP POST
$web = New-Object Net.WebClient

#Air requires that the data is in XML format and declared properly - so add the HTTP Header to state this
$web.Headers.Add("Content-Type", "text/xml; charset=utf-8")

#perform the actual HTTP post to the IP and port (which is 5521 + instance number) of the XML data
$web.UploadString("http://$($airServerAddress):$(5521+$airChannelNumber)/postbox", $xmlDoc.OuterXml)