#This is an example script designed to be executed by Cinegy Event Manager via the PowerShell plug-in
#The script accesses the passed-in provider, then uses the Logger object to print out the variables that
#have been passed in (also via the $provider object) before finishing.
param($provider)

# get logger instance to add information directly into task log
$logger = [Cinegy.PowerShell.Command.Logger]$provider.Logger
$logger.LogInfo(" === This is a PowerShell script running inside Event Manager")

# get the event argument dictionary and print to the console
$logger.LogInfo(" === These are the arguments pass in to the event:")
foreach($argument in $provider.Arguments.GetEnumerator())
{
	$Logger.LogInfo("  $($argument.Key): $($argument.value)")
}
