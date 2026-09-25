param(
    [string]$GameRoot = "C:\DuneAwakeningServer",
    [string]$ConfigRoot = "C:\DuneAwakeningServer\Config",
    [string]$SaveRoot = "C:\DuneAwakeningServer\Saves"
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Force -Path $GameRoot | Out-Null
New-Item -ItemType Directory -Force -Path $ConfigRoot | Out-Null
New-Item -ItemType Directory -Force -Path $SaveRoot | Out-Null

Write-Host "Dune server install placeholder."
Write-Host "Install the official dedicated server files from the game publisher or official server distribution method into: $GameRoot"
Write-Host "Place your live config in: $ConfigRoot"
Write-Host "Place world/save data in: $SaveRoot"
Write-Host "Review the game provider documentation for the correct service start command and required ports."
