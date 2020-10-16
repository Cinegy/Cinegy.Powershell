#Script to read a Cinegy Air playlist, and gather all referenced clips used into a directory.
#This is useful for moving a playlist example from one system to another.

Param(
    [string]$playlistPath,
    [string]$tempPath="D:\Temp\GatheredItems"    
)

#read the playlist file into an XML object
$playlist = [Xml](Get-Content -Path $playlistPath)

#use an XPath query to get all 'quality' nodes in the XML document
$clipQualities = $playlist | Select-Xml -XPath "/mcrs_playlist/program/block/item/timeline/group/track/clip/quality"

#read the 'src' attribute from these quality nodes and store in a list
$unsortedFiles = foreach ($quality in $clipQualities) { $quality.Node.src }

Write-Host "Found $($unsortedFiles.Count) file path entries in the timelines of the items"

#sort and then filter for unique entries
$uniqueFiles = $unsortedFiles | Sort-Object | Get-Unique

Write-Host "Found $($uniqueFiles.Count) unique file path entries in the source file list"

#ensure that the target directory for storing gathered items exists
New-Item -ItemType Directory -Path $tempPath -ErrorAction SilentlyContinue

#loop through each file, and then check it exists at source
foreach($file in $uniqueFiles) {
    if(Test-Path -Path $file) {
        $fileName = split-path -Path $file -Leaf
        $copyTarget = Join-Path -Path $tempPath -ChildPath $fileName
        
        #now check it actually needs copying - please note, this does not do anything clever like length or mod date checking
        if(Test-Path $copyTarget) {
            Write-Host "Skipping already copied $fileName"
        } else {
            Write-Host "Copying file $fileName"
            Copy-Item -Path $file -Destination $tempPath
        }        
    }
}

#todo - repeat, but for gathering titler events