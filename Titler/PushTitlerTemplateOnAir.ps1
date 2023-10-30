#some variable values to use within the script
$airServerAddress = "127.0.0.1"
$airChannelNumber = 0
$airLayerNumber = 5 #Layer Number from 0 - 8
$templatePath = "C:\Data\Dev\Git\Cinegy.Powershell\Titler\TitlerScenes\Lower3rd.cintitle"; #Use the sample scene on TitlerScenes Folder - Lower3rd.cintitle
$titleText = "Top Line For Title"
$newsText = "Details of the news story for the audience to understand the plot with 3 or less sentences."

$varialbleList = "<Variables>"
$varialbleList += "<Var Name=""TopText.Text"" Type=""String"" Value=""$titleText"" />"
$varialbleList += "<Var Name=""BottomText.Text"" Type=""String"" Value=""$newsText"" />"
$varialbleList += "</Variables>"

#make a Type PostRequest XML document using .Net XML document object
$xmlDoc = New-Object System.Xml.XmlDocument;
$decl = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)

#add root element for request - which is a 'PostRequest' element
$xmlRootElem =  $xmlDoc.AppendChild($xmlDoc.CreateElement('Request'));
$xmlDoc.InsertBefore($decl, $xmlDoc.DocumentElement)

#create the first SetAttribute element (you can submit many in a request)
$xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('Event'));

$xmlDevAttr = $xmlDoc.CreateAttribute('Device');
$xmlDevAttr.Value = '*GFX_' + $airLayerNumber; 
$xmlSetValueElem.Attributes.Append($xmlDevAttr);  

$xmlCmdAttr = $xmlDoc.CreateAttribute('Cmd');
$xmlCmdAttr.Value = 'SHOW'; 
$xmlSetValueElem.Attributes.Append($xmlCmdAttr);  

$xmlSetOp1Elem = $xmlDoc.CreateElement('Op1');
$xmlSetOp1Elem.InnerText = $templatePath
$xmlSetValueElem.AppendChild($xmlSetOp1Elem);

$xmlSetOp2Elem = $xmlDoc.CreateElement('Op2');
$xmlSetOp2Elem.InnerText = $varialbleList
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
$web.UploadString("http://$($airServerAddress):$(5521+$airChannelNumber)/video/command", $xmlDoc.OuterXml)

$xmlDoc.OuterXml | Out-File ".\xmldoc.xml"