param($provider)

$logger = [Cinegy.Logging.ILogger]$provider.Logger
$logger.Info(" === START Source initialization")

# get the original file path
$originalFilePath = $provider.FilePath
$logger.Info("Original media file: $originalFilePath")

# create default Cinelink
$cinelink = $provider.CreateFromFileAsTracks()

# check that Tracks are present
if($cinelink.Media -is [Cinegy.Cinelink.LinkMediaTracks]) {
    # max audio tracks to preserve in a file
    $maxAudioTracks = 4
    # check the number of audio tracks
    $audioTracks = $cinelink.Media.Audio.Count
    $logger.Info("Available audio tracks: $audioTracks")
    $logger.Info("Max audio tracks to keep: $maxAudioTracks")

    # remove extra tracks if requierd 
    if($audioTracks -gt $maxAudioTracks) {
        $tracksToRemove = $audioTracks - $maxAudioTracks
        $logger.Info("Removing last audio tracks: $tracksToRemove")

        # Remove from the end
        for ($i = 0; $i -lt $tracksToRemove; $i++) {
            $cinelink.Media.Audio.RemoveAt($cinelink.Media.Audio.Count - 1)
        }        
        # return modified cinelink from script
        $cinelink.Details.Location = [System.IO.Path]::GetDirectoryName($originalFilePath);
        $cinelink.Details.Extension = [System.IO.Path]::GetExtension($originalFilePath).Trim('.');
        $cinelink.Details.Name = [System.IO.Path]::GetFileNameWithoutExtension($originalFilePath);
        $cinelink
    } else {
        $logger.Info("Source media has less than $maxAudioTracks audio tracks. Original source will be used instead.")    
    }

} else {
    $logger.Error("Failed to generate Cinelink with Tracks. Original source will be used instead!")
}

$logger.Info(" === END")