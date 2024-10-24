#Script to read a Cinegy Multiviewer 'metrics' REST API, and then pre-process this data into the format needed for our ElasticSearch dashboards.
#By default, this script will send the telemetry to the Cinegy central telemetry portal - this is not supported for production critical use.

Set-StrictMode -Version Latest

#change these variables depending upon your environment
$telemetryServerUrl = "https://telemetry.cinegy.com"
$OrganizationName="cinegy"
$tags="test,localhost"
$multiviewersrv = "localhost"


#don't change these unless you know what you are doing
$IndexName = "multiviewersrt"
$Level="Info"

#srt counters for 'periodic' measurements
$lastRecords = $null

function Send-TelemetryMessage([string] $body) {
	#create webclient object, add JSON content-type header, and POST to telemetry server
	$web = new-object net.webclient
	$web.Headers.add("Content-Type", "application/json")
	$web.UploadString("$telemetryServerUrl/_bulk",$body)
}

function Get-MVSrtMetricsMessage() {
    #create an object of correct structure to steer the log record in ElasticSearch (this will be first line sent to server)
    $index = [PSCustomObject]@{
        index = [PSCustomObject]@{
            _index = "$IndexName-$OrganizationName-$([System.DateTime]::UtcNow.Year).$([System.DateTime]::UtcNow.Month.ToString("00")).$([System.DateTime]::UtcNow.Day.ToString("00"))"
            }
    }

    $telemetry = [xml](Invoke-WebRequest -Uri http://$($multiviewersrv):8090/Multiviewer/Rest/GetSRTStats).Content
        
    $body = ""
    $queryTime = (Get-Date).ToString("O")
 
    if([bool]$(Get-Member -inputobject $telemetry -name "SrtStats" -Membertype Properties) -eq $false) {
        $global:lastRecords = $null
        return $null
    }

	if([bool]$(Get-Member -inputobject $telemetry.SrtStats -name "Connections" -Membertype Properties) -eq $false) {
        $global:lastRecords = $null
        return $null
    }

    if([bool]$(Get-Member -inputobject $telemetry.SrtStats.Connections -name "Connection" -Membertype Properties) -eq $false) {
        $global:lastRecords = $null
        return $null
    }

    $records = $telemetry.SrtStats.Connections.Connection | Sort-Object -Property "MsTimeStamp"
    
    if($null -eq $global:lastRecords) { $global:lastRecords = $records }
    
	if($(Get-Member -inputobject $global:lastRecords -name "SrtStats" -Membertype Properties) -eq $false) {
        $global:lastRecords = $null
        return $null
    }

    foreach ($record in $records) {
        #don't log any stats for localhost connections
        if($record.Key -Match "127.0.0.1") { continue }

        $connectedTime = [TimeSpan]::FromMilliseconds($record.MsTimeStamp)
        Write-Host "Connection $($record.Key) - ($($connectedTime.ToString("dd' days 'hh\:mm\:ss"))) "

        $deltaPktRetrans = 0
        $deltaPktSndLoss = 0
        $deltaPktRcvLoss = 0
        $deltaPktSndDrop = 0
        $deltaPktRcvDrop = 0
        $deltaPktSent = 0
        $deltaPktRecv = 0
        $deltaMsRtt = 0.0
        $deltaPctPktLoss = 0.0

        #check a few key values to create delta values (more efficient to pre-calc and store than live query)
        foreach ($lastRecord in $global:lastRecords) {
            if($lastRecord.Key -eq $record.Key) {
                $deltaPktRetrans = [int64]$record.PktRetrans - [int64]$lastRecord.PktRetrans
                $deltaPktSndLoss = [int64]$record.PktSndLoss - [int64]$lastRecord.PktSndLoss
                $deltaPktRcvLoss = [int64]$record.PktRcvLoss - [int64]$lastRecord.PktRcvLoss
                $deltaPktSndDrop = [int64]$record.PktSndDrop - [int64]$lastRecord.PktSndDrop
                $deltaPktRcvDrop = [int64]$record.PktRcvDrop - [int64]$lastRecord.PktRcvDrop
                $deltaPktSent = [int64]$record.PktSent - [int64]$lastRecord.PktSent
                $deltaPktRecv = [int64]$record.PktRecv - [int64]$lastRecord.PktRecv                
                $deltaMsRtt = [single]$record.MsRTT - [single]$lastRecord.MsRTT

                if($deltaPktRetrans -gt 0) {
                    if($deltaPktSent -gt 0) {
                        $deltaPctPktLoss = ($deltaPktRetrans / $deltaPktSent) * 100
                    }
                    else {
                        $deltaPctPktLoss = ($deltaPktRetrans / $deltaPktRecv) * 100
                    }
                }
            }
        }
        
        #create an object of minimum structure to send to ElasticSearch (this will be the second line sent to server)
        $log = [PSCustomObject]@{
            level = $Level
            time = $queryTime
            tags = $tags
            host = $multiviewersrv
            logger = "PowershellMVSrtScript"
            key = "TSD"
            srtstats = [PSCustomObject]@{
                connectionKey = $record.Key
                msTimeStamp = [int64]$record.MsTimeStamp
                pktSent = [int64]$record.PktSent
                pktRecv = [int64]$record.PktRecv
                pktSndLoss = [int64]$record.PktSndLoss
                pktRcvLoss = [int64]$record.PktRcvLoss
                pktRetrans = [int64]$record.PktRetrans
                pktRcvRetrans = [int64]$record.PktRcvRetrans
                pktSentACK = [int64]$record.PktSentACK
                pktRecvACK = [int64]$record.PktRecvACK
                pktSentNAK = [int64]$record.PktSentNAK
                pktRecvNAK = [int64]$record.PktRecvNAK
                mbpsSendRate = [single]$record.MbpsSendRate
                mbpsRecvRate = [single]$record.MbpsRecvRate
                usSndDuration = [int64]$record.UsSndDuration
                pktReorderDistance = [int64]$record.PktReorderDistance
                pktRcvAvgBelatedTime = [single]$record.PktRcvAvgBelatedTime
                pktRcvBelated = [int64]$record.PktRcvBelated
                pktSndDrop = [int64]$record.PktSndDrop
                pktRcvDrop = [int64]$record.PktRcvDrop
                pktRcvUndecrypt = [int64]$record.PktRcvUndecrypt
                byteSent = [int64]$record.ByteSent
                byteRecv = [int64]$record.ByteRecv
                byteRcvLoss = [int64]$record.ByteRcvLoss
                byteRetrans = [int64]$record.ByteRetrans
                byteSndDrop = [int64]$record.ByteSndDrop
                byteRcvDrop = [int64]$record.ByteRcvDrop
                byteRcvUndecrypt = [int64]$record.ByteRcvUndecrypt
                usPktSndPeriod = [int64]$record.UsPktSndPeriod
                pktFlowWindow = [int64]$record.PktFlowWindow
                pktCongestionWindow = [int64]$record.PktCongestionWindow
                pktFlightSize = [int64]$record.PktFlightSize
                msRTT = [single]$record.MsRTT
                mbpsBandwidth = [single]$record.MbpsBandwidth
                byteAvailSndBuf = [int64]$record.ByteAvailSndBuf
                byteAvailRcvBuf = [int64]$record.ByteAvailRcvBuf
                mbpsMaxBW = [single]$record.MbpsMaxBW
                byteMSS = [int64]$record.ByteMSS
                pktSndBuf = [int64]$record.PktSndBuf
                byteSndBuf = [int64]$record.ByteSndBuf
                msSndBuf = [int64]$record.MsSndBuf
                msSndTsbPdDelay = [int64]$record.MsSndTsbPdDelay
                pktRcvBuf = [int64]$record.PktRcvBuf
                byteRcvBuf = [int64]$record.ByteRcvBuf
                msRcvBuf = [int64]$record.MsRcvBuf
                msRcvTsbPdDelay = [int64]$record.MsRcvTsbPdDelay
                pktReorderTolerance = [int64]$record.PktReorderTolerance
                pktSentUnique = [int64]$record.PktSentUnique
                pktRecvUnique = [int64]$record.PktRecvUnique
                byteSentUnique = [int64]$record.ByteSentUnique
                byteRecvUnique = [int64]$record.ByteRecvUnique
                deltaPktRetrans = $deltaPktRetrans
                deltaPktSndLoss = $deltaPktSndLoss
                deltaPktRcvLoss = $deltaPktRcvLoss
                deltaPktSndDrop = $deltaPktSndDrop
                deltaPktRcvDrop = $deltaPktRcvDrop
                deltaPktSent = $deltaPktSent
                deltaPktRecv = $deltaPktRecv
                deltaPctPktLoss = $deltaPctPktLoss
                deltaMsRtt = $deltaMsRtt
            }
        }

        #debug print the metrics to console
        # ConvertTo-Json -InputObject $log | Write-Host
        
        #convert the custom objects to JSON format, and append each object on a single line
        # $body += (ConvertTo-Json -InputObject $index -Compress) + "`n" + (ConvertTo-Json -InputObject $log -Compress) + "`n"
    }

    $global:lastRecords = $records

    return $body
}

while($true) {

    #  Send-TelemetryMessage -body $message

    #  if($enableSrtStatistics) {
         $srtMessage = Get-MVSrtMetricsMessage

         if(![string]::IsNullOrEmpty($srtMessage)) {
             Send-TelemetryMessage -body $srtMessage
         }
    #  }

 Start-Sleep 5    
 }
