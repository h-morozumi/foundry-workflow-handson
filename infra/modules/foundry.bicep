// =============================================================================
//  Microsoft Foundry account + project + GPT model deployment
// -----------------------------------------------------------------------------
//  - Foundry account (Cognitive Services kind 'AIServices') は AVM
//    `avm/res/cognitive-services/account` で作成し、`allowProjectManagement` を
//    有効化することで Foundry のプロジェクト機能を使えるようにする。
//  - GPT モデル (デフォルト: gpt-4.1-mini) は AVM の `deployments` 経由で
//    アカウントと同時にデプロイする。
//  - AI Foundry **project** (`Microsoft.CognitiveServices/accounts/projects`) は
//    AVM が未対応のため、本モジュール内で素の Bicep として作成する。
//  - Foundry ポータルでハンズオン (Prompt Agent / Workflow / Evaluation) を
//    実行できるよう、デプロイ実行ユーザーに `Azure AI User` ロールを付与する。
// =============================================================================

metadata description = 'Microsoft Foundry account + project + GPT model deployment for the hands-on demos.'

// -----------------------------------------------------------------------------
//  Parameters
// -----------------------------------------------------------------------------

@description('Required. Foundry account (Cognitive Services / kind AIServices) name. Custom subdomain にも利用される。')
@minLength(2)
@maxLength(64)
param accountName string

@description('Required. Foundry project の論理名。`accountName/projectName` で一意。')
@minLength(2)
@maxLength(64)
param projectName string

@description('Optional. Foundry project のポータル表示名。')
param projectDisplayName string = projectName

@description('Optional. Foundry project の説明文。')
param projectDescription string = 'Project for the Microsoft Foundry hands-on (workflow / agent / evaluation).'

@description('Required. リージョン。Responses API / Foundry agent service が利用できるリージョンを選ぶこと。例: eastus2, japaneast, swedencentral.')
param location string

@description('Optional. 全リソースに付与するタグ。')
param tags object = {}

// ---------- Chat model deployment ----------

@description('Optional. デプロイするチャット用モデル名。')
param chatModelName string = 'gpt-5.4-mini'

@description('Optional. モデルのプロバイダ (format)。')
@allowed([
  'OpenAI'
  'Microsoft'
  'Meta'
  'Mistral AI'
  'Cohere'
  'AI21 Labs'
  'DeepSeek'
  'xAI'
  'Core42'
])
param chatModelFormat string = 'OpenAI'

@description('Optional. モデル バージョン。')
param chatModelVersion string = '2026-03-17'

@description('Optional. デプロイ SKU。')
@allowed([
  'GlobalStandard'
  'DataZoneStandard'
  'Standard'
  'GlobalProvisioned'
  'Provisioned'
])
param chatModelSkuName string = 'GlobalStandard'

@description('Optional. デプロイ容量 (TPM の単位; モデルごとに 1 = 1k TPM 程度)。ハンズオン用に 10 を既定とする。')
@minValue(1)
param chatModelCapacity int = 10

@description('Optional. ポータル上の deployment name。空なら chatModelName を使う。')
param chatDeploymentName string = ''

// ---------- RBAC ----------

@description('Required. ハンズオン実行者 (azd 実行ユーザー) の Entra principal Object ID。空文字を渡すと RBAC 割り当てをスキップ。')
param principalId string

@description('Optional. principalId のタイプ。CI/CD で SP を使う場合は ServicePrincipal にする。')
@allowed([
  'User'
  'ServicePrincipal'
  'Group'
])
param principalType string = 'User'

// -----------------------------------------------------------------------------
//  Variables
// -----------------------------------------------------------------------------

var deploymentName = empty(chatDeploymentName) ? chatModelName : chatDeploymentName

// Built-in role: Azure AI User
//   ハンズオンで Prompt Agent / Workflow / Evaluation を作成・実行できる最小ロール。
//   docs: https://aka.ms/foundry-ext-project-role
var azureAiUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

// -----------------------------------------------------------------------------
//  Foundry account (+ chat model deployment)  via AVM
// -----------------------------------------------------------------------------

module account 'br/public:avm/res/cognitive-services/account:0.14.0' = {
  name: 'foundry-account-deployment'
  params: {
    name: accountName
    location: location
    tags: tags
    kind: 'AIServices'
    sku: 'S0'
    customSubDomainName: accountName
    allowProjectManagement: true
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
    managedIdentities: {
      systemAssigned: true
    }
    deployments: [
      {
        name: deploymentName
        model: {
          format: chatModelFormat
          name: chatModelName
          version: chatModelVersion
        }
        sku: {
          name: chatModelSkuName
          capacity: chatModelCapacity
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
//  Existing reference for sub-resources (project / role assignment)
// -----------------------------------------------------------------------------

resource accountExisting 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: accountName
  dependsOn: [
    account
  ]
}

// -----------------------------------------------------------------------------
//  Foundry project (child of the account)
// -----------------------------------------------------------------------------

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: accountExisting
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectDisplayName
    description: projectDescription
  }
}

// -----------------------------------------------------------------------------
//  RBAC: Foundry account に対し Azure AI User を付与
// -----------------------------------------------------------------------------

resource aiUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: accountExisting
  name: guid(accountExisting.id, principalId, azureAiUserRoleId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiUserRoleId)
  }
}

// -----------------------------------------------------------------------------
//  Outputs (シークレットは含めない)
// -----------------------------------------------------------------------------

@description('Foundry account の ARM resource ID。')
output accountId string = account.outputs.resourceId

@description('Foundry account の名前。')
output accountName string = account.outputs.name

@description('Foundry project の ARM resource ID。')
output projectId string = project.id

@description('Foundry project の名前。')
output projectName string = project.name

@description('Foundry project エンドポイント (例: https://<account>.services.ai.azure.com/api/projects/<project>)。')
output projectEndpoint string = 'https://${accountExisting.name}.services.ai.azure.com/api/projects/${project.name}'

@description('Foundry account / Azure OpenAI 互換エンドポイント (例: https://<account>.openai.azure.com/)。')
output openAiEndpoint string = 'https://${accountExisting.name}.openai.azure.com/'

@description('Foundry Models (AI Inference) エンドポイント (例: https://<account>.services.ai.azure.com/models)。')
output modelsEndpoint string = 'https://${accountExisting.name}.services.ai.azure.com/models'

@description('デプロイしたチャット モデルの deployment 名。アプリ側で `model` パラメータに指定する値。')
output chatDeploymentName string = deploymentName

@description('デプロイしたチャット モデルの名前。')
output chatModelName string = chatModelName
