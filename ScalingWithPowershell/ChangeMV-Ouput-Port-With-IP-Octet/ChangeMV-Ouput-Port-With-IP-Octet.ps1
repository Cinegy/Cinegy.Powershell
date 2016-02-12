$hostname = $env:COMPUTERNAME

$nics = Gwmi Win32_NetworkAdapterConfiguration -Comp $hostname | Where{($_.IPEnabled -eq "TRUE")}
foreach ($nic in $nics) {
    
    foreach ($addr in $nic.IPAddress) {
        if($addr -like "10.183.*")
        {
            Write-Host "This NIC is on RTP LAN"
            $lastOctet = $addr.Split(".")[3]
            Write-Host "Last octet: " $lastOctet
                        
            $xml = [xml](Get-Content C:\ProgramData\Cinegy\Multiviewer\MultiviewerCnfg.xml)

            $rtpOutput = $xml.SelectSingleNode("/Settings/Output/RtpOutput")
            #$rtpOutput.Url = "rtp://172.31.12.69:1$lastOctet"
            $rtpOutput.Url = "rtp://239.183.3."+$lastOctet+":1234"
            
            $xml.Save("C:\ProgramData\Cinegy\Multiviewer\MultiviewerCnfg.xml")

            Restart-Service -Name MultiviewerSvc
        }
    }
}