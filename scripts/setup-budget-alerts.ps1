param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = $env:DUNE_RESOURCE_GROUP,
    [string]$BudgetAmount = $env:DUNE_BUDGET_AMOUNT,
    [string]$ActionGroupName = 'dune-budget-alerts',
    [string]$EmailReceiver = $env:DUNE_ALERT_EMAIL
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw 'Azure CLI (az) is not installed or not on PATH.'
}

if (-not $SubscriptionId) { throw 'SubscriptionId is required. Set AZURE_SUBSCRIPTION_ID or pass -SubscriptionId.' }
if (-not $ResourceGroupName) { throw 'ResourceGroupName is required. Set DUNE_RESOURCE_GROUP or pass -ResourceGroupName.' }
if (-not $BudgetAmount) { throw 'BudgetAmount is required. Set DUNE_BUDGET_AMOUNT or pass -BudgetAmount.' }
if (-not $EmailReceiver) { throw 'EmailReceiver is required. Set DUNE_ALERT_EMAIL or pass -EmailReceiver.' }

az account set --subscription $SubscriptionId | Out-Null

$actionGroupId = az monitor action-group create `
    --name $ActionGroupName `
    --resource-group $ResourceGroupName `
    --action email $EmailReceiver $EmailReceiver `
    --query 'id' -o tsv

$thresholds = @(60, 80, 100)

foreach ($threshold in $thresholds) {
    $alertName = "dune-budget-$threshold-percent"
    $startDate = (Get-Date).ToString('yyyy-MM-dd')

    $notificationJson = @{
        category = 'Cost'
        enabled = 'true'
        operator = 'GreaterThanOrEqualTo'
        threshold = [string]$threshold
        contactEmails = @($EmailReceiver)
    } | ConvertTo-Json -Compress

    az consumption budget create `
        --name $alertName `
        --scope "/subscriptions/$SubscriptionId" `
        --amount $BudgetAmount `
        --time-grain Monthly `
        --category Cost `
        --start-date $startDate `
        --notifications $notificationJson | Out-Null

    Write-Host "Created budget alert for $threshold% of monthly budget."
}

Write-Host "Action group created: $actionGroupId"
Write-Host "Budget alerts configured for $BudgetAmount USD."
