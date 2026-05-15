# STEP4: エージェントの評価（Evaluation）

これまで作ったエージェントが「**どれくらい良い回答を返しているか**」を、Microsoft Foundry ポータルの
**Evaluations** 機能で定量評価するハンズオンです。

ここでは [STEP1](../01-translate-summarize/README.md) で作った **`Summarizer`** を題材に、
組み込みの **AI 品質エバリュエーター（Relevance / Coherence / Fluency など）** でスコアリングします。

> 評価対象は何でも構いません。`Translator` や [STEP3](../03-human-in-the-loop/README.md) の `post-drafter` でも同じ手順で評価できます。

## 学習ゴール

- 評価用データセット（JSONL）の最小構成を理解する
- ポータルの **Evaluations** から評価ジョブを作成・実行できる
- 組み込みエバリュエーターのスコアと AI 生成のコメントを読み解ける

## 前提条件

- リポジトリ直下の [README.md](../../README.md#前提条件) のセットアップが完了していること
- [STEP1](../01-translate-summarize/README.md) を完了し、`Summarizer` エージェントが動作していること
- 評価用に **GPT 系のチャットモデル** がデプロイされていること（評価器が LLM-as-a-judge のため。例: `gpt-5.4-mini` など）

## 作るもの

| 名前 | 種別 | 役割 |
| --- | --- | --- |
| `summarizer-eval-set.jsonl` | データセット | 評価入力（`query`）と参考解答（`ground_truth`）の組 |
| `summarizer-eval-run-01` | 評価ジョブ | `Summarizer` をデータセットで一括実行しスコアリング |

## 手順

### 1. 評価用データセット（JSONL）を準備する

ハンズオン用のサンプルとして [`summarizer-eval-set.jsonl`](summarizer-eval-set.jsonl) を本ディレクトリに同梱しています。中身は以下のような **1 行 = 1 ケース** の JSON Lines 形式です。

```jsonl
{"query": "Microsoft Foundry はモデル・エージェント・ツール・データを統合した AI アプリ開発プラットフォームで、構築・評価・デプロイを可観測性とガバナンス付きで提供します。プロコードとローコードの両方に対応し、複数の言語で利用できます。", "ground_truth": "- Microsoft Foundry は AI アプリ開発の統合プラットフォーム\n- 可観測性とガバナンス付きで構築・評価・デプロイ可能\n- プロコード / ローコードと複数言語に対応"}
{"query": "GitHub は、複数ファイルにまたがってコードを計画・記述・レビューできる新世代の Copilot を発表しました。エージェントモードでは、与えられたタスクを小さなステップに分解し、開発者の承認を得ながら実行します。プルリクエストとの連携も強化され、失敗したチェックの修正案を自動で提案できます。", "ground_truth": "- 複数ファイルを横断する新世代 Copilot を発表\n- エージェントモードがタスクを分解・承認付きで実行\n- プルリクエスト連携を強化し失敗チェックの修正案を自動提案"}
{"query": "Azure Container Apps は、Kubernetes クラスタを直接管理せずにコンテナワークロードを実行できるサーバーレス基盤です。HTTP・KEDA によるオートスケールや scale-to-zero に対応し、コンテナイメージまたはソースコードからデプロイできます。複数リビジョンへのトラフィック分割や Dapr 統合、マネージド ID もサポートします。", "ground_truth": "- Kubernetes 管理不要のサーバーレスコンテナ基盤\n- HTTP/KEDA オートスケールと scale-to-zero に対応\n- リビジョン分割・Dapr・マネージド ID をサポート"}
```

> `query` は `Summarizer` への入力（要約させたい原文）、`ground_truth` は人手で書いた参考要約です。
> 件数は 3〜10 件あれば十分にハンズオン目的を満たします。
>
> 自分のドメインで試したい場合は、メモ帳など任意のテキストエディタで JSONL ファイルを編集 / 新規作成して差し替えてください（開発環境のセットアップは不要です）。文字コードは BOM 無し UTF-8、改行は LF が安全です。

> データセットは**事前に別途アップロードする必要はありません**。次の手順の**評価ジョブ作成ウィザード内でファイルをそのままアップロード**します。

### 2. 評価ジョブを作成する

1. [https://ai.azure.com](https://ai.azure.com) で対象プロジェクトを開き、**「新しい Foundry」** がオンになっていることを確認
2. 上部メニュー **「ビルド」** → 左メニュー **「評価」** を開く
3. 右上の **「+ 新しい評価」**（**+ New evaluation**）をクリック
4. **評価名**: `summarizer-eval-run-01`
5. **何を評価しますか?**: **エージェント**（Agent）を選択
   - **エージェント**: `Summarizer`
6. **テストデータ**: ウィザード内のデータ選択画面で [`summarizer-eval-set.jsonl`](summarizer-eval-set.jsonl) をその場でアップロード
   - **データセット名**（例）: `summarizer-eval-set`
   - **列マッピング**（次の手順で設定）:
     - **query** → `{{item.query}}`
     - **ground_truth** → `{{item.ground_truth}}`
     - **response** → `{{sample.output_text}}`（エージェント評価の場合は自動で提案される）
   - `response` 列はデータセット側に用意不要です。評価ジョブ実行時に **エージェント (`Summarizer`) が生成** したテキストが `sample.output_text` として取り込まれます。
7. **エバリュエーター**（AI quality / LLM-as-a-judge）を以下から **2〜3 個** 選択:
   - **Relevance** — 出力が入力に対してどれだけ関連しているか
   - **Coherence** — 出力の論理的一貫性
   - **Fluency** — 出力の自然さ
   - **Similarity**（任意） — `ground_truth` との意味的類似度
   - **Groundedness**（任意） — `response` が `context` に基づいているかを評価。要約タスクと相性は良いものの、**`context` 列のマッピングが必須** です。本データセットには `context` 列がないため、選ぶ場合は **列マッピングで `context` → `{{item.query}}`**（要約原文を grounding 元として使う）と設定してください。設定が手間なら、まずは省略して **Similarity** を主役にするのがおすすめです。
8. **判定モデル (Judge model)**: 評価に使う LLM を選択（デプロイ済みの `gpt-5.4-mini` など）
9. **送信 / 作成** で評価ジョブを開始

### 3. 結果を確認する

評価ジョブが完了したら、ジョブをクリックして結果を確認します。

確認するポイント:

- **Aggregate scores**: 各エバリュエーターの平均スコア（1〜5 の 5 段階が一般的）
- **Per-row results**: 各ケースの入力 / 出力 / スコア / 評価コメント
- **低スコアのケース**: なぜ低くなったか、評価器のコメントを読む
  - 例: `Summarizer` が 3 行に収まっていない / 余計な前置きが入っている など

### 4. Instructions を改善して再評価する

低スコアの傾向が見えたら、`Summarizer` の Instructions を強化して **同じデータセットで再度評価** します。

例: 「箇条書き 3 行のみ。前置き禁止。各行は 80 文字以内。」と明確化する。

新しい評価ジョブ名（例: `summarizer-eval-run-02`）で再実行し、スコアの **before / after** を比較します。

> これが LLM 開発における **「Eval 駆動開発」** の最小サイクルです。

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| データセットのアップロードに失敗する | JSONL は **1 行 1 オブジェクト**、改行は LF が安全。BOM 付き UTF-8 は避ける |
| 列マッピングで `query` / `ground_truth` が選べない | データのキー名と一致させる。スキーマプレビューで認識されているか確認 |
| Groundedness 選択時に `context` の列マッピングを求められる | データセットに `context` 列がない場合は **`context` → `{{item.query}}`** にマッピング（要約原文を grounding 元として使う）。あるいは Groundedness を外して Similarity で代替する |
| 評価ジョブが Failed になる | Judge model のクォータ / デプロイ有無を確認。ジョブを実行するプリンシパル（ログインユーザー、またはプロジェクトのマネージド ID）に **判定モデル呼び出し権限**（`Azure AI User` 相当 / `Cognitive Services OpenAI User`）が付与されているかを確認 |
| スコアがすべて満点に近い | データが簡単すぎる可能性あり。少し意地悪な原文（曖昧 / 専門用語多め）を 1〜2 件追加する |

## クリーンアップ

- 評価ジョブ `summarizer-eval-run-01` / `summarizer-eval-run-02`
- データセット `summarizer-eval-set`

## 次のステップ

- [STEP5](../05-custom-evaluator/README.md) で **カスタム エバリュエーター**（Code-based / Prompt-based）を追加し、「3 行ちょうどか」「80 文字以内か」「前置きが無いか」などドメイン固有の観点を測る
- [STEP3](../03-human-in-the-loop/README.md) の `post-drafter` を、別データセット（テーマ → 期待される投稿）で評価する
- ワークフロー全体（`translate-summarize`）を End-to-End で評価し、エージェント単体の品質と比較する
