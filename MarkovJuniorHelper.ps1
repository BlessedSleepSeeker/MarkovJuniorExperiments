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

.Parameter -Silent
Do not display subcommands output

.Example
MarkovJuniorHelper.ps1

.Example
MarkovJuniorHelper.ps1 -OutputFolderName myproject -RemovePNG -Silent

#>

Param(
    [Parameter(Mandatory)] $OutputFolderName,
    $OriginalOutputFolder = "output",
    [switch] $NoPaletteGen,
    [switch] $NoGif,
    [switch] $RemovePNG,
    [switch] $Silent
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

prt $Silent Blue Black

if (!(Test-Path "$FullPath")) {
    prt "Folder not found at '${FullPath}'. Creating folder..." Yellow Black
    New-Item -ItemType Directory -Path "$FullPath"
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
    prt "ffmpeg -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png" Red White
    if ($Silent) {
        ffmpeg -y -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png -hide_banner -loglevel error
    }
    else {
        ffmpeg -y -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png
    }
    prt "Palette generated at '${FullPath}/palette.png" Green Black
}

if (!$NoGif) {
    prt "Generating GIF..." Yellow Black
    prt "ffmpeg -framerate 50 -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif" Red White
    if ($Silent) {
        ffmpeg -framerate 50 -y -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif -hide_banner -loglevel error
    }
    else {
        ffmpeg -framerate 50 -y -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif
    }
    prt "GIF generated at '${FullPath}/output.gif" Green Black
}

if ($RemovePNG) {
    prt "Cleaning files in folder $OriginalOutputFolder/" Yellow Black
    if ($Silent) {
        Remove-Item .\$OriginalOutputFolder\*.png | Out-Null
    }
    else {
        Remove-Item .\$OriginalOutputFolder\*.png
    }
}
