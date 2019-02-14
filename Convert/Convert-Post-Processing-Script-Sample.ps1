param($provider)

# -------------------------------------------------------
# Helper functions - see below for the MAIN code
# -------------------------------------------------------

# 
# dump all available script metadata
#
function Cinegy-DumpProviderMetadata($provider, $logger)
{
    #log message about function start
    $logger.Info(" == Cinegy-DumpProviderMetadata == ")

    # ensure provider is ready to serve files list
    if ([bool]($provider.PSObject.Methods.Name -match "QueryFiles"))
    {
        # get the list of files created
        # NOTE: in general case the task can have multiple targets that can have multiple output destinations
        # therefore we loop through all returned items. In the simple case there will be just one file in the list
        $files = $provider.QueryFiles();

        $logger.Info("Files:")
        foreach($fileMetadataSet in $files)
        {
            # each returned file set can have multiple properties, output all of them
            foreach($fileMateadata in $fileMetadataSet.GetEnumerator())
            {
                $logger.Info("  $($fileMateadata.Key): $($fileMateadata.value)")
            }
        }
    }

    # dump all available metadata items for the task
    $logger.Info("Metadata:")
    foreach($metadata in $provider.Metadata.GetEnumerator())
    {
        $logger.Info("  $($metadata.Key): $($metadata.value)")
    }

    $logger.Info(" ==== ")
}

# 
# move created files into new folder
#
function Cinegy-MoveOutputFiles($provider, $logger)
{
    #log message about function start
    $logger.Info(" == Cinegy-MoveOutputFiles == ")

    # ensure provider is ready to serve files list
    if ([bool]($provider.PSObject.Methods.Name -match "QueryFiles"))
    {
        # get the list of files created
        # NOTE: in general case the task can have multiple targets that can have multiple output destinations
        # therefore we loop through all returned items. In the simple case there will be just one file in the list
        $files = $provider.QueryFiles();

        #iterate through each created file and move it into the new folder
        foreach($fileMetadataSet in $files)
        {
            # get file metadata
            $path = $fileMetadataSet["dst.location"]
            $name = $fileMetadataSet["dst.name"]
            $extension = $fileMetadataSet["dst.extension"]

            #generate original file path
            $OriginalOutputFilePath = [io.path]::combine($path, $name + $extension)
            #new destination folder "GeneratedFiles" to move files into
            $newTargetFolder = [io.path]::combine($path, "GeneratedFiles")

            $logger.Info("Moving file '$OriginalOutputFilePath' to '$newTargetFolder' ...")
            Move-Item -Path $OriginalOutputFilePath -Destination $newTargetFolder -Force
        }
    }

    $logger.Info(" ==== ")
}


# -------------------------------------------------------
# MAIN
# -------------------------------------------------------

# get logger instance to add information directly into task log

$logger = [Cinegy.Logging.ILogger]$provider.Logger
$logger.Info(" === Post-Processing script - START")

# Sample #1 - dump all available metadata
Cinegy-DumpProviderMetadata $provider $logger

# Sample #2 - move created files
Cinegy-MoveOutputFiles $provider $logger

$logger.Info(" === Post-Processing script - END")



