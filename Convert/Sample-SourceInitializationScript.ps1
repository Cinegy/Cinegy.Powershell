param($provider)

$logger = [Cinegy.Logging.ILogger]$provider.Logger
$logger.Info(" === START")

# folder to look for the additional audio files

$audioFilesFolder = "C:\Users\Public\Videos"
$audioFilesMask = "_Audio*.wav"

$logger.Info("Audio files folder: $audioFilesFolder")

# create default Cinelink
$cinelink = $provider.CreateFromFile()

# replace Media with Tracks
$cinelink.Media = [Cinegy.Cinelink.LinkMediaTracks]::new()

# get the original file path
$originalFilePath = $provider.FilePath
$logger.Info("Original media file: $originalFilePath")

# add original video track
$videoTrack = [Cinegy.Cinelink.LinkMediaTrack]::new()
$videoTrack.Location = $originalFilePath
$cinelink.Media.Video.Add($videoTrack)

# add original audio track
$audioTrack = [Cinegy.Cinelink.LinkMediaTrack]::new()
$audioTrack.Location = $originalFilePath
$cinelink.Media.Audio.Add($audioTrack)

# search and add additional audio tracks starting from the second track
$audioOrder = 1
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($originalFilePath)
$audioFilesMask = $fileName + $audioFilesMask

$audioFiles = [System.IO.Directory]::EnumerateFiles($audioFilesFolder, $audioFilesMask)
foreach($file in $audioFiles)
{
	$logger.Info("Additional audio track # $audioOrder : $file")
	
	$audioTrack = [Cinegy.Cinelink.LinkMediaTrack]::new()
	$audioTrack.Location = $file
	$audioTrack.Order = $audioOrder
	$cinelink.Media.Audio.Add($audioTrack)
	++$audioOrder
}

# return result from script
$cinelink

$logger.Info(" === END")
