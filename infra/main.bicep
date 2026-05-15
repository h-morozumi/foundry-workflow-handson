// =============================================================================
//  Microsoft Foundry ハンズオン デモ用 Azure インフラ (azd エントリ ポイント)
// -----------------------------------------------------------------------------
//  リソース グループ スコープでデプロイする。
//  リソース グループ自体は **azd** が `azd up` (= `azd provision`) 実行時に
//  プロンプトで作成 (もしくは既存を選択) し、本テンプレートはそのリソース
//  グループの中に Foundry account / project / GPT モデルを配置する。
//
//  デプロイ方法:
//    azd auth login
//    azd init                        # 初回のみ (azure.yaml をスキャン)
//    azd up                          # 環境名 / リージョン / RG をプロンプト
//
//  既に環境を作っている場合:
//    azd env new <env-name>
//    azd env set AZURE_LOCATION eastus2
//    azd up
// =============================================================================

targetScope = 'resourceGroup'

metadata description = 'Provision the Microsoft Foundry account, project, and GPT model deployment used by the hands-on labs.'

// -----------------------------------------------------------------------------
//  Parameters
// -----------------------------------------------------------------------------

@maxLength(32)
@description('Required. azd の環境名。リソース名 / タグの suffix に使う (azd が AZURE_ENV_NAME から渡す)。')
param environmentName string

@description('Optional. リソースのデプロイ先リージョン。既定は所属リソース グループのリージョン。Responses API と Foundry agent service が両方サポートされている必要がある (例: eastus2, japaneast, swedencentral)。')
param location string = resourceGroup().location

@description('Optional. ハンズオン実行者 (azd 実行ユーザー) の Entra principal Object ID。空なら RBAC 割り当てをスキップ。')
param principalId string = ''

@allowed([
  'User'
  'ServicePrincipal'
  'Group'
])
@description('Optional. principalId のタイプ。CI/CD で SP を使う場合は ServicePrincipal にする。')
param principalType string = 'User'

// ---------- Chat model parameters (foundry.bicep へ素通し) ----------

@description('Optional. デプロイするチャット用モデル名。')
param chatModelName string = 'gpt-5.4-mini'

@description('Optional. モデルのプロバイダ (format)。')
param chatModelFormat string = 'OpenAI'

@description('Optional. モデル バージョン。')
param chatModelVersion string = '2026-03-17'

@description('Optional. デプロイ SKU。')
param chatModelSkuName string = 'GlobalStandard'

@description('Optional. デプロイ容量。ハンズオンなら 10 で十分。')
@minValue(1)
param chatModelCapacity int = 10

@description('Optional. デプロイ名。空なら chatModelName と同一。')
param chatDeploymentName string = ''

// -----------------------------------------------------------------------------
//  Variables
// -----------------------------------------------------------------------------

var abbrs = loadJsonContent('./abbreviations.json')

// `uniqueString` で衝突しにくいトークンを作る (azd 標準パターン)。
// resourceGroup スコープなので RG ID を seed にする。
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

// Foundry account 名は customSubDomain として URL に出るので英数小文字のみに揃える。
var accountName = take('${abbrs.aiFoundryAccount}${resourceToken}', 32)
var projectName = take('${abbrs.aiFoundryProject}${environmentName}', 32)

var commonTags = {
  'azd-env-name': environmentName
  workload: 'foundry-workflow-demo'
  environment: environmentName
}

// -----------------------------------------------------------------------------
//  Foundry account / project / model deployment
// -----------------------------------------------------------------------------

module foundry './modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    accountName: accountName
    projectName: projectName
    projectDisplayName: 'Foundry Hands-on (${environmentName})'
    projectDescription: 'Project provisioned by azd for the foundry-workflow-demo hands-on.'
    location: location
    tags: commonTags
    chatModelName: chatModelName
    chatModelFormat: chatModelFormat
    chatModelVersion: chatModelVersion
    chatModelSkuName: chatModelSkuName
    chatModelCapacity: chatModelCapacity
    chatDeploymentName: chatDeploymentName
    principalId: principalId
    principalType: principalType
  }
}

// -----------------------------------------------------------------------------
//  Outputs (azd は output を `.env` に書き出してくれる)
// -----------------------------------------------------------------------------

@description('リソース グループ名。')
output AZURE_RESOURCE_GROUP string = resourceGroup().name

@description('リージョン。')
output AZURE_LOCATION string = location

@description('Foundry account の名前。')
output AZURE_FOUNDRY_ACCOUNT_NAME string = foundry.outputs.accountName

@description('Foundry project の名前。')
output AZURE_FOUNDRY_PROJECT_NAME string = foundry.outputs.projectName

@description('Foundry project エンドポイント (Agents / Workflows / Evaluations の SDK で使う)。')
output AZURE_FOUNDRY_PROJECT_ENDPOINT string = foundry.outputs.projectEndpoint

@description('Azure OpenAI 互換エンドポイント。')
output AZURE_OPENAI_ENDPOINT string = foundry.outputs.openAiEndpoint

@description('Foundry Models (AI Inference) エンドポイント。')
output AZURE_AI_MODELS_ENDPOINT string = foundry.outputs.modelsEndpoint

@description('チャット モデルの deployment 名。')
output AZURE_OPENAI_CHAT_DEPLOYMENT string = foundry.outputs.chatDeploymentName

@description('チャット モデル名。')
output AZURE_OPENAI_CHAT_MODEL string = foundry.outputs.chatModelName
