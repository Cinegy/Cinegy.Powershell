# Cinegy Convert v21.x Source Initialization script

# The script demonstrates simple logo embedding on top of the actual source (clip or sequence from Cinegy Archive or media file)
# The source media is transformed into Timeline XML, then new video track is added on top and simple Logo clip
# is added for the entire duration of the source media. The Logo clip will be stretched to cover the entire vide frame area
# and alpha-blended on top of the source video.

param($provider)

$logger = [Cinegy.Logging.ILogger]$provider.Logger
$logger.Info(" === Source Initialization script START (simple logo)")

# simple logo media file location (defaut is %UserProfile%\Pictures\CinegyLogo.png)
$logoPath = $env:UserProfile + "\Pictures\CinegyLogo.png"

# check if the logo media file actually exists
$logger.Info("Using logo file $logoPath")
if([System.Io.File]::Exists($logoPath) -ne $true)
{
    # terminate the script and report missing logo file
    throw "Failed to locate Logo file: $logoPath"
}

# generate Cinelink with media as TimelineXML
if($null -ne $provider.SourceNode)
{
    # source is Cinegy Archive node defined by $provider.SourceNode
    $sourceNodeId = $provider.SourceNode.Id.Id.ToString()
    $logger.Info("Generating Cinelink from node $sourceNodeId")
    $cinelink = $provider.CreateCinelinkFromNode($sourceNodeId)
}else
{
    # source is media file defined by $provider.FilePath
    $logger.Info("Generating Cinelink from file $($provider.FilePath)")
    $cinelink = $provider.CreateFromFileAsTimeline()
}

# get Cinelink timeline duration
$timeline = $cinelink.Media.Timeline
$duration = $timeline.Duration
	
if([string]::IsNullOrEmpty($duration))
{
    # locate the last clip stop time and use it as a timeline duration
	[double]$maxDuration = 0.0;
	$logger.Info("Timeline duration is not specified. Looking up the last clip in the timeline...")
	foreach($group in $timeline.Group.GetEnumerator())
	{
		foreach($track in $group.Tracks.GetEnumerator())
		{
			foreach($clip in $track.Clips.GetEnumerator())
			{
				[double]$clipDuration = try { $clip.Stop } catch { 0.0 }
				if($clipDuration -gt $maxDuration)
				{
					$maxDuration = $clipDuration
					$duration = $clip.Stop
				}
			}
		}
	}
    $timeline.Duration = $duration
}

$logger.Info("Timeline duration is $duration")
if([string]::IsNullOrEmpty($duration))
{
	throw "Failed to get Cinelink duration to insert Logo!"
}

# create video clip quality that reference the logo file
$logoClipQuality = [Cinegy.MCR.Timeline.TrackStructure.ClipQuality]::new()
$logoClipQuality.Id = "0"
$logoClipQuality.Source = $logoPath

# create new video clip with the specified quality 
$logoClip = [Cinegy.MCR.Timeline.TrackStructure.Clip]::new()
$logoClip.SourceReference = "65535"
$logoClip.Start = "0"
$logoClip.Start = "0"
$logoClip.Stop = $duration
$logoClip.MediaStart = "0"
$logoClip.MediaStop = $duration
$logoClip.QualityTags.Add($logoClipQuality)

# create new transparent video track
$logoTrack = [Cinegy.MCR.Timeline.Track]::new()
$logoTrack.Format = "ARGB32"
$logoTrack.Clips.Add($logoClip)

# add new video track to the existing ones
$videoGroup = $timeline.Group[0]
$videoGroup.Tracks.Add($logoTrack)

# add generated cinelink to script output
$cinelink

$logger.Info(" === Source Initialization script END")
