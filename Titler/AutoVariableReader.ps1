#This is an example script designed to be executed by Cinegy Event Manager via the PowerShell plug-in
#The script accesses the passed-in provider, then uses the Logger object to print out the variables that
#have been passed in (also via the $provider object) before finishing.
param($provider)

#user configurable defaults here:
$dataFolder = "D:\Data\Dev\GIT\powershell\Titler\DataSamples"
$separatorChar = ";"

# --- FUNCTION SECTION (scroll down for main script) --- #

#see https://github.com/Cinegy/Cinegy.Powershell/blob/master/Titler/PushTitlerVariableToPostbox.ps1 for commented example
function PostVariablesToAir([string]$ServerUrl,$VarTable){
    $xmlDoc = New-Object System.Xml.XmlDocument;

    $xmlRootElem =  $xmlDoc.AppendChild($xmlDoc.CreateElement('PostRequest'));

    foreach($var in $VarTable.Keys){
        $xmlSetValueElem = $xmlRootElem.AppendChild($xmlDoc.CreateElement('SetValue'));
        $xmlSetValueElem.SetAttribute("Name", $var);
        $xmlSetValueElem.SetAttribute("Type", 'Text');
        $xmlSetValueElem.SetAttribute("Value", $VarTable.$var);
    }
    
    $result = Invoke-RestMethod -Method POST -Body $xmlDoc.OuterXml -ContentType "text/xml; charset=utf-8" -Uri $serverUrl
    if($result.PostReply.Success -ne 1 ) { $logger.LogError("Error in result returned from Air Postbox: $result") }
}

#find a file matching the ID to read and split into sub-variables
function GetVariablesForId([string]$ItemId,[string]$DataFolder,[string]$SeparatorChar=","){
    if($itemId.Length -lt 2) { return $null } #only operate on elements with an ID at least 2 chars long - will skip blanks then

    $matchedSources = Get-ChildItem -Path $DataFolder -Name "$($ItemId)*"
    if($matchedSources.Count -gt 0){
        if($matchedSources.Count -gt 1) { 
            $logger.LogWarning("Multiple data sources match ID, taking no action"); 
            return $null 
        }
        $logger.LogInfo("Found data file $($matchedSources) for variable loading")
        return (Get-Content -Path $matchedSources.PSPath) -Split $SeparatorChar
    }
}

# ---- MAIN SCRIPT STARTS HERE AFTER FUNCTIONS ---- #

# get logger instance to add information directly into task log
$logger = [Cinegy.PowerShell.Command.Logger]$provider.Logger

if($provider.Arguments.Command -ne "TEMPLATEVARS") {
    $logger.LogWarning("Unexpected command $($provider.Arguments.Command) (expected TEMPLATEVARS) - no action taken")
    exit
}

$serverUrl = $provider.Arguments.Op1
$playlist = [Xml]$provider.Arguments.Op2

#check to see if on-air item has a populated titleId that corresponds to any existing file
$variables = GetVariablesForId -ItemId $playlist.titles.onair.titleId -DataFolder $dataFolder -SeparatorChar $separatorChar

if($null -eq $variables) {
    #nothing matched in the check, so now check each cued item - leave loop as soon as something is found
    foreach($cuedItem in $playlist.titles.cue){
        $variables = GetVariablesForId -ItemId $cuedItem.titleId -DataFolder $dataFolder -SeparatorChar $separatorChar
        if($variables) { break }
    }
}

#if we have found any variables to set, set them
if($variables){
    $varTable = @{}
    for($lineNumber = 1;$lineNumber -le $variables.Count;$lineNumber++){
        $logger.LogInfo("Sending variable Line$lineNumber.Text=$($variables[$lineNumber-1])")
        $varTable.Add("Line$lineNumber.Text",$variables[$lineNumber-1])
    }
    PostVariablesToAir -ServerUrl $serverUrl -VarTable $varTable
}

