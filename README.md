# Dune: Awakening Private Server on Azure

This repository is a GitHub-ready starter for hosting a private Dune: Awakening server on Microsoft Azure.

Important:
- This repo does not contain the game’s proprietary server binaries or official server config format.
- The Azure pieces here handle networking, VM provisioning, cost alerting, and scaling guidance.
- You will still need to install the official dedicated server software from the game publisher or official distribution method and place the final server files on the VM.

## What this repo includes
- Azure infrastructure as code using Bicep
- A Windows VM template sized for low idle cost
- Scaling guidance built around small idle footprint and larger burst capacity
- Budget alerting and Azure Monitor alert scripts
- Example config files and PowerShell automation scripts

## Recommended architecture
For your use case—one-off idle periods with occasional bursts up to 12 players—the best pattern is a single cost-efficient Windows VM that stays small when idle and scales upward only when the server shows sustained load.

Recommended pattern:
- Baseline VM: `Standard_B2s` or `Standard_D2s_v5`
- Peak VM: `Standard_D4s_v5` or similar if your server load spikes
- Scale trigger: CPU above 65% for 10 minutes, then resize upward
- Scale down: CPU below 20% for 30 minutes, then resize downward
- Public IP for admin access and friend connections
- Network Security Group for game ports and RDP
- Azure Disk or Azure Files for persistent server data
- Separate GitHub repo for configuration and automation

This is more practical for a private game server than trying to scale out aggressively across multiple VMs, because the server world state tends to be single-instance and highly stateful.

## Scaling model
The repo includes a scaling script that can be run on a schedule to check host CPU and resize the VM when thresholds are crossed.

Suggested scaling thresholds:
- Idle: low CPU for long periods, keep at smallest VM size
- Burst: when CPU stays above 65% for 10 minutes, move to the next VM tier
- Recovery: once CPU remains below 20% for 30 minutes, scale back down
- Maximum players: 12 players should fit comfortably on a mid-size VM; keep the upper limit conservative to avoid unnecessary cost

## Budget guardrails
You specifically asked for cost visibility, and the repo now includes budget and alert automation.

Recommended budget plan:
- Soft alert at 60% of monthly budget
- Warning alert at 80%
- Critical alert at 100%
- Optional final stop threshold if you want automated shutdown at the top end

The budget alert script creates Azure Monitor actions and cost alerts so you get visibility before a surprise bill.

## Folder structure
- `infrastructure/bicep/` - Azure deployment templates
- `scripts/` - install, scaling, and monitoring scripts
- `configs/` - example configuration files
- `.github/workflows/` - GitHub Actions automation

## Quick start
1. Create a GitHub repo from this folder.
2. Add Azure credentials as GitHub secrets.
3. Review the Bicep template and parameters.
4. Deploy the VM with the PowerShell script.
5. Connect to the VM and install the official dedicated server files.
6. Use the scaling and budget scripts to keep costs controlled.
7. Store all per-server config in this GitHub repo and sync changes to the VM.

## Local environment variables
Keep all real secret values in a local file or shell environment instead of committing them to the repo.

Example local config:

```powershell
$env:DUNE_RESOURCE_GROUP = 'dune-awakening-rg'
$env:DUNE_LOCATION = 'eastus'
$env:DUNE_VM_NAME = 'dune-awakening-server'
$env:DUNE_VM_ADMIN_USERNAME = 'duneadmin'
$env:DUNE_VM_ADMIN_PASSWORD = 'ReplaceWithStrongPassword!123'
$env:AZURE_SUBSCRIPTION_ID = '<subscription-id>'
$env:DUNE_BUDGET_AMOUNT = '150'
$env:DUNE_ALERT_EMAIL = 'you@example.com'
```

You can also save these in a `.env` file and load them with a shell that supports it.

## GitHub secrets needed
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CREDENTIALS`
- `VM_ADMIN_USERNAME`
- `VM_ADMIN_PASSWORD`
- `AZURE_RESOURCE_GROUP`
- `AZURE_LOCATION`

## Azure deployment
Use the included deployment script with environment variables or explicit parameters:

```powershell
cd scripts
./deploy-azure.ps1 -ResourceGroupName $env:DUNE_RESOURCE_GROUP -Location $env:DUNE_LOCATION -VmName $env:DUNE_VM_NAME -AdminUsername $env:DUNE_VM_ADMIN_USERNAME -AdminPassword $env:DUNE_VM_ADMIN_PASSWORD
```

## Scale the server VM
Run the scaling script with your subscription and VM details:

```powershell
cd scripts
./scale-vm.ps1 -SubscriptionId "<subscription-id>" -ResourceGroupName "dune-awakening-rg" -VmName "dune-awakening-server" -TargetSize "Standard_D4s_v5" -MinSize "Standard_B2s" -MaxSize "Standard_D4s_v5"
```

This script checks the VM CPU usage and resizes the VM when thresholds are reached.

## Budget alerts
Create cost-based alerts and an action group with:

```powershell
cd scripts
./setup-budget-alerts.ps1 -SubscriptionId "<subscription-id>" -ResourceGroupName "dune-awakening-rg" -BudgetAmount 150 -ActionGroupName "dune-budget-alerts" -EmailReceiver "you@example.com"
```

This is designed to alert on 60%, 80%, and 100% of the monthly budget threshold.

## Notes for your actual server
Once the VM is running, install the official dedicated server files from the game provider and then point the server config to:
- game install directory
- save directory
- config file directory
- logs directory

Keep the live server config backed up in GitHub using a sync process such as Git pull, a deployment runner, or a simple PowerShell copy script.

## Security guidance
- Do not commit production secrets.
- Use a dedicated admin account.
- Restrict firewall rules to your friend group IP addresses when possible.
- Keep the VM patched and auto-update enabled.
- Set up Azure cost alerts before first deployment, especially if you plan to leave the machine running 24/7.

## Example GitHub workflow
The repo includes a workflow that can deploy the VM and sync config changes from GitHub to the host.

## License
This is sample infrastructure for personal hosting and experimentation. Validate any Azure cost, firewall, and game-server compliance requirements with the relevant provider and hosting policy.
