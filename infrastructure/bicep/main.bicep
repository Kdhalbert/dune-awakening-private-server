@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Name of the VM hosting the dedicated server.')
param vmName string = 'dune-awakening-server'

@description('Admin username for the Windows VM.')
param adminUsername string

@description('Admin password for the Windows VM.')
@secure()
param adminPassword string

@description('Baseline VM size when idle.')
param idleVmSize string = 'Standard_B2s'

@description('Burst VM size when players are active.')
param peakVmSize string = 'Standard_D4s_v5'

@description('Public IP SKU.')
param publicIpSku string = 'Standard'

@description('Budget threshold in USD for monthly cost alerts.')
param monthlyBudgetUSD int = 150

@description('Email address for budget warnings.')
param budgetAlertEmail string = 'you@example.com'

var vnetName = '${vmName}-vnet'
var subnetName = 'default'
var nsgName = '${vmName}-nsg'
var pipName = '${vmName}-pip'
var nicName = '${vmName}-nic'
var osDiskName = '${vmName}-osdisk'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'GamePort'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '7777'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'GamePortUdp'
        properties: {
          priority: 1020
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '7777'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: pipName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower(replace(vmName, '_', '-'))
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: idleVmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        name: osDiskName
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmPublicIp string = pip.properties.ipAddress
output vmFqdn string = pip.properties.dnsSettings.fqdn
output adminUsername string = adminUsername
output idleVmSize string = idleVmSize
output peakVmSize string = peakVmSize
output monthlyBudgetUSD int = monthlyBudgetUSD
output budgetAlertEmail string = budgetAlertEmail
