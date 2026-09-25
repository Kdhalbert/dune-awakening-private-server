param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$VmName,

    [string]$TargetSize = 'Standard_D4s_v5',
    [string]$MinSize = 'Standard_B2s',
    [string]$MaxSize = 'Standard_D4s_v5',
    [int]$ScaleUpCpuThreshold = 65,
    [int]$ScaleDownCpuThreshold = 20,
    [int]$ScaleUpSeconds = 600,
    [int]$ScaleDownSeconds = 1800
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is not installed or not on PATH.'
}

$subscription = az account show --subscription $SubscriptionId 2>$null
if (-not $subscription) {
    az login | Out-Null
}

az account set --subscription $SubscriptionId | Out-Null

$vm = az vm show --resource-group $ResourceGroupName --name $VmName --query "hardwareProfile.vmSize" -o tsv
if (-not $vm) {
    throw "VM '$VmName' was not found in resource group '$ResourceGroupName'."
}

$cpuUsage = az vm monitor metrics tail --resource-group $ResourceGroupName --name $VmName --metric "Percentage CPU" --interval 5m --output json 2>$null | ConvertFrom-Json

if ($cpuUsage -and $cpuUsage.count -gt 0) {
    $latest = $cpuUsage | Sort-Object timestamp | Select-Object -Last 1
    $usage = $latest.average

    if ($usage -gt $ScaleUpCpuThreshold) {
        if ($TargetSize -ne $MaxSize) {
            az vm resize --resource-group $ResourceGroupName --name $VmName --size $MaxSize | Out-Null
            Write-Host "Scaled up $VmName to $MaxSize due to sustained CPU usage: $usage%"
        }
    }
    elseif ($usage -lt $ScaleDownCpuThreshold) {
        if ($TargetSize -ne $MinSize) {
            az vm resize --resource-group $ResourceGroupName --name $VmName --size $MinSize | Out-Null
            Write-Host "Scaled down $VmName to $MinSize due to low CPU usage: $usage%"
        }
    }
    else {
        Write-Host "CPU usage is stable at $usage%; no resize triggered."
    }
}
else {
    Write-Host "No recent CPU metric data available; retaining current VM size."
}

Write-Host "Scale-up threshold: $ScaleUpCpuThreshold%"
Write-Host "Scale-down threshold: $ScaleDownCpuThreshold%"
Write-Host "Current size: $vm"
