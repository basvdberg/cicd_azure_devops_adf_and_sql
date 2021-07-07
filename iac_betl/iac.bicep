param env string = 'dev'

param adfName string = 'adf-betl-dev'
param location string = 'westeurope'
param gitAccountName string ='basvdberg'
param gitRepositoryName string ='infra_as_code'
param gitCollaborationBranch string='develop'
param gitRootFolder string='/'

param sqlsName string = 'sqls-betl-dev'
param sqldbBetl string = 'sqldb-betl'
param sqldbAw string = 'sqldb-aw'
param sqldbRdw string = 'sqldb-rdw'

param keyVaultName string = 'kv-betl-dev'
param keyVaultAdminObjectId string = '9f83c342-ad77-40f7-9a2d-4eac0f45a402'
param connectionStringSqldbBetl string = 'set_by_devops'
param connectionStringSqldbAW string = 'set_by_devops'
param connectionStringSqldbRDW string = 'set_by_devops'

var fullAdfName = 'Microsoft.DataFactory/factories/${adfName}'
var tenantId = subscription().tenantId
var repoConfigurationGit = {
  type: 'FactoryGitHubConfiguration'
  accountName: gitAccountName
  repositoryName: gitRepositoryName
  collaborationBranch: gitCollaborationBranch
  rootFolder: gitRootFolder
}

var emptyRepo = {
  type: 'FactoryVSTSConfiguration'
}
var repoConf = ((toLower(env) == 'dev') ? repoConfigurationGit : emptyRepo ) /* only set git on dev environment */

resource adfName_resource 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adfName
  location: location
  properties: {
    repoConfiguration: repoConf
    globalParameters: {
      Environment: {
        type: 'String'
        value: env
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: {}
}

resource keyVaultName_resource 'Microsoft.KeyVault/vaults@2016-10-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: reference('${fullAdfName}/providers/Microsoft.ManagedIdentity/Identities/default', '2015-08-31-PREVIEW').principalId
        permissions: {
          keys: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
      {
        tenantId: tenantId
        objectId: keyVaultAdminObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'recover'
            'backup'
            'restore'
          ]
          certificates: [
            'get'
            'list'
            'update'
            'create'
            'import'
            'delete'
            'recover'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
          ]
        }
      }
    ]
  }
  dependsOn: [
    adfName_resource
  ]
}

resource keyVaultName_connectionStringSqldbBetl 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVaultName_resource
  name: 'connectionStringSqldbBetl'
  properties: {
    value: connectionStringSqldbBetl
  }
}

resource keyVaultName_connectionStringSqldbAw 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVaultName_resource
  name: 'connectionStringSqldbAw'
  properties: {
    value: connectionStringSqldbAW
  }
}

resource keyVaultName_connectionStringSqldbRdw 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVaultName_resource
  name: 'connectionStringSqldbRdw'
  properties: {
    value: connectionStringSqldbRDW
  }
}

resource sqls_res 'Microsoft.Sql/servers@2021-02-01-preview'={
  name: sqlsName
  location: location
  properties: {
    administratorLogin: 'sa_${sqlsName}'
    administratorLoginPassword: 'csd@#54gfrji25rtgfdsvf@#!'
    minimalTlsVersion: '1.2'
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}
/*
resource sqls_res_admin 'Microsoft.Sql/servers/administrators@2020-11-01-preview' = {
  parent: sqls_res
  name: 'sqls-aad'
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'bas@c2h.nl'
    sid: '9f83c342-ad77-40f7-9a2d-4eac0f45a402'
    tenantId: 'a91d9163-466c-4179-aee2-ef8cb39e4326'
  }
}
*/
/*
resource sqls_res_only_aad 'Microsoft.Sql/servers/azureADOnlyAuthentications@2021-02-01-preview' = {
  parent: sqls_res
  name: 'Default'
  properties: {
    azureADOnlyAuthentication: true
  }
}
*/
resource sqls_res_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  parent: sqls_res
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqls_res_ClientIps 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  name: 'ClientIp-2021-7-7_11-20-29'
  parent: sqls_res
  properties: {
    startIpAddress: '84.80.150.66'
    endIpAddress: '84.80.150.66'
  }
}

resource sqldbAw_res 'Microsoft.Sql/servers/databases@2021-02-01-preview'={
  name : sqldbAw
  location: location
  parent: sqls_res
  properties:{
    sampleName:'AdventureWorksLT'
  }
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5

  }
}

resource sqldbBetl_res 'Microsoft.Sql/servers/databases@2021-02-01-preview'={
  name : sqldbBetl
  location: location
  parent: sqls_res
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}

resource sqldbRdw_res 'Microsoft.Sql/servers/databases@2021-02-01-preview'={
  name : sqldbRdw
  location: location
  parent: sqls_res
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
}
