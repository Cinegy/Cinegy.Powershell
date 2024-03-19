####################################################################################################
# Cinegy example Football Package - Match Squad
# This script reads an XML Data (MatchData.xml)  
# It demonstrates basic PowerShell reading of XML - but also how Cinegy Titler variables can set text and image variables through the 'Postbox'
# To use - fill in the variables, manually load in (or schedule) the Football_04 scene, and set the script running.
# If you would like to see how to more reliably make sure the script is running and maybe change in some values in XML
# To see how to trigger the scene to come on-air from the script, see
# https://github.com/Cinegy/Cinegy.Powershell/blob/master/Titler/Football/Match_Referees.ps1

#######################
#  Vars to be set     #
#######################
$footballDataXmlFilePath = "C:\Data\Dev\Git\Cinegy.Powershell\Titler\Football\MatchData.xml" # Match Data XML
$airServerAddress = "127.0.0.1" # hostname of machine running Cinegy Air Engine
$airChannelNumber = 0 # playout engine instance number (zero-based)

$xmlDoc = New-Object System.Xml.XmlDocument;
#add root element for request - which is a 'PostRequest' element
$xmlRootElem =  $xmlDoc.AppendChild($xmlDoc.CreateElement('PostRequest'));

#read matchdata from XML
[xml]$match = Get-Content $footballDataXmlFilePath

#create the first SetAttribute element (you can submit many in a request)
#SetAttribute elements must have 3 attributes, the name, type and value
$xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
$xmlSetValueElem.SetAttribute("Name", "REF.Text");
$xmlSetValueElem.SetAttribute("Type",'Text');
$xmlSetValueElem.SetAttribute("Value", $match.Match.mainRef.name + " " + $match.Match.mainRef.surname + " (" + $match.Match.mainRef.countryCode + ")");

$xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
$xmlSetValueElem.SetAttribute("Name", "TITLE.Text");
$xmlSetValueElem.SetAttribute("Type",'Text');
$xmlSetValueElem.SetAttribute("Value", "Assistant Referees");

$xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
$xmlSetValueElem.SetAttribute("Name", "AS_NAME.Text");
$xmlSetValueElem.SetAttribute("Type",'Text');
$xmlSetValueElem.SetAttribute("Value", $match.Match.asRef1.name + " " + $match.Match.asRef1.surname + "                       " + $match.Match.asRef2.name + " " + $match.Match.asRef2.surname);

#uncomment the below line to print the XML into a file to inspect it
#Out-File -FilePath PostXMLLog.xml -InputObject $xmlDoc.OuterXml

#create a .Net webclient which will be used to perform the HTTP POST
$web = New-Object Net.WebClient

#Air requires that the data is in XML format and declared properly - so add the HTTP Header to state this
$web.Headers.Add("Content-Type", "text/xml; charset=utf-8")

#perform the actual HTTP post to the IP and port (which is 5521 + instance number) of the XML data
$web.UploadString("http://$($airServerAddress):$(5521+$airChannelNumber)/postbox", $xmlDoc.OuterXml)