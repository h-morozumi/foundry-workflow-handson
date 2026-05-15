// =============================================================================
//  azd から渡される環境変数を main.bicep のパラメータにバインドする。
//  azd は `.azure/<env>/.env` の値を環境変数として CLI に export し、
//  `bicepparam` 内の `readEnvironmentVariable` がそれを読む仕組み。
//
//  リソース グループ自体は azd が `azd up` 時に作成 / 選択する。
//  本ファイルでは RG 名は扱わない (Bicep 側のスコープも resourceGroup)。
// =============================================================================

using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', '')

// 空なら main.bicep 側で `resourceGroup().location` にフォールバックする。
param location        = readEnvironmentVariable('AZURE_LOCATION', '')

// 任意 (空なら main.bicep 側のデフォルト動作)
param principalId       = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param principalType     = readEnvironmentVariable('AZURE_PRINCIPAL_TYPE', 'User')

// チャット モデルを差し替えたい場合は azd env set で上書き可能
//   例: azd env set AZURE_CHAT_MODEL_NAME gpt-5-mini
//       azd env set AZURE_CHAT_MODEL_VERSION 2025-08-07
param chatModelName     = readEnvironmentVariable('AZURE_CHAT_MODEL_NAME', 'gpt-5.4-mini')
param chatModelFormat   = readEnvironmentVariable('AZURE_CHAT_MODEL_FORMAT', 'OpenAI')
param chatModelVersion  = readEnvironmentVariable('AZURE_CHAT_MODEL_VERSION', '2026-03-17')
param chatModelSkuName  = readEnvironmentVariable('AZURE_CHAT_MODEL_SKU', 'GlobalStandard')
param chatModelCapacity = int(readEnvironmentVariable('AZURE_CHAT_MODEL_CAPACITY', '10'))
param chatDeploymentName = readEnvironmentVariable('AZURE_CHAT_DEPLOYMENT_NAME', '')

