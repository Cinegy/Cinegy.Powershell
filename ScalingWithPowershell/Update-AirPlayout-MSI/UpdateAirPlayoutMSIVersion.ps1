#Script to install Air Playout MSIs onto a server
#Also Requires target server to have a C:\Windows\Temp folder, the executing user to have admin rights on the remote box
#PING to be enabled on the target, and for Software Restriction Policies to be defined, with Enforcement set to "All users except local administrators" 
$MSIPath = ".\"
$MSIName = "CinegyPlayoutX64.msi"
$hostname = "localhost" 

Write-Host "Trying $hostname"
    
$PingStatus = Gwmi Win32_PingStatus -Filter "Address = '$hostname'" | Select-Object StatusCode

if ($PingStatus.StatusCode -eq 0)
{
    Write-host "Server alive..."
     
    $wmi = [string]::Format("\\{0}\ROOT\CIMV2:Win32_Product",$hostname)
  
    #check that app is not already installed - if found, uninstall for clean install
    Write-Host 'Checking for an already installed version of Cinegy Playout Engine'
     
    $app = Get-WmiObject -Class "Win32_Product" -ComputerName $hostname | where-object {$_.Name -eq "Cinegy Playout x64"}
     
    if ($app)
    {          
        Write-Host "Cinegy Playout Engine is already installed." 
           
        Write-Host  "Uninstalling"
   
        $app.uninstall() > $null
    }
    else
    {
        Write-Host "Cinegy Playout Engine is not installed." 
    }

    Write-Host "Start Install of Cinegy Playout Engine"
 
    Copy-Item ($MSIPath + $MSIName) "\\$hostname\c$\windows\temp\"
       
    $product = [WMIClass]$wmi
    $var = $product.Install("c:\windows\temp\" + $MSIName)
     
    if ($var.ReturnValue -ne 0)
    { 
        Write-Host "Error installing MSI on $hostname"
        $exit = [string]::Format("exitcode: {0}", $var.ReturnValue)
        Write-Host $exit
    }   
    else
    {
        Write-Host "Installed successfully on $hostname"     
    }

}
else{
    Write-host "Server offline..."
}
     
     
    

 
 
