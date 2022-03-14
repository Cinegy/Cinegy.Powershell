param ($SourceFile)

$sourceFileName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile)   
$sourceFileExtension =  [System.IO.Path]::GetExtension($SourceFile)   

$outputFile = "$sourceFileName-Processed$sourceFileExtension"

Write-Output "Cinegy As Run Processing - Input file $SourceFile, run at $(Get-Date)" | Out-File -FilePath $outputFile -Force
$CinegyAsRunCsvHeaders = "Timestamp", "Device", "Event", "Id"

$loglines = Get-Content -Path $SourceFile

foreach($line in $loglines){
    $lineobject = $line | ConvertFrom-Csv -Header $CinegyAsRunCsvHeaders
    $localtime = [DateTime]::SpecifyKind([DateTime]::Parse($lineobject.Timestamp), [DateTimeKind]::Utc).ToLocalTime()
    
    # this optional line causes the log to only print lines related to VIDEO devices with START events
    if(($lineobject.Device -eq "VIDEO") -and ($lineobject.Event -eq "START")) {
        $line.Replace($lineobject.Timestamp, $localtime) | Out-File $outputFile -Append
    }
}