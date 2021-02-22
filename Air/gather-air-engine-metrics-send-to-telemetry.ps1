﻿#Script to read a Cinegy Air Engine 'metrics' REST API, and then pre-process this data into the format needed for our ElasticSearch dashboards.
#By default, this script will send the telemetry to the Cinegy central telemetry portal - this is not supported for production critical use.

Set-StrictMode -Version Latest

#change these variables depending upon your environment
$telemetryServerUrl = "https://telemetry.cinegy.com"
$OrganizationName="cinegy"
$tags="test,aws-east"
$airengine = "TESTENGINE1"
$airInstance = 0
$channelName = "Test Channel HD1" #friendly name that will appear in dashboard drop-downs and labels
$enableSrtStatistics = $false # SRT stats is only supported in unreleased builds, so defaulted to 'off' in sample script

#don't change these unless you know what you are doing
$IndexName = "airengine"
$Level="Info"
$highTimeTicks = [Int64]0
$engineStartupTimeTicks = [Int64]0
$warmUpPeriodTicks = [Int64](New-TimeSpan -Seconds 10).Ticks

#srt counters for 'periodic' measurements
$lastRecords = $null

function Send-TelemetryMessage([string] $body) {
	#create webclient object, add JSON content-type header, and POST to telemetry server
	$web = new-object net.webclient
	$web.Headers.add("Content-Type", "application/json")
	$web.UploadString("$telemetryServerUrl/_bulk",$body)
}

function Get-AirStartupMessage($StartupTime) {
    #create an object of correct structure to steer the log record in ElasticSearch (this will be first line sent to server)
    $index = [PSCustomObject]@{
        index = [PSCustomObject]@{
            _index = "$IndexName-$OrganizationName-$([System.DateTime]::UtcNow.Year).$([System.DateTime]::UtcNow.Month.ToString("00")).$([System.DateTime]::UtcNow.Day.ToString("00"))"
            }
    }

    $log = [PSCustomObject]@{
        level = $Level
        time = $StartupTime.ToString("O")
        tags = $tags
        host = $airengine
        logger = "PowershellAirTelemetryScript"
        key = "START"
        channelName = $channelName
    }

    $body = (ConvertTo-Json -InputObject $index -Compress) + "`n" + (ConvertTo-Json -InputObject $log -Compress) + "`n"

    return $body
}

