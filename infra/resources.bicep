@description('Location for all resources')
param location string

@description('Resource token for unique naming')
param resourceToken string

@description('Complete tags with cost-center and owner')
param tagsComplete object

@description('Incomplete tags missing cost-center and owner')
param tagsIncomplete object

// ============================================================================
// VIRTUAL NETWORK (shared)
// ============================================================================
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'vnet-${resourceToken}'
  location: location
  tags: tagsComplete
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-vms'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// ============================================================================
// VM 1: Idle/Underutilized VM (SRE Agent should detect low CPU)
// ============================================================================
resource nic1 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-idle-vm-${resourceToken}'
  location: location
  tags: tagsComplete
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm1 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'vm-idle-${resourceToken}'
  location: location
  tags: tagsComplete
  properties: {
    // ⚠️ OVERSIZED: D2s_v3 for an idle workload
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id
        }
      ]
    }
    osProfile: {
      computerName: 'vm-idle'
      adminUsername: 'azureuser'
      adminPassword: 'P@ssw0rd1234!'  // Demo only - use Key Vault in production
    }
  }
}

// ============================================================================
// VM 2: Another idle VM (demonstrates pattern of waste)
// ============================================================================
resource nic2 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'nic-batch-vm-${resourceToken}'
  location: location
  tags: tagsComplete
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm2 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'vm-batch-${resourceToken}'
  location: location
  tags: tagsComplete
  properties: {
    // ⚠️ OVERSIZED: D4s_v3 sitting idle
    hardwareProfile: {
      vmSize: 'Standard_D4s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id
        }
      ]
    }
    osProfile: {
      computerName: 'vm-batch'
      adminUsername: 'azureuser'
      adminPassword: 'P@ssw0rd1234!'
    }
  }
}

// ============================================================================
// ORPHANED DISK (not attached to any VM - SRE Agent should detect)
// ============================================================================
resource orphanedDisk 'Microsoft.Compute/disks@2023-04-02' = {
  name: 'disk-orphaned-${resourceToken}'
  location: location
  // ⚠️ INTENTIONALLY MISSING TAGS
  tags: tagsIncomplete
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 128
  }
}

// Another orphaned disk
resource orphanedDisk2 'Microsoft.Compute/disks@2023-04-02' = {
  name: 'disk-backup-old-${resourceToken}'
  location: location
  tags: tagsIncomplete
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 256
  }
}

// ============================================================================
// STORAGE ACCOUNTS - Some with missing tags
// ============================================================================

// Properly tagged storage
resource storageTagged 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'sttagged${resourceToken}'
  location: location
  tags: tagsComplete
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// ⚠️ MISSING TAGS: cost-center and owner
resource storageUntagged1 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stuntagged1${resourceToken}'
  location: location
  tags: tagsIncomplete
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource storageUntagged2 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stuntagged2${resourceToken}'
  location: location
  // ⚠️ NO TAGS AT ALL
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// ============================================================================
// APP SERVICE: Working web app connected to resources
// ============================================================================
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'plan-${resourceToken}'
  location: location
  tags: tagsComplete
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: 'app-${resourceToken}'
  location: location
  tags: union(tagsComplete, {
    'azd-service-name': 'api'
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      appSettings: [
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storageTagged.name
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
    httpsOnly: true
  }
}

// Grant App Service access to Storage
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageTagged.id, webApp.id, storageBlobDataContributorRoleId)
  scope: storageTagged
  properties: {
    principalId: webApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================
output vm1Name string = vm1.name
output vm2Name string = vm2.name
output orphanedDiskName string = orphanedDisk.name
output untaggedStorageName string = storageUntagged1.name
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
