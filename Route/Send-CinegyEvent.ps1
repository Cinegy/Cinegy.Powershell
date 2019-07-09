#This is an example script which shows how to trigger a Cinegy Event Manager event from a PowerShell script.
#It expects the same standard 5 arguments that any Event Manager plug-in expects.
#This script always assumes we are talking to an EventManager installed on the same machine as the script runs
Param([string]$Device,[string]$Command,[string]$OP1,[string]$OP2,[string]$OP3)

#this is just a GUID that indicates the COM object we need to create to talk to the event manager sub-system
$PlayOutExEventSinkCLSID = [GUID]("6ed27a11-6b7e-429a-9c83-a189b9c4ec83")

try {    
	#we use powershell + .NET to get a concrete Type object from the class ID GUID 
	$eventControllerType = [Type]::GetTypeFromCLSID($PlayOutExEventSinkCLSID)
	
	#once we have that type, we can create a realy instance of that type
    #if there is no EventManagerSvc process running on the machine, making this call will start it up
	#if one is already running, it will just attach to that running instance and re-use it
	$eventController = [System.Activator]::CreateInstance($eventControllerType)
	
	#if this worked, $eventController will now be a real object allowing us to make Event Manager do things.
	#if something has gone wrong, we'll be kicked out into the 'catch' script block and will print onto the screen what has gone wrong...

	#we'll pass the arguments as an object array (and it must be of type Object[], it can't just be any collection)
	[Object[]]$eventArguments = $Device,$Command,$OP1,$OP2,$OP3
		
	#we will use the ability of .NET to execute any arbitrary method on a dynamically typed object via just the method name	
    $eventControllerType.InvokeMember("OnEvent", [System.Reflection.BindingFlags]::InvokeMethod, $null, $eventController, $eventArguments)
	
	#that's it - the 'OnEvent' method against the EventManager COM server is called, the arguments are passed - the above method will 'block'
	#until the operation completes, so if there is a problem it can take a while to time out (but if it just works, it will return quickly).
	
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host $ErrorMessage
}