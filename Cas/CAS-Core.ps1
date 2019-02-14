$AppName = "CAS-SCRIPT"
$AppVersion = "1.0"
$LicenseId = '{6EECC5D8-DF37-4ead-B79C-25874FD616A2}'
$CasVersion =  '1411301'

function Create-CasAuthenticationHeader()
{
    if([string]::IsNullOrWhiteSpace($($settings.SecurePassword))) {            
        $insecurePassword = $settings.InsecurePassword
    } else {            
        $secureString= ConvertTo-SecureString $settings.SecurePassword
        $insecurePassword = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($secureString))
    }
    
    $app = "$AppName##$LicenseId##$CasVersion##$AppVersion";
    $token = "$($settings.UserName):${insecurePassword}:$($settings.UserDomain):${app}:$($settings.DatabaseServer):$($settings.DatabaseName)"; 
	$bytes  = [System.Text.Encoding]::UTF8.GetBytes($token);
    $encoded = [System.Convert]::ToBase64String($bytes); 
	return "Basic " + $encoded;
}

function Get-CasContext()
{
	$header = Create-CasAuthenticationHeader
    $web = new-object net.webclient
    $web.Headers.add("Accept", "application/json, text/javascript, */*; q=0.01")
    $web.Headers.add("Authorization", $header)
    $web.DownloadString($settings.CasBaseUrl) | Out-Null

    return $web.ResponseHeaders["CinegyContext"]
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
    Invoke-WebRequest -Uri "$($settings.CasBaseUrl)/logout" -Method Get -Headers @{"CinegyContext" = $Context} -ErrorAction Continue | Out-Null
}

function Load-CasSettings()
{
    return Get-Content -Path "ConnectionDetails.json" | ConvertFrom-Json
}

$settings = Load-CasSettings
