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
    $TakeEach = 1,
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
$CreateDirCommand = "New-Item -ItemType Directory -Path '$FullPath\'"
$RunMarkovCommand = ".\MarkovJunior.exe"
$ffmpegPaletteCommand = "ffmpeg -y -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png"
$ffmpegGifCommand = "ffmpeg -framerate 50 -y -i '$OriginalOutputFolder/%d.png' -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif"

if ($Clean) {
    Remove-Item -Path "$OriginalOutputFolder\*" -Recurse
    Exit
}

if (!(Test-Path "$FullPath")) {
    prt "Folder not found at '${FullPath}'. Creating folder..." Yellow Black
    if ($Silent) {
        $CreateDirCommand = "$CreateDirCommand | Out-Null"
    }
    Invoke-Expression $CreateDirCommand
}

prt "Running MarkovJunior..." Yellow Black

if ($Silent) {
    $RunMarkovCommand = "$RunMarkovCommand | Out-Null"
}
Invoke-Expression $RunMarkovCommand

if (!$NoPaletteGen) {
    prt "Generating Palette..." Yellow Black
    #prt "ffmpeg -i $OriginalOutputFolder/0.png -vf palettegen $FullPath/palette.png" Red White
    if ($Silent) {
        $ffmpegPaletteCommand = "$ffmpegPaletteCommand -hide_banner -loglevel error"
    }
    Invoke-Expression $ffmpegPaletteCommand
    prt "Palette generated at '${FullPath}/palette.png !" Green Black
}

# Delete some files. If take each is at 2, every odd file will be deleted. If TakeEach is at 3, only 0.png, 3.png, 6.png are left afterwards...

$FinalFrame = $(Get-ChildItem $OriginalOutputFolder -File | Sort-Object -Descending {[int]($_.basename -replace '\D')} | Select-Object -First 1)

if ($TakeEach -gt 1) {
    $count = $TakeEach
    prt $TakeEach Red Black
    foreach ($file in $(Get-ChildItem $OriginalOutputFolder -File | Sort-Object {[int]($_.basename -replace '\D')})) {
        if ($count -eq $TakeEach) {
            $count = 0
        }
        else {
            if ("$file" -ne "$FinalFrame") {
                prt $file Red Black
                Remove-Item $OriginalOutputFolder/$file
            }
        }
        $count = $count + 1
    }
}

# Rename the file to make them following (can't use wildcard matching on windows)

$NewInt = 0
foreach ($file in $(Get-ChildItem $OriginalOutputFolder -File | Sort-Object {[int]($_.basename -replace '\D')})) {
    Rename-Item "$OriginalOutputFolder/$file" "$NewInt.png"
    $NewInt = $NewInt + 1
}

if (!$NoGif) {
    prt "Generating GIF..." Yellow Black
    #prt "ffmpeg -framerate 50 -i $OriginalOutputFolder/%d.png -i $FullPath/palette.png -lavfi paletteuse -sws_dither none -loop -1 $FullPath/output.gif" Red White
    if ($Silent) {
        $ffmpegGifCommand = "$ffmpegGifCommand -hide_banner -loglevel error"
    }
    Invoke-Expression $ffmpegGifCommand
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
