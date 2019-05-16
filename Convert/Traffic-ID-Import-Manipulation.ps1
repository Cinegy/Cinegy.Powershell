param($provider)

# -------------------------------------------------------
# Helper functions - see below for the MAIN code
# -------------------------------------------------------

# 
# dump all available script metadata
#
function Cinegy-DumpProviderMetadata($Provider, $Logger)
{
    #log message about function start
    $Logger.Info(" == Cinegy-DumpProviderMetadata == ")

    # ensure provider is ready to serve files list
    if ([bool]($Provider.PSObject.Methods.Name -match "QueryFiles"))
    {
        # get the list of files created
        # NOTE: in general case the task can have multiple targets that can have multiple output destinations
        # therefore we loop through all returned items. In the simple case there will be just one file in the list
        $files = $Provider.QueryFiles();

        $Logger.Info("Files:")
        foreach($fileMetadataSet in $files)
        {
            # each returned file set can have multiple properties, output all of them
            foreach($fileMateadata in $fileMetadataSet.GetEnumerator())
            {
                $Logger.Info("  $($fileMateadata.Key): $($fileMateadata.value)")
            }
        }
    }

    # dump all available metadata items for the task
    $Logger.Info("Metadata:")
    foreach($metadata in $Provider.Metadata.GetEnumerator())
    {
        $Logger.Info("  $($metadata.Key): $($metadata.value)")
    }

    $Logger.Info(" ==== ")
}

# 
# Add custom metadata to be used as macro
#
function Cinegy-SetTrafficId($Provider, $Logger)
{
    #log message about function start
    $Logger.Info(" == Cinegy-SetTrafficId == ")

    #check if traffic ID is already defined in metadata (e.g. via CinegyLink file) - this system field uses internal database name
    if($Provider.Metadata.ContainsKey("src.meta.traffic_programm_id"))
    {
        $Logger.Info("Traffic ID is already defined {src.meta.traffic_programm_id}: " + $Provider.Metadata['src.meta.traffic_programm_id'])
    }
    else {
        #initialize TrafficId with source file name (using macro which excludes file name extension)
	    $TrafficId = $Provider.Metadata['src.shortname']
	    $Logger.Info("Traffic ID is set to {src.shortname}: " + $TrafficId)

        #remove example postfix value from the Traffic ID if any is set
        $postfixToRemove = "V1"
        if($TrafficId.ToUpper().EndsWith($postfixToRemove))
        {
            $TrafficId = $TrafficId.SubString(0, $TrafficId.Length-$postfixToRemove.Length)
            $Logger.Info("$postfixToRemove is removed from Traffic ID: " + $TrafficId)
        }

        #register Traffic ID value in source metadata
        $Provider.AddMetadata('src.meta.traffic_programm_id', $TrafficId)	
        $Logger.Info("Traffic ID added to metadata with name {src.meta.traffic_programm_id}: " + $Provider.Metadata['src.meta.traffic_programm_id'])
    }

    $Logger.Info(" ==== ")
}


# -------------------------------------------------------
# MAIN
# -------------------------------------------------------

# get logger instance to add information directly into task log

$logger = [Cinegy.Logging.ILogger]$provider.Logger
$logger.Info(" === Pre-Processing Traffic ID Import Script - START")

# Set the traffic ID
Cinegy-SetTrafficId -Provider $provider -Logger $logger

# Dump all available metadata (useful to verify behaviour - safe to comment in production)
Cinegy-DumpProviderMetadata -Provider $provider -Logger $logger