param(
    [string]$ResourceGroupName = 'dune-awakening-rg',
    [string]$Location = 'eastus',
    [string]$VmName = 'dune-awakening-server',
    [string]$AdminUsername = 'duneadmin',
    [string]$AdminPassword = 'ChangeMeStrongPassword!123',
    [string]$TemplateFile = '../infrastructure/bicep/main.bicep'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is not installed or not on PATH. Install Azure CLI before running this script.'
}

$resolvedTemplate = (Resolve-Path $TemplateFile).Path

az group create --name $ResourceGroupName --location $Location | Out-Null

az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $resolvedTemplate `
    --parameters adminUsername=$AdminUsername adminPassword=$AdminPassword vmName=$VmName location=$Location

Write-Host "Deployment complete."
Write-Host "VM name: $VmName"
Write-Host "Resource group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Next step: connect to the VM and install the official dedicated server software."
