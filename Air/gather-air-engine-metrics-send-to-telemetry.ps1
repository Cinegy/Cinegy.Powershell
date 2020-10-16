#Script to read a Cinegy Air Engine 'metrics' REST API, and then pre-process this data into the format needed for our ElasticSearch dashboards.
#By default, this script will send the telemetry to the Cinegy central telemetry portal - this is not supported for production critical use.


Set-StrictMode -Version Latest

#change these variables depending upon your environment
$telemetryServerUrl = "https://telemetry.cinegy.com"
$OrganizationName="cinegy"
$tags="test,aws-east"
$airengine = "TESTENGINE1"
$airInstance = 0
$channelName = "Test Channel HD1" #friendly name that will appear in dashboard drop-downs and labels

#don't change these unless you know what you are doing
$IndexName = "airengine"
$Level="Info"
$highTimeTicks = [Int64]0
$engineStartupTimeTicks = [Int64]0
$warmUpPeriodTicks = [Int64](New-TimeSpan -Seconds 10).Ticks

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
    
    Start-Sleep 5    
}
