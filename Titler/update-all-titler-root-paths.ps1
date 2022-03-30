# This script takes a folder full of Titler scenes, updates the 'Root Hint' path in the XML to match the containing folder name.

#Requires -Version 7

Param(
    [string]$TitlerDirectory
)

#get all bundles in the 
$titlerScenes = Get-ChildItem -Path $TitlerDirectory -Filter *.CinTitle 

$titlerScenes | ForEach-Object -Process {
    Write-Host "Updating scene $_"
    #load the Cinegy Titler file contents into an XML object for query and update
    $cinTitle = [Xml](Get-Content -Path $_)

    #check to see if a root path is set
    if($null -ne $cinTitle.CinegyTitler.RootFolder){
        #fix up the root hint path in the XML to reference the new targetted directory
        $cinTitle.CinegyTitler.RootFolder.Path = $TitlerDirectory

        #save updated cintitle back to a file in the merged directory
        $cinTitle.Save($_)
    }
}