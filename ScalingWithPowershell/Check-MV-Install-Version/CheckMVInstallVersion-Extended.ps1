#read server list from XML
[xml]$servers = Get-Content "ServerList.xml"

ForEach ($server In $servers.ServerList.ChildNodes) 
{   
    $hostname = $server.Name
    
    Write-Host "----------------------------------------------------------------------------"
    Write-Host "Trying $hostname"
    
    $PingStatus = Gwmi Win32_PingStatus -Filter "Address = '$hostname'" | Select-Object StatusCode
    if ($PingStatus.StatusCode -eq 0){
        Write-host "Server alive..."
      

        $wmi = [string]::Format("\\{0}\ROOT\CIMV2:Win32_Product",$hostname)
  
        #check that PSS App it's not already installed.
 
         Write-Host 'Checking for an installed version of Cinegy Multiviewer'
     
        $app = Get-WmiObject -Class "Win32_Product" -ComputerName "$hostname" | where-object {$_.Name -eq "Cinegy Multiviewer"}
     
        if ($app)
        {    
            $version = $app.Version
      
            Write-Host "Cinegy Multiviewer is already installed. Current Version is $version" 
        }
        else
        {
           $app = Get-WmiObject -Class "Win32_Product" -ComputerName "$hostname" | where-object {$_.Name -eq "Cinegy Multiviewer (x64)"}
           if ($app)
            {    
                $version = $app.Version
      
                Write-Host "Cinegy Multiviewer x64 is installed. Current Version is $version" 
            }
            else
            {
                Write-Host "Cinegy Multiviewer (32 or 64-bit) is not installed." 
            }
        }

        
    }
    else{
        Write-host "Server offline..."
    }

}

     
    
