param(
    [string]$ResourceGroupName = $env:DUNE_RESOURCE_GROUP,
    [string]$Location = $env:DUNE_LOCATION,
    [string]$VmName = $env:DUNE_VM_NAME,
    [string]$AdminUsername = $env:DUNE_VM_ADMIN_USERNAME,
    [string]$AdminPassword = $env:DUNE_VM_ADMIN_PASSWORD,
    [string]$TemplateFile = '../infrastructure/bicep/main.bicep'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is not installed or not on PATH. Install Azure CLI before running this script.'
}

if (-not $ResourceGroupName) { throw 'ResourceGroupName is required. Set DUNE_RESOURCE_GROUP or pass -ResourceGroupName.' }
if (-not $Location) { throw 'Location is required. Set DUNE_LOCATION or pass -Location.' }
if (-not $VmName) { throw 'VmName is required. Set DUNE_VM_NAME or pass -VmName.' }
if (-not $AdminUsername) { throw 'AdminUsername is required. Set DUNE_VM_ADMIN_USERNAME or pass -AdminUsername.' }
if (-not $AdminPassword) {
    $AdminPassword = Read-Host 'Enter a strong Windows VM admin password' -AsSecureString
    $AdminPassword = [System.Net.NetworkCredential]::new([string]::Empty, $AdminPassword).Password
}

$resolvedTemplate = (Resolve-Path $TemplateFile).Path

az group create --name $ResourceGroupName --location $Location | Out-Null

az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $resolvedTemplate `
    --parameters adminUsername=$AdminUsername adminPassword=$AdminPassword vmName=$VmName location=$Location

Write-Host 'Deployment complete.'
Write-Host "VM name: $VmName"
Write-Host "Resource group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host 'Next step: connect to the VM and install the official dedicated server software.'
