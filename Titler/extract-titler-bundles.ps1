# This script takes a folder full of 'bundled' Titler scenes, and extracts them into a target folder.
# It also makes sure that the referenced '_Assets' folder is labelled with the bundle name, to prevent any issues with
# elements sharing a name. It also fixes up the 'Root Hint' path in the XML to the extracted folder.

#Requires -Version 7

Param(
    [string]$SourceBundlesDir,
    [string]$TargetExtractDir
)

#get all bundles in the 
$zips = Get-ChildItem -Path $SourceBundlesDir -Filter *.zip 

$zips | ForEach-Object -Process {
    #extract to a temporary location
    $tmpDir = New-Item -ItemType Directory -Path (Join-Path $([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid()))
    Write-Host "Expanding bundle $($_.Name)"
    Expand-Archive -Path $_ -DestinationPath $tmpDir

    #open the XML of the expected cintitle file name
    $bundleName = $_.BaseName
    $expectedCinTitleFile = $(Join-Path $tmpDir ($bundleName + ".cintitle"))
    $outputCinTitleFile = $(Join-Path $TargetExtractDir ($bundleName + ".cintitle"))
    $patchedAssetFolderName = "_Assets-$bundleName"
    $patchedAssetTargetFolderPath = Join-Path $TargetExtractDir ".\$patchedAssetFolderName"

    #check file exists as expected in bundle
    if(!(Test-Path -Path $expectedCinTitleFile)) {
        Write-Error "ERROR: Unable to locate file $expectedCinTitleFile in bundle; corrupted or incorrectly named bundle (skipped extraction)"
        Remove-Item $tmpDir -Recurse
        return
    }

    #check that the bundle is not already present on the store:
    if((Test-Path $outputCinTitleFile) -or (Test-Path $patchedAssetTargetFolderPath)){
        Write-Error "WARN: Current bundle already extracted - taking no action"
        Remove-Item $tmpDir -Recurse
        return
    }

    #load the Cinegy Titler file contents into an XML object for query and update
    $cinTitle = [Xml](Get-Content -Path $expectedCinTitleFile)

    #find all objects with the 'File' attribute and update any bundle-relative paths (refuse to touch paths with macros - could be chaos)
    $nodesWithFileAttrbs = $cinTitle | Select-Xml -XPath "//*[@File][not(contains(@File,'$`{'))]"
    $nodesWithFileAttrbs | ForEach-Object {
        $_.Node.File = $_.Node.File.Replace(".\_Assets\",".\$patchedAssetFolderName\")
    }

    #fix up the root hint path in the XML to reference the new targetted directory
    $cinTitle.CinegyTitler.RootFolder.Path = $TargetExtractDir

    #todo: query any variable values to see if these are used and warn
    #Since bundling would break this value anyway and should be warned it may not be fixable

    #save updated cintitle back to a file in the merged directory
    $cinTitle.Save($outputCinTitleFile)
	
    #create the bundle-named assets directory and copy in source assets
    New-Item -ItemType "directory" -Path $patchedAssetTargetFolderPath
    Copy-Item -Recurse -Path "$tmpDir\_Assets\*" -Destination $patchedAssetTargetFolderPath

    #clean up tmpdir used for extraction
    Remove-Item $tmpDir -Recurse
}

