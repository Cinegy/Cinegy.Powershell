####################################################################################################
# Cinegy example RSS Weather variable injector
# This script reads an RSS feed (from weather API) - YOU WILL NEED YOUR OWN API KEY FOR THIS TO WORK!
# It demonstrates basic PowerShell reading of RSS - but also how Cinegy Titler variables can set text and image variables through the 'Postbox'
# To use - fill in the variables, manually load in (or schedule) the weather scene, and set the script running.
# If you would like to see how to more reliably make sure the script is running and maybe pass in some values
# to a script (like chosen city) in reaction to the current item - see this post:
# https://open.cinegy.com/posts/2020-02-03-automated-dynamic-graphics/
# To see how to trigger the scene to come on-air from the script, see
# https://github.com/Cinegy/Cinegy.Powershell/blob/master/Titler/PushTitlerTemplateOnAir.ps1


#######################
#  Vars to be set     #
#######################
$weatherApiKey = "ADDYOURAPIKEYHERE" # you will need to set this to your own valid API key for this service
$iconUncPath = "D:\Data\dev\GIT\powershell\Titler\TitlerScenes\weather_icon\" # a UNC path pointing to the location of weather icons, in a location the Air server can see / access
$citiesXmlFilePath = "D:\Data\dev\GIT\powershell\Titler\DataSamples\CityList_update.xml" # this file should contain the list of cities you want to read the data for
$onAirTime = 20 # number of seconds to keep a scene on-air
$airEngineHostName = "localhost" # hostname of machine running Cinegy Air Engine
$airEngineInstanceNumber = 0 # playout engine instance number (zero-based)

#read city list from XML
[xml]$cities = Get-Content $citiesXmlFilePath

#webclient to grab RSS data from internet
$client = New-Object Net.WebClient

while ($true) {
    ForEach ($city In $cities.CityList.ChildNodes) {   
        #make a Type PostRequest XML document using .Net XML document object
        $xmlDoc = New-Object System.Xml.XmlDocument;

        #add root element for request - which is a 'PostRequest' element
        $xmlRootElem = $xmlDoc.AppendChild($xmlDoc.CreateElement('PostRequest'));

        $url = "http://api.weatherapi.com/v1/current.xml?key=$weatherApiKey&q=$($city.Name)"
        $serverResponse = "";
        $serverResponse = [xml]$client.DownloadString($url)
    
        $saveFile = "$PSScriptRoot\DataSamples\" + $city.Abbreviation + ".xml"
    
        if ($serverResponse) {
            if ($serverResponse.root.current) {
                Out-File -filepath $saveFile -InputObject  $serverResponse.OuterXml

                [xml]$feed = Get-Content $saveFile

                #if we received the city information we update the template values
                if ($feed.root.current.temp_c) {
                    #create the first SetAttribute element (you can submit many in a request)
                    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));

                    #SetAttribute elements must have 3 attributes, the name, type and value
                    $xmlSetValueElem.SetAttribute("Name", 'City');
                    $xmlSetValueElem.SetAttribute("Type", 'Text');
                    $xmlSetValueElem.SetAttribute("Value", $city.Name);
	
                    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
                    $xmlSetValueElem.SetAttribute("Name", 'Temp');
                    $xmlSetValueElem.SetAttribute("Type", 'Text');
                    $xmlSetValueElem.SetAttribute("Value", $feed.root.current.temp_c.ToString() + '°C');

                    $IconPath = $feed.root.current.condition.icon
                    $PathEle = $IconPath.Split("/")
					
                    $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
                    $xmlSetValueElem.SetAttribute("Name", 'Icon_url');
                    $xmlSetValueElem.SetAttribute("Type", 'Text');
                    $xmlSetValueElem.SetAttribute("Value", $iconUncPath + $PathEle[$PathEle.count - 2] + '\' + $PathEle[$PathEle.count - 1].ToString());	
				
                    Out-File -filepath ".\\Saved\\PostXML-Log.xml" -InputObject  $xmlDoc.OuterXml
    
                    #create a .Net webclient which will be used to perform the HTTP POST (we'll keep it separate from the client the RSS reading uses)
                    $web = New-Object Net.WebClient

                    #Air requires that the data is in XML format and declared properly - so add the HTTP Header to state this
                    $web.Headers.add("Content-Type", "text/xml; charset=utf-8")

                    #perform the actual HTTP post to the IP and port (which is 5521 + instance number) of the XML data
                    $web.UploadString("http://$($airEngineHostName):$(5521+$airEngineInstanceNumber)/postbox", $xmlDoc.OuterXml)

                    #wait some seconds before show the next city 
                    Start-Sleep $onAirTime
                }
                else {
                    Write-Host ("*** Err: No information found: " + $city.Name);
                }

            }
        }
    }
}

