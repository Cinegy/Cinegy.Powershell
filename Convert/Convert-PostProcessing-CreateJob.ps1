param($provider)

$settingsPath = "C:\ProgramData\Cinegy\Cinegy Convert\Convert-ConnectionSettings.json"

# -------------------------------------------------------
# Helper functions - see below for the MAIN code
# -------------------------------------------------------
function Get-CasContext($settings)
{
    $logger.Info("Connection settings:" +
        "`nPowerShell`t: $($psversionTable.PSVersion) $($psversionTable.PSEdition)" +
        "`nAppName`t`t: $($settings.appName)" +
        "`nAppVersion`t: $($settings.appVersion)" +
        "`nLicenseId`t: $($settings.licenseId)" +
        "`nCAS Url`t`t: $($settings.casBaseUrl)" +
        "`nDatabase`t: $($settings.DatabaseServer)\$($settings.DatabaseName)" +
        "`nUser`t`t: $($settings.UserDomain)\$($settings.UserName)"
        )
    # create auth header
    $casVersion = '1411301'
    $app = "$($settings.appName)##$($settings.licenseId)##$casVersion##$($settings.appVersion)";
    $token = "$($settings.UserName):$($settings.UserPassword):$($settings.UserDomain):${app}:$($settings.DatabaseServer):$($settings.DatabaseName)"; 
	$bytes  = [System.Text.Encoding]::UTF8.GetBytes($token);
    $encoded = [System.Convert]::ToBase64String($bytes); 
	$authHeader = "Basic " + $encoded;

    $web = new-object net.webclient
    $web.Headers.add("Accept", "application/json, text/javascript, */*; q=0.01")
    $web.Headers.add("Authorization", $authHeader)
    $web.DownloadString($settings.CasBaseUrl) | Out-Null
    
    $context = $web.ResponseHeaders["CinegyContext"]
    $logger.Info("Context: $context")
    return $context
}

function Invoke-CasMethod($MethodRelativeUrl, $Context, $Method="GET", $Body="")
{
    $web = new-object net.webclient
    $web.Headers.add("Accept", "application/json, text/javascript, */*; q=0.01")
    $web.Headers.add("CinegyContext", $Context)
    
    if($Method -eq "GET")
    {
        $web.DownloadString($settings.CasBaseUrl + $MethodRelativeUrl) | ConvertFrom-Json 
    }
    
    if($Method -eq "POST")
    {
        $web.Headers.add("Content-Type", "application/json")
        $web.UploadString($settings.CasBaseUrl + $MethodRelativeUrl,$Body) | ConvertFrom-Json 
    }
}

function Invoke-CasLogout($Context)
{
    Invoke-WebRequest -UseBasicParsing -Uri "$($settings.CasBaseUrl)/logout" -Method Get -Headers @{"CinegyContext" = $Context} -ErrorAction Continue | Out-Null
}

# -------------------------------------------------------
# MAIN
# -------------------------------------------------------

# get logger instance to add information directly into task log

$logger = [Cinegy.Logging.ILogger]$provider.Logger
$logger.Info("=== Post-Processing script - START")
$logger.Info("Loading settings file: $settingsPath")
if([System.Io.File]::Exists($settingsPath) -ne $true)
{
    # terminate the script and report missing file
    throw "Failed to locate settings file: $settingsPath"
}

# load settings
$settings = Get-Content -Path $settingsPath | ConvertFrom-Json

# connect to Cinegy Archive
$logger.Info("Connecting to Cinegy Archive")
$context = Get-CasContext $settings

if($null -eq $context)
{
    throw "Failed to login to Cinegy Archive via CAS"
}

#get CAS version
$casVersion = Invoke-WebRequest -UseBasicParsing -Uri "$($settings.CasBaseUrl)/version" -Method Get -ErrorAction Continue
$logger.Info("CAS: $casVersion")

# job creation parameters
$jobName = $provider.Metadata["src.name"]
$rollName = $provider.Metadata["roll.name"]
$rollId = $provider.Metadata["roll.id"]

# find subject node to be added 
$logger.Info("Loading Roll node info from CAS [$rollId]")
$subjectNodeResult = Invoke-CasMethod -MethodRelativeUrl "/node/$($rollId)?f=1" -Context $context
if($subjectNodeResult.retCode -ne 0)
{
    # logout from CAS to free lisence
    Invoke-CasLogout -Context $Context
    throw "Failed to locate the subject node [$rollId]: $($subjectNodeResult.error)"
} 

# create a new Job
$logger.Info("Creating a new job '$jobName' for the Roll '$rollName' [$rollId]")
$jobParameters = [PSCustomObject]@{
    parent_id = $settings.jobDropTargetId
    name = $jobName
    job_disabled = $false
    subjects = @( $subjectNodeResult.node.node )
}

$parametersJson = (ConvertTo-Json -InputObject $jobParameters -Depth 5)
$response = Invoke-CasMethod -MethodRelativeUrl '/createjob' -Method POST -Body $parametersJson -Context $context

# logout from CAS to free lisence
Invoke-CasLogout -Context $Context

# check result
if($response.retCode -ne 0)
{
    throw "Failed to create job: $($response.error)"
}
else
{
    $logger.Info("Created new job with ID [$($response.node._id._nodeid_id)]")
}

$logger.Info("=== Post-Processing script - END")



