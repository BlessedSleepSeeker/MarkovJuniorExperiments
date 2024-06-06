<#
Created by Camille Gouneau
04 June 2024

.Synopsis
An helper script for executing MarkovJunior then exporting the result as gif if needed. Make sure your model is set with gif="True" !

.Description

.Parameter -OutputFolderName
The name of the subfolder of "output" where the result will be stored.

.Parameter -NoPaletteGen
Disable Automatic FFMPEG Palette Generation from the generated MarkovJunior img.

.Parameter -NoGif
Disable the Gif Generation.

.Parameter -RemovePNG
Remove the png used to generate a gif. This is recommended as the amount of png can quickly take a lot of space.

.Parameter -RemovePaletteAfterUse
Remove the generated palette file after use.

.Parameter -Silent
Do not display subcommands output.

.Example
MarkovJuniorHelper.ps1 -OutputFolderName $(Get-Date -Format "yyyy_MM_dd_HH_mm_ss") -RemovePNG -RemovePaletteAfterUse -Silent
This will create a subfolder with the current datetime.

.Example
MarkovJuniorHelper.ps1 -Clean
This will delete all content inside the $OriginalOutputFolder/, output/ by default

#>

Param(
    [Parameter(Mandatory)] $OutputFolderName,
    $OriginalOutputFolder = "output",
    [switch] $NoPaletteGen,
    [switch] $NoGif,
    [switch] $RemovePNG,
    [switch] $RemovePaletteAfterUse,
    [switch] $Silent,
    [switch] $Clean
)

function prt {
    param (
        [string]$Message,
        [ConsoleColor]$ForegroundColor,
        [ConsoleColor]$BackgroundColor
    )
    $params = @{}
    if ($ForegroundColor) {
        $params.ForegroundColor = $ForegroundColor
    }
    if ($BackgroundColor) {
        $params.BackgroundColor = $BackgroundColor
    }
    Write-Host $Message @params
}

$FullPath = "$OriginalOutputFolder/$OutputFolderName"

if ($Clean) {
    Remove-Item -Path "$OriginalOutputFolder\*" -Recurse
    Exit
}

if (!(Test-Path "$FullPath")) {
    prt "Folder not found at '${FullPath}'. Creating folder..." Yellow Black
    if ($Silent) {
        New-Item -ItemType Directory -Path "$FullPath" | Out-Null
    }
    else {
        New-Item -ItemType Directory -Path "$FullPath"
    }
    
}

prt "Running MarkovJunior..." Yellow Black

if ($Silent) {
    .\MarkovJunior.exe | Out-Null
}
else {
    .\MarkovJunior.exe
}

if (!$NoPaletteGen) {
    prt "Generating Palette..." Yellow Black
    #prt "ffmpeg -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png" Red White
    if ($Silent) {
        ffmpeg -y -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png -hide_banner -loglevel error
    }
    else {
        ffmpeg -y -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png
    }
    prt "Palette generated at '${FullPath}/palette.png !" Green Black
}

if (!$NoGif) {
    prt "Generating GIF..." Yellow Black
    #prt "ffmpeg -framerate 50 -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif" Red White
    if ($Silent) {
        ffmpeg -framerate 50 -y -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif -hide_banner -loglevel error
    }
    else {
        ffmpeg -framerate 50 -y -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif
    }
    prt "GIF generated at '${FullPath}/output.gif" Green Black
}

if ($RemovePNG) {
    prt "Cleaning files in folder $OriginalOutputFolder/..." Yellow Black
    if ($Silent) {
        Remove-Item .\$OriginalOutputFolder\*.png | Out-Null
    }
    else {
        Remove-Item .\$OriginalOutputFolder\*.png
    }
}

if ($RemovePaletteAfterUse) {
    prt "Removing $FullPath/palette.png..." Yellow Black
    if ($Silent) {
        Remove-Item .\$FullPath\palette.png | Out-Null
    }
    else {
        Remove-Item .\$FullPath\palette.png
    }
}
