#Script to read a Cinegy Air playlist, and gather all referenced clips used into a directory.
#This is useful for moving a playlist example from one system to another.

#Requires -Version 7

Param(
    [string]$PlaylistPath,
    [string]$TempMediaPath="D:\Temp\GatheredMediaItems",
    [string]$TempTitlerPath="D:\Temp\GatheredTitlerItems",
    [switch]$DoCopy
)

#read the playlist file into an XML object
$playlist = [Xml](Get-Content -Path $PlaylistPath)

#use an XPath query to get all 'quality' nodes in the XML document
$clipQualities = $playlist | Select-Xml -XPath "/mcrs_playlist/program/block/item/timeline/group/track/clip/quality"

#read the 'src' attribute from these quality nodes and store in a list
$unsortedFiles = foreach ($quality in $clipQualities) { $quality.Node.src }

#sort and then filter for unique entries
$uniqueFiles = $unsortedFiles | Sort-Object | Get-Unique

Write-Host "Found $($unsortedFiles.Count) ($($uniqueFiles.Count) unique) file path entries in the timelines of the items"

#use an XPath query to get all events with a command 'SHOW' against devices starting *GFX_ (Titler) in the XML document
$titlerShowEvents = $playlist | Select-Xml -XPath "/mcrs_playlist/program/block/item/events/event[@cmd='SHOW'][starts-with(@device,'*GFX_')]"

#read the 'op1' node from the titler show events and store in a list
$unsortedTitlerScenes = foreach ($titlerEvents in $titlerShowEvents) { $titlerEvents.Node.op1 }

#sort and then filter for unique entries
$uniqueTitlerScenes = $unsortedTitlerScenes | Sort-Object | Get-Unique

Write-Host "Found $($unsortedTitlerScenes.Count) ($($uniqueTitlerScenes.Count) unique) titler show entries in the playlist items"

#ensure that the target directory for storing gathered items exists
New-Item -ItemType Directory -Path $TempMediaPath -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $TempTitlerPath -ErrorAction SilentlyContinue

#loop through each titler file, and then check it exists at source
foreach($file in $uniqueTitlerScenes) {
    if($DoCopy -and (Test-Path -Path $file)) {
        $fileDirectory = Split-Path -Path $file -Parent
        $fileName = split-path -Path $file -Leaf
        $fileNameBase = split-path -Path $file -LeafBase
        $copyTarget = Join-Path -Path $TempTitlerPath -ChildPath $fileName
        
        #now check it actually needs copying - please note, this does not do anything clever like length or mod date checking
        if(Test-Path $copyTarget) {
            Write-Host "Skipping already copied $fileName"
        } else {
            Write-Host "Copying file $fileName"

            #load the Cinegy Titler file contents into an XML object for query and update
            $cinTitle = [Xml](Get-Content -Path $file)
            $patchedAssetFolderName = "_Assets-$fileNameBase"
            #find all objects with the 'File' attribute and update any bundle-relative paths (refuse to touch paths with macros - could be chaos)
            $nodesWithFileAttrbs = $cinTitle | Select-Xml -XPath "//*[@File][not(contains(@File,'$`{'))]"
            $nodesWithFileAttrbs | ForEach-Object {
                $sourceFileName = Join-Path $fileDirectory $_.Node.File
                $patchedFileName = $_.Node.File.Replace(".\_Assets\",".\$patchedAssetFolderName\")
                $destinationFileName = Join-Path $TempTitlerPath $patchedFileName                
                New-Item -ItemType Directory -Path (Split-Path $destinationFileName -Parent) -ErrorAction SilentlyContinue
                Copy-Item -Path $sourceFileName -Destination $destinationFileName

                $_.Node.File = $patchedFileName
                
            }
                    
            #save updated cintitle back to a file in the merged directory
            $cinTitle.Save($copyTarget)
        }        
    }
}

exit

#loop through each media file, and then check it exists at source
foreach($file in $uniqueFiles) {
    if($DoCopy -and (Test-Path -Path $file)) {
        $fileName = split-path -Path $file -Leaf        
        $copyTarget = Join-Path -Path $TempMediaPath -ChildPath $fileName

        #now check it actually needs copying - please note, this does not do anything clever like length or mod date checking
        if(Test-Path $copyTarget) {
            Write-Host "Skipping already copied $fileName"
        } else {
            Write-Host "Copying file $fileName"
            Copy-Item -Path $file -Destination $TempMediaPath
        }        
    }
}


