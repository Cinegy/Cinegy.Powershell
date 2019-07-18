Param([int]$engineCount=1)

$modelXml = 
@"
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<AirEngineConfig Version="2">
	<General InstanceName="Air1" EmbedInstanceName="0" VideoBadFileName="" AudioBadFileName="" ExternalCommandsServer="" IdleColor="#0000FF" MinimumItemLen="500" VideoAccelerator="Direct3D11/0" QueueSize="25" FeedbackCodec="4294901760" ProcessingMode="0" OutBlocks="3"/>
	<StartInLive Enabled="0" LiveTargetAspect="0" AudioMatrixFileName="" AudioMatrixName=""/>
	<SCTE35Generator SplicePrerollMs="4000" Scte104Line="11"/>
	<Licensing BasicProduction="0" BasicAutomaton="0" AdvancedProduction="1" AdvancedAutomaton="1"/>
	<Channels MaxFormat="1920x1080i_25" DropFrame="0">
		<Channel0 Format="1920x1080i_25" ColorInfo="18">
			<Output0 Clsid="{BDDDCDE6-D5C6-4833-B4C4-39DAA9B014A7}" Url="srt://0.0.0.0:6000" MulticastSourceIP="0.0.0.0" MulticastSourceIP2="0.0.0.0" MulticastTTL="1" TSPacketsInRTP="7" RegistrationServer="" OutputID="" ServiceID="1" TransportID="0" PMT_PID="256" PCR_PID="0" SCTE35_PID="0" VideoType="65537" VideoBitrate="4000000" GOPSize="50" GOPPDist="5" ClosedGOP="1" ChromaFormat="0" FrameCodingType="1" VideoPID="4096" AudioStreams="1" AudioStreamInput_0="0" AudioStreamPID_0="4097" AudioStreamType_0="4" AudioStreamBitrate_0="160000" AudioStreamLanguage_0="" H264EntropyCoding="1" AdaptiveGOP="0" TransportRate="0" OP4247_PID="0" CodingWindow="4294967295" RateMode="0" BitDepth="8" ErrorCorrection="0">
				<Prescale Enabled="0" Pixels="1280" Lines="720" HiFps="0" Progressive="1"/>
			</Output0>
		</Channel0>
	</Channels>
	<SCTE35Listener Enabled="0" Url="" IPListenOn="0.0.0.0" OutOffset="0" InOffset="0"/>
	<GFX Mode="2" UseTypeInSeq="1" TypeRootFolder="" NoCGVideo="0"/>
	<AudioInput>
		<S0 Flags="65536" Channels="0;1" Meta="-1" DRC="1"/>
		<S1 Flags="65536" Channels="2;3" Meta="-1" DRC="1"/>
		<S2 Flags="65536" Channels="4;5" Meta="-1" DRC="1"/>
		<S3 Flags="65536" Channels="6;7" Meta="-1" DRC="1"/>
		<S4 Flags="0" Channels="" Meta="-1" DRC="1"/>
		<S5 Flags="0" Channels="" Meta="-1" DRC="1"/>
		<S6 Flags="0" Channels="" Meta="-1" DRC="1"/>
		<S7 Flags="0" Channels="" Meta="-1" DRC="1"/>
	</AudioInput>
	<AudioOutput>
		<S0 Flags="65536" Channels="0;1" Meta="-1"/>
		<S1 Flags="65536" Channels="2;3" Meta="-1"/>
		<S2 Flags="65536" Channels="4;5" Meta="-1"/>
		<S3 Flags="65536" Channels="6;7" Meta="-1"/>
		<S4 Flags="0" Channels="" Meta="-1"/>
		<S5 Flags="0" Channels="" Meta="-1"/>
		<S6 Flags="0" Channels="" Meta="-1"/>
		<S7 Flags="0" Channels="" Meta="-1"/>
	</AudioOutput>
	<Proxy Enabled="0" Folder="C:\CinegyAirProxy" MaximumGb="100" RefreshTime="15000" Compression="4" RenderThreadCount="1" RenderBuffers="8" RenderSpeedLimit="250" IsSpeedLimit="0" IgnoreEOF="0" EnableQualityDegradation="0" MpegFormat="2" UseGPU="0" StampProxyFrames="0" ExtendedLog="0" ForceMPEG2="0" ProxyThreadPriority="Lowest"/>
	<Logging LogFolder="C:\Data\Logs" TraceLevel="5" ErrorLevel="1" RotateFrequency="24" DayStartAt="6" AsRunLogFolder=""/>
	<Events>
		<TitleList Enabled="0" Device="SUBTITLE" Command="LOAD" Op1="" Frequency="5000" Items="3"/>
		<TitleTC Enabled="0" Device="SUBTITLE" Command="TC" Op1="" Frequency="5000" Delay="0"/>
		<EPGList Enabled="0" Device="EPG" Command="LOAD" Op1="" Frequency="5000" Items="3"/>
		<EPGTC Enabled="0" Device="EPG" Command="TC" Op1="" Frequency="5000" Delay="0"/>
		<LiveEnter Enabled="0" Device="" Command="" Op1="" Op2="" Op3=""/>
		<LiveLeave Enabled="0" Device="" Command="" Op1="" Op2="" Op3=""/>
	</Events>
	<GPI Enabled="0" CommercialBitNo="7" CommercialPrerollMs="2000" LiveEnabled="0" LiveBitNo="0" LivePrerollMs="2000"/>
</AirEngineConfig>
"@

New-Item -ItemType Directory -Force -Path C:\ProgramData\Cinegy\CinegyAir\Config\
	
[xml]$profileXml = $modelXml

for($i =0 ; $i -lt $engineCount; $i++ ){
    $profileXml.AirEngineConfig.General.InstanceName = "Air$i"
    $profileXml.AirEngineConfig.Channels.Channel0.Output0.Url = "srt://0.0.0.0:" + (6000 + $i)
    $profileXml.AirEngineConfig.Logging.LogFolder = "C:\Data\Logs\Air$i"
    New-Item -ItemType Directory -Force -Path $profileXml.AirEngineConfig.Logging.LogFolder
    $profileXml.Save("C:\ProgramData\Cinegy\CinegyAir\Config\Instance-$i.Config.xml")
}
