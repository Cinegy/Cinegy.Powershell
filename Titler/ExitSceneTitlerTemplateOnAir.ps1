#make a Type PostRequest XML document using .Net XML document object
$xmlDoc = New-Object System.Xml.XmlDocument;
$decl = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)

#add root element for request - which is a 'PostRequest' element
$xmlRootElem =  $xmlDoc.AppendChild($xmlDoc.CreateElement('Request'));
$xmlDoc.InsertBefore($decl, $xmlDoc.DocumentElement)

#create the first SetAttribute element (you can submit many in a request)
$xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('Event'));

$xmlDevAttr = $xmlDoc.CreateAttribute('Device');
$xmlDevAttr.Value = '*GFX_LOGO'; 
$xmlSetValueElem.Attributes.Append($xmlDevAttr);  

$xmlCmdAttr = $xmlDoc.CreateAttribute('Cmd');
$xmlCmdAttr.Value = 'EXIT_SCENE_LOOP'; 
$xmlSetValueElem.Attributes.Append($xmlCmdAttr);  

$xmlSetOp1Elem = $xmlDoc.CreateElement('Op1');
$xmlSetOp1Elem.InnerText = "";
$xmlSetValueElem.AppendChild($xmlSetOp1Elem);

$xmlSetOp2Elem = $xmlDoc.CreateElement('Op2');
$xmlSetOp2Elem.InnerText = ""
$xmlSetValueElem.AppendChild($xmlSetOp2Elem);

$xmlSetOp3Elem = $xmlDoc.CreateElement('Op3');
$xmlSetOp3Elem.InnerText = "";
$xmlSetValueElem.AppendChild($xmlSetOp3Elem);
$xmlDoc.InnerXml;

#create a .Net webclient which will be used to perform the HTTP POST
$web = new-object net.webclient

#Air requires that the data is in XML format and declared properly - so add the HTTP Header to state this
$web.Headers.add("Content-Type", "text/xml; charset=utf-8")

#perform the actual HTTP post to the IP and port (which is 5521 + instance number) of the XML data
$web.UploadString("http://localhost:5521/video/command", $xmlDoc.OuterXml)

$xmlDoc.OuterXml | Out-File "D:\Temp\xmldoc.xml"