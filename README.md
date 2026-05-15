# Microsoft Foundry ワークフロー ハンズオン

**Microsoft Foundry ポータル（[https://ai.azure.com](https://ai.azure.com)）だけで完結する、エージェント / ワークフローのハンズオン集**です。
ブラウザだけあれば進められます（VS Code・Python・ローカル環境セットアップは不要）。

> このページが、ハンズオン全体の **入り口（目次）** です。
> 各ステップの詳細手順は、下の「ハンズオン一覧」のリンク先 README を参照してください。

---

## 🚀 ハンズオン一覧

順番に進めることで、Prompt Agent 単体 → ワークフロー連結 → ループ → ヒューマン・イン・ザ・ループ → 評価
と段階的に Foundry のエージェント機能を体験できます。

| # | ハンズオン | 学べること | 所要時間（目安） |
| --- | --- | --- | --- |
| **STEP1** | [シーケンシャル: 翻訳 → 要約](hands-on/01-translate-summarize/README.md) | Prompt Agent の作り方 / 2 つのエージェントを直列に連結するワークフロー | 約 20 分 |
| **STEP2** | [ループ: 問題作成 × レビュー](hands-on/02-quiz-review-loop/README.md) | データ変換系（`SetVariable`）とフロー系（`ConditionGroup` / `GotoAction`）でループと終了条件を実装 | 約 25 分 |
| **STEP3** | [ヒューマン・イン・ザ・ループ: SNS 投稿レビュー](hands-on/03-human-in-the-loop/README.md) | 基本情報系（`Question` / `SendActivity`）でユーザに確認・修正指示を反映して再生成するパターン | 約 25 分 |
| **STEP4** | [評価: Summarizer をスコアリング](hands-on/04-evaluation/README.md) | Evaluations 機能 / AI 品質エバリュエーター / Eval 駆動で改善するサイクル | 約 30 分 |
| **STEP5** | [カスタム エバリュエーター](hands-on/05-custom-evaluator/README.md) | Code-based / Prompt-based のカスタム評価軸（行数・文字数・前置きの有無）をポータルで作成 | 約 25 分 |

> どの STEP も独立して実施可能ですが、**STEP4 / STEP5 は STEP1 で作る `Summarizer` を題材** にします。
> 初めての方は STEP1 → STEP2 → STEP3 → STEP4 → STEP5 の順がおすすめです。

---

## 📋 前提条件

以下は **事前に完了していること** を前提とします。

- ✅ 有効な **Azure サブスクリプション** を持つ Azure アカウント
- ✅ **Microsoft Foundry プロジェクト** が作成済みであること
  - [https://ai.azure.com](https://ai.azure.com) からプロジェクトを開けること
  - プロジェクトに **チャット用モデル** がデプロイ済みであること（例: `gpt-5-mini`、`gpt-4.1-mini` など）
  - プロジェクトが [ホスト型エージェント対応リージョン](https://learn.microsoft.com/ja-jp/azure/foundry/agents/concepts/hosted-agents#region-availability) にあること
- ✅ 対象 Foundry プロジェクトに **`Azure AI User`** など、エージェント / ワークフローを作成・実行可能な [ロール](https://aka.ms/foundry-ext-project-role) が付与されていること

> Foundry プロジェクトとモデルがまだ無い場合は、本リポジトリ同梱の Bicep で `azd up` 一発で用意できます。次のセクション [🧰 azd でハンズオン環境を構築する (任意)](#-azd-でハンズオン環境を構築する-任意) を参照してください。
> 自分で手作業で作成する場合は、公式ドキュメント [Quickstart: Create a project](https://learn.microsoft.com/azure/foundry/how-to/create-projects) を参照してください。

---

## 🧰 azd でハンズオン環境を構築する (任意)

Foundry プロジェクト・GPT モデル デプロイメントが手元に無い場合、本リポジトリ同梱の Bicep を [`azd`](https://learn.microsoft.com/azure/developer/azure-developer-cli/) で一括プロビジョニングできます。

### 作られるもの

`azd up` 時に **azd が** 環境名 / リージョン / 対象リソース グループをプロンプト (もしくは既存環境から取得) し、その RG の中に Bicep が以下を作ります。

| リソース | 内容 |
| --- | --- |
| Resource Group | **azd が作成 / 選択** (例: `rg-foundry-handson`) |
| **Microsoft Foundry account** (Cognitive Services / `AIServices`) | `allowProjectManagement: true`、System Assigned MI 付き |
| **Microsoft Foundry project** | ハンズオンで利用する論理プロジェクト |
| **GPT モデル デプロイメント** | 既定: `gpt-5.4-mini` (version `2026-03-17`) / `GlobalStandard` / capacity 10 |
| **RBAC ロール割り当て** | 実行ユーザーに `Azure AI User` を付与 (`AZURE_PRINCIPAL_ID` を渡したときのみ) |

> インフラの IaC は [`infra/main.bicep`](infra/main.bicep) (resourceGroup スコープ) と [`infra/modules/foundry.bicep`](infra/modules/foundry.bicep) を参照してください。
> Foundry account / GPT モデルは [Azure Verified Modules](https://aka.ms/avm) (`avm/res/cognitive-services/account`) を利用しています。

### 手順

```bash
# 1) 必要な CLI を準備 (初回のみ)
#    - Azure CLI: https://learn.microsoft.com/cli/azure/install-azure-cli
#    - Azure Developer CLI: https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd

# 2) Azure にサインイン
az login
azd auth login

# 3) リポジトリ ルートで azd up を実行
#    初回はプロンプトで以下を聞かれる:
#      - Environment name        (例: foundry-handson)
#      - Azure subscription
#      - Azure location          (例: eastus2)
#      - Azure resource group    (新規作成 or 既存を選択)
azd up

# (任意) ハンズオン実行ユーザーに自動で `Azure AI User` を割り当てたい場合は、
# 1 度 azd up する前に以下を実行しておく:
#   azd env new foundry-handson
#   azd env set AZURE_PRINCIPAL_ID "$(az ad signed-in-user show --query id -o tsv)"
#   azd up

# (任意) 既定モデルを変えたい場合
#   azd env set AZURE_CHAT_MODEL_NAME    gpt-5-mini
#   azd env set AZURE_CHAT_MODEL_VERSION 2025-08-07
#   azd up
```

完了すると Foundry account / project / モデルが作られ、ポータル ([https://ai.azure.com](https://ai.azure.com)) から開けます。
出力される `AZURE_FOUNDRY_PROJECT_ENDPOINT` などは `.azure/<env-name>/.env` から参照できます。

### クリーンアップ

```bash
azd down --purge --force
```

> `Microsoft.CognitiveServices/accounts` は **論理削除 (soft-delete)** が有効です。`--purge` を付けないと同名で再作成しようとした際に競合します。

### よく使うパラメータ (env 変数)

| 変数 | 既定値 | 用途 |
| --- | --- | --- |
| `AZURE_ENV_NAME` | `azd up` のプロンプトで指定 | リソース名 / タグの suffix |
| `AZURE_LOCATION` | `azd up` のプロンプトで指定 | デプロイ先リージョン (例: `eastus2`, `japaneast`, `swedencentral`) |
| `AZURE_RESOURCE_GROUP` | `azd up` のプロンプトで指定 | 対象 RG (新規作成 or 既存) |
| `AZURE_PRINCIPAL_ID` | 空 | 空でなければ Azure AI User を付与 |
| `AZURE_PRINCIPAL_TYPE` | `User` | `User` / `ServicePrincipal` / `Group` |
| `AZURE_CHAT_MODEL_NAME` | `gpt-5.4-mini` | デプロイするチャット モデル |
| `AZURE_CHAT_MODEL_FORMAT` | `OpenAI` | プロバイダ |
| `AZURE_CHAT_MODEL_VERSION` | `2026-03-17` | モデル バージョン |
| `AZURE_CHAT_MODEL_SKU` | `GlobalStandard` | デプロイ SKU |
| `AZURE_CHAT_MODEL_CAPACITY` | `10` | デプロイ容量 (TPM 単位) |
| `AZURE_CHAT_DEPLOYMENT_NAME` | (空 = モデル名) | ポータル上の deployment 名 |

---

## 🧭 進め方

1. ブラウザで [https://ai.azure.com](https://ai.azure.com) を開き、対象の **Foundry プロジェクト** を選択
2. 上の「ハンズオン一覧」から実施したい STEP の README を開く
3. README の手順に沿って **Prompt Agent → Workflow** の順に作成し、プレイグラウンドで実行
4. 終わったら各 README の **クリーンアップ** セクションに従って後始末

各 STEP の末尾には **「次のステップ」** として発展課題を載せています。

---

## ❓ よくある質問

<details>
<summary><strong>Prompt Agent と Hosted Agent の違いは？</strong></summary>

- **Prompt Agent** … Foundry ポータルで宣言的に作るエージェント。本ハンズオンの対象。
- **Hosted Agent** … Microsoft Agent Framework などでコードを書いて Foundry にデプロイするエージェント。
  本リポジトリでは扱いませんが、将来 SDK サンプルを追加する余地はあります（[AGENTS.md](AGENTS.md) 参照）。

</details>

<details>
<summary><strong>ワークフローは VS Code から作成・編集できますか？</strong></summary>

**現時点では Foundry ポータルからのみ作成・編集可能です。**
VS Code 拡張機能（Foundry Toolkit）からは閲覧 / 実行は可能でも、Workflows の新規作成・編集はサポートされていません。

</details>

<details>
<summary><strong>料金が心配です</strong></summary>

ハンズオンで発生するのは主に **モデル呼び出しの従量課金**（および STEP4 では評価ジョブ実行時の判定モデル呼び出し）です。
小さなテストを数回行う程度であれば多くの場合数十円〜数百円のオーダーですが、念のため
各 STEP の **クリーンアップ** を実施してください。
正確な料金は [Microsoft Foundry の料金ページ](https://azure.microsoft.com/pricing/details/ai-foundry/) を参照してください。

</details>

<details>
<summary><strong>うまく動きません</strong></summary>

各 STEP の README に **トラブルシューティング表** があります。まずはそちらを確認してください。
エラーの詳細は Foundry ポータルの **「Activity」 / 「Run」ログ** を確認すると原因を特定しやすいです。

</details>

---

## 📚 参考リンク

- [Microsoft Foundry ポータル](https://ai.azure.com)
- [Microsoft Foundry エージェント概要](https://learn.microsoft.com/azure/foundry/agents/overview)
- [Microsoft Foundry エージェント ワークフロー概念](https://learn.microsoft.com/azure/foundry/agents/concepts/workflow)
- [Quickstart: Create a prompt agent](https://learn.microsoft.com/azure/foundry/agents/quickstarts/prompt-agent)
- [Evaluation in Microsoft Foundry](https://learn.microsoft.com/azure/foundry/concepts/evaluation-overview)

---

## 🗂 リポジトリ構成

```
foundry-workflow-demo/
├── README.md                                # このファイル（ハンズオン目次）
├── AGENTS.md                                # AI コーディングエージェント向け規約
├── LICENSE                                  # MIT License
├── .gitignore
├── azure.yaml                               # azd プロジェクト定義 (infra のみ)
├── infra/                                   # Bicep IaC (azd up で実行)
│   ├── main.bicep                           # subscription スコープのエントリ
│   ├── main.bicepparam                      # azd env 変数 → Bicep パラメータ
│   ├── abbreviations.json                   # リソース型ごとの略号
│   └── modules/
│       └── foundry.bicep                    # Foundry account + project + GPT モデル
└── hands-on/                                # ポータルで実施するハンズオン本体
    ├── 01-translate-summarize/README.md     # STEP1: シーケンシャル
    ├── 02-quiz-review-loop/README.md        # STEP2: ループ（データ変換 / フロー系コンポーネント）
    ├── 03-human-in-the-loop/README.md       # STEP3: HIL
    ├── 04-evaluation/README.md              # STEP4: 評価
    └── 05-custom-evaluator/README.md        # STEP5: カスタム エバリュエーター
```

---

## 🪪 ライセンス

本リポジトリは [MIT License](LICENSE) の下で提供されます。
