param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [string]$BudgetAmount = '150',
    [string]$ActionGroupName = 'dune-budget-alerts',
    [string]$EmailReceiver = 'you@example.com'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is not installed or not on PATH.'
}

az account set --subscription $SubscriptionId | Out-Null

$actionGroupId = az monitor action-group create `
    --name $ActionGroupName `
    --resource-group $ResourceGroupName `
    --action email $EmailReceiver $EmailReceiver `
    --query "id" -o tsv

$thresholds = @(60, 80, 100)

foreach ($threshold in $thresholds) {
    $alertName = "dune-budget-$threshold-percent"
    $startDate = (Get-Date).ToString('yyyy-MM-dd')

    az consumption budget create `
        --name $alertName `
        --scope "/subscriptions/$SubscriptionId" `
        --amount $BudgetAmount `
        --time-grain Monthly `
        --category Cost `
        --start-date $startDate `
        --notifications "{""category"":""Cost"",""enabled"":""true"",""operator"":""GreaterThanOrEqualTo"",""threshold"":""$threshold"",""contactEmails"":""$EmailReceiver""}" | Out-Null

    Write-Host "Created budget alert for $threshold% of monthly budget."
}

Write-Host "Action group created: $actionGroupId"
Write-Host "Budget alerts configured for $BudgetAmount USD."
