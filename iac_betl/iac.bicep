param env string = 'dev'

param adfName string = 'adf-betl-${env}'
param location string = 'westeurope'
param gitAccountName string ='basvdberg'
param gitRepositoryName string ='betl'
param gitCollaborationBranch string='develop'
param gitRootFolder string='/adf_betl_getting_started'

param sqlsName string = 'sqls-betl-${env}'
param sqldbBetl string = 'sqldb-betl'
param sqldbAw string = 'sqldb-aw'
param sqldbRdw string = 'sqldb-rdw'

param adminUser string = 'sa_${sqlsName}'
param adminPassword string = 'csd@#54gfrji25rtgfdsvf@#!'

param kv string = 'kv-betl-${env}'
param AzureAdminLogin string = 'Bas van den Berg'
param AzureAdminObjectId string = '9f83c342-ad77-40f7-9a2d-4eac0f45a402'
param connectionStringSqldbBetl string = 'integrated security=False;encrypt=True;connection timeout=30;data source=${sqlsName}${environment().suffixes.sqlServerHostname};initial catalog=${sqldbBetl};user id=${adminUser};password=${adminPassword}'
param connectionStringSqldbAw string = 'integrated security=False;encrypt=True;connection timeout=30;data source=${sqlsName}${environment().suffixes.sqlServerHostname};initial catalog=${sqldbAw};user id=${adminUser};password=${adminPassword}'
param connectionStringSqldbRdw string = 'integrated security=False;encrypt=True;connection timeout=30;data source=${sqlsName}${environment().suffixes.sqlServerHostname};initial catalog=${sqldbRdw};user id=${adminUser};password=${adminPassword}'

var fullAdfName = 'Microsoft.DataFactory/factories/${adfName}'
var tenantId = subscription().tenantId

param ipAddress string = '84.80.150.66'

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

resource kv_res 'Microsoft.KeyVault/vaults@2016-10-01' = {
  name: kv
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
        objectId: reference('${fullAdfName}', '2018-06-01', 'Full').identity.principalId
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
        objectId: AzureAdminObjectId
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

resource kv_connectionStringSqldbBetl 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: kv_res
  name: 'connectionStringSqldbBetl'
  properties: {
    value: connectionStringSqldbBetl
  }
}

resource kv_connectionStringSqldbAw 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: kv_res
  name: 'connectionStringSqldbAw'
  properties: {
    value: connectionStringSqldbAw
  }
}

resource kv_connectionStringSqldbRdw 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: kv_res
  name: 'connectionStringSqldbRdw'
  properties: {
    value: connectionStringSqldbRdw
  }
}

resource sqls_res 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlsName
  location: location
  properties: {
    administratorLogin: adminUser
    administratorLoginPassword: adminPassword
    administrators: {
      administratorType: 'ActiveDirectory'
      azureADOnlyAuthentication: false
      principalType: 'User'
      login: AzureAdminLogin
      sid: AzureAdminObjectId
      tenantId: tenantId
    }

    minimalTlsVersion: '1.2'
    version: '12.0'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

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
    startIpAddress: ipAddress
    endIpAddress: ipAddress
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

