$AppName = "CAS-SCRIPT"
$AppVersion = "1.0"
$LicenseId = '{6EECC5D8-DF37-4ead-B79C-25874FD616A2}'
$CasVersion =  '1411301'
$UserName = 'yourusernamehere'
$Password = 'yourpasswordhere'	
$UserDomain = 'munich'
$DbServer = 'cinebsarc1'
$DbName = 'Archive-Bristol-Trunk'
$CasBaseUrl = "http://cinebstyan4.cinegy.local:8082/ICinegyDataAccessRestService/"

function Create-CasAuthenticationHeader()
{
    $app = "$AppName##$LicenseId##$CasVersion##$AppVersion";
    $token = "${UserName}:${Password}:${UserDomain}:${app}:${DbServer}:${DbName}"; 
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

    $login = $web.DownloadString($CasBaseUrl)

    return $web.ResponseHeaders["CinegyContext"]
}

function Invoke-CasMethod($MethodRelativeUrl, $Context, $Method="GET", $Body="")
{
    $web = new-object net.webclient
    $web.Headers.add("Accept", "application/json, text/javascript, */*; q=0.01")
    $web.Headers.add("CinegyContext", $Context)
    
    if($Method -eq "GET")
    {
        $web.DownloadString("${CasBaseUrl}${MethodRelativeUrl}") | ConvertFrom-Json 
    }
    
    if($Method -eq "POST")
    {
        $web.UploadString("${CasBaseUrl}${MethodRelativeUrl}",$Body) | ConvertFrom-Json 
    }
}

function Invoke-CasLogout($Context)
{

    $logout = Invoke-WebRequest -Uri "${CasBaseUrl}/logout" -Method Get -Headers @{"CinegyContext" = $Context} -ErrorAction Continue 

}