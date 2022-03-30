####################################################################################################
# Cinegy example Analog Clock Script
# This script reads current time from host computer and shows it as a cinegy titler template on screen
# It demonstrates basic PowerShell - Cinegy Titler variables can set text variables through the 'Postbox'
# To use - fill in the variables, manually load in (or schedule) the clock, and set the script running.
# If you would like to see how to more reliably make sure the script is running and maybe pass in some values
# to a script (like chosen city) in reaction to the current item - see this post:
# https://open.cinegy.com/posts/2020-02-03-automated-dynamic-graphics/
# To see how to trigger the scene to come on-air from the script, see
# https://github.com/Cinegy/Cinegy.Powershell/blob/master/Titler/PushTitlerTemplateOnAir.ps1


#######################
#  Vars to be set     #
#######################
$airEngineHostName = "localhost" # hostname of machine running Cinegy Air Engine
$airEngineInstanceNumber = 0 # playout engine instance number (zero-based)

while ($true) {
    #calculate the angle of each arm
    $hourValue = (360/12) * -1 * (Get-Date).ToString('hh');
    $minuteValue = (360/60) * -1 * (Get-Date).ToString('mm');
    $secondValue = (360/60) * -1 * (Get-Date).ToString('ss');

    #make a Type PostRequest XML document using .Net XML document object
    $xmlDoc = New-Object System.Xml.XmlDocument;

    #add root element for request - which is a 'PostRequest' element
    $xmlRootElem = $xmlDoc.AppendChild($xmlDoc.CreateElement('PostRequest'));

    #create the first SetAttribute element (you can submit many in a request)
    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
    #SetAttribute elements must have 3 attributes, the name, type and value
    $xmlSetValueElem.SetAttribute("Name", 'Hour');
    $xmlSetValueElem.SetAttribute("Type", 'Float');
    $xmlSetValueElem.SetAttribute("Value", $hourValue.ToString());

    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
    $xmlSetValueElem.SetAttribute("Name", 'Minute');
    $xmlSetValueElem.SetAttribute("Type", 'Float');
    $xmlSetValueElem.SetAttribute("Value", $minuteValue.ToString());
    
    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
    $xmlSetValueElem.SetAttribute("Name", 'Second');
    $xmlSetValueElem.SetAttribute("Type", 'Float');
    $xmlSetValueElem.SetAttribute("Value", $secondValue.ToString());	

    Out-File -filepath ".\\Saved\\PostXML-Log.xml" -InputObject  $xmlDoc.OuterXml

    #create a .Net webclient which will be used to perform the HTTP POST (we'll keep it separate from the client the RSS reading uses)
    $web = New-Object Net.WebClient

    #Air requires that the data is in XML format and declared properly - so add the HTTP Header to state this
    $web.Headers.add("Content-Type", "text/xml; charset=utf-8")

    #perform the actual HTTP post to the IP and port (which is 5521 + instance number) of the XML data
    $web.UploadString("http://$($airEngineHostName):$(5521+$airEngineInstanceNumber)/postbox", $xmlDoc.OuterXml)       
             
}