function Get-AirTelemetryMessage([ref]$HighWatermarkTime,[ref]$EngineStartupTimeTicks) {
    #create an object of correct structure to steer the log record in ElasticSearch (this will be first line sent to server)
    $index = [PSCustomObject]@{
        index = [PSCustomObject]@{
            _index = "$IndexName-$OrganizationName-$([System.DateTime]::UtcNow.Year).$([System.DateTime]::UtcNow.Month.ToString("00")).$([System.DateTime]::UtcNow.Day.ToString("00"))"
            }
    }

    $telemetry = [xml](Invoke-WebRequest -Uri http://$($airengine):$(5521+$airInstance)/metrics).Content

    $body = ""
    $records = $telemetry.Metrics.At | Sort-Object -Property "Time"

    $EngineStartupTimeTicks.Value = (Get-Date $telemetry.Metrics.StartAt).ToUniversalTime().Ticks
    $cutOffTime = $EngineStartupTimeTicks.Value + $warmUpPeriodTicks

    foreach ($record in $records) {
        $recordTimeTicks = (Get-Date $record.Time).ToUniversalTime().Ticks

        if($recordTimeTicks -gt $HighWatermarkTime.Value ) {
            #don't register any records generated within 10 seconds of engine start time
            if($recordTimeTicks -lt $cutOffTime) {
                Write-Host "Supressing telemetry too near startup..."
                continue
            }
            
            #create an object of minimum structure to send to ElasticSearch (this will be the second line sent to server)
            $log = [PSCustomObject]@{
                level = $Level
                time = $record.Time
                tags = $tags
                host = $airengine
                logger = "PowershellAirTelemetryScript"
                key = "TSD"
                channelName = $channelName
                stats = [PSCustomObject]@{
                    dropped = [int]$($record.DroppedCount)
                    output = [int]$($record.OutputCount)
                    noInput = [int]$($record.NoInputSignal)
                    avgRead = [single]($record.AverageReadTime)
                    readError = [int]($record.ReadErrorRate)
                    heartBeat = [int]($record.Heartbeat)
					timeVariation = [single]$($record.TimeVariation)
					deviceTimeVariation = [single]$($record.DeviceTimeVariation)
                }
            }

            #convert the custom objects to JSON format, and append each object on a single line
            $body += (ConvertTo-Json -InputObject $index -Compress) + "`n" + (ConvertTo-Json -InputObject $log -Compress) + "`n"
            $HighWatermarkTime.Value = $recordTimeTicks
        }
    }

    return $body
}

function Get-AirSrtMetricsMessage() {
    #create an object of correct structure to steer the log record in ElasticSearch (this will be first line sent to server)
    $index = [PSCustomObject]@{
        index = [PSCustomObject]@{
            _index = "$IndexName-$OrganizationName-$([System.DateTime]::UtcNow.Year).$([System.DateTime]::UtcNow.Month.ToString("00")).$([System.DateTime]::UtcNow.Day.ToString("00"))"
            }
    }

    $telemetry = [xml](Invoke-WebRequest -Uri http://$($airengine):$(5521+$airInstance)/metrics/srt).Content
    
    $body = ""
    $queryTime = (Get-Date).ToString("O")

    $records = $telemetry.Connections.Connection | Sort-Object -Property "MsTimeStamp"
    
    if($null -eq $global:lastRecords) { $global:lastRecords = $records }

    foreach ($record in $records) {
        #don't log any stats for localhost connections
        if($record.Key -Match "127.0.0.1") { continue }

        $connectedTime = [TimeSpan]::FromMilliseconds($record.MsTimeStamp)
        Write-Host "Connection $($record.Key) - ($($connectedTime.ToString("dd' days 'hh\:mm\:ss"))) "

        # if($lastPktRetrans[$record.Key] == $null || $lastPktRetrans[$record.Key] -lt $record.pktRetrans) {
        #     $lastPktRetrans[$record.Key] = $record.pktRetrans
        # }

        $deltaPktRetrans = 0
        $deltaPktSndLoss = 0
        $deltaPktRcvLoss = 0
        $deltaMsRtt = 0.0
        #check a few key values to create delta values (more efficient to pre-calc and store than live query)
        foreach ($lastRecord in $global:lastRecords) {
            if($lastRecord.Key -eq $record.Key) {
                $deltaPktRetrans = [int64]$record.PktRetrans - [int64]$lastRecord.PktRetrans
                $deltaPktSndLoss = [int64]$record.PktSndLoss - [int64]$lastRecord.PktSndLoss
                $deltaPktRcvLoss = [int64]$record.PktRcvLoss - [int64]$lastRecord.PktRcvLoss
                $deltaMsRtt = [single]$record.MsRTT - [single]$lastRecord.MsRTT
                break
            }
        }
        
        $global:lastRecords = $records

        #create an object of minimum structure to send to ElasticSearch (this will be the second line sent to server)
        $log = [PSCustomObject]@{
            level = $Level
            time = $queryTime
            tags = $tags
            host = $airengine
            logger = "PowershellAirSrtScript"
            key = "TSD"
            channelName = $channelName
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
                deltaMsRtt = $deltaMsRtt
            }
        }

        #convert the custom objects to JSON format, and append each object on a single line
        $body += (ConvertTo-Json -InputObject $index -Compress) + "`n" + (ConvertTo-Json -InputObject $log -Compress) + "`n"
    }

    return $body
}

while($true) {
    $newEngineStartTimeTicks = $engineStartupTimeTicks
    $message = Get-AirTelemetryMessage -HighWatermarkTime ([ref]$highTimeTicks) -EngineStartupTimeTicks ([ref]$newEngineStartTimeTicks)

    if($newEngineStartTimeTicks -ne $engineStartupTimeTicks)
    {
        if($engineStartupTimeTicks -ne 0) {
            $newEngineStartTime = Get-Date $newEngineStartTimeTicks
            Write-Host "New engine start time: $newEngineStartTime"
            
            $startupMessage = Get-AirStartupMessage -StartupTime $newEngineStartTime
            Send-TelemetryMessage -body $startupMessage
        }

        $engineStartupTimeTicks = $newEngineStartTimeTicks
    }

    Send-TelemetryMessage -body $message

    if($enableSrtStatistics) {
        $srtMessage = Get-AirSrtMetricsMessage

        Send-TelemetryMessage -body $srtMessage
    }

    Start-Sleep 5    
}
