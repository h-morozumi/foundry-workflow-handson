# STEP5: カスタム エバリュエーター（Custom Evaluator）

[STEP4](../04-evaluation/README.md) では Microsoft Foundry の **組み込みエバリュエーター**（Relevance / Coherence / Fluency など）で `Summarizer` を評価しました。
本ハンズオンでは、組み込みでは測れない **ドメイン固有の品質基準** をカスタム エバリュエーターで定義し、同じ `Summarizer` に適用します。

> カスタム エバリュエーター（**Public Preview**）はすべて **Foundry ポータル UI 上で作成可能** です。SDK / コードのローカル実行は不要です。

## 学習ゴール

- カスタム エバリュエーターの **2 タイプ**（Code-based / Prompt-based）の使い分けを理解する
- ポータルの **Evaluator catalog** からカスタム エバリュエーターを作成・登録できる
- 既存の評価ジョブにカスタム エバリュエーターを追加して、組み込みと並べてスコアできる

## 前提条件

- リポジトリ直下の [README.md](../../README.md#前提条件) のセットアップが完了していること
- [STEP1](../01-translate-summarize/README.md) を完了し、`Summarizer` エージェントが動作していること
- [STEP4](../04-evaluation/README.md) を一度実施し、データセット `summarizer-eval-set` がアップロード済みであること（再利用します）

## 作るもの

`Summarizer` の **Instructions「箇条書き 3 行で要約」** を機械的・意味的の両面から検証するため、3 つのカスタム エバリュエーターを作ります。

| 名前 | タイプ | 何を判定するか | スコア |
| --- | --- | --- | --- |
| `three_line_format` | Code-based | ちょうど 3 行 / 各行が `- ` で始まる箇条書きか | 0.0 / 0.5 / 1.0 |
| `line_length_limit` | Code-based | 各行が 80 文字以内か（`- ` を除く本文部分） | 0.0 / 1.0 |
| `no_preamble` | Prompt-based | 「以下が要約です」等の前置き / 後置きが混入していないか | 1〜5 |

> **使い分けの目安**: 機械的に判定できるもの（行数・文字数）は **Code-based**（高速・決定的・LLM 呼び出しなしで安価）、意味の判定が必要なもの（前置きの有無）は **Prompt-based** が向いています。

## 手順

### 1. Code-based: `three_line_format` を作成する

1. [https://ai.azure.com](https://ai.azure.com) で対象プロジェクトを開く
2. 上部メニュー **「ビルド」** → 左メニュー **「評価」** → タブ **「エバリュエーター カタログ」**（**Evaluator catalog**）を開く
3. 右上 **「+ カスタム エバリュエーター」**（**+ Custom evaluator**）→ **「作成」**
4. 以下を入力:
   - **Name**: `three_line_format`
   - **Display name**: `Three Line Format`
   - **Description**: `Summarizer の出力がちょうど 3 行の箇条書きかを判定`
   - **Type**: **Code-based** を選択
   - **Scoring method**: Continuous（0.0〜1.0、固定）
5. **Code** エディタに [snippets/three_line_format.py](snippets/three_line_format.py) の内容をコピペ:

   ```python
   def grade(sample: dict, item: dict) -> float:
       """Summarizer の出力が「箇条書き 3 行」かを判定する。"""
       # データセット評価は item["response"]、
       # エージェント / モデル評価は item["sample"]["output_text"] に出力が入る。
       response = item.get("response", "") or item.get("sample", {}).get("output_text", "")

       if not response:
           return 0.0

       lines = [line for line in response.strip().splitlines() if line.strip()]

       if len(lines) != 3:
           return 0.0

       if all(line.lstrip().startswith("- ") for line in lines):
           return 1.0

       return 0.5
   ```

6. **保存** / **作成**

> Code-based は LLM を呼ばないため判定モデルは不要ですが、API スキーマ上 `deployment_name` の入力は **評価ジョブ実行時** に必須になります（カタログ作成時点では不要）。

### 2. Code-based: `line_length_limit` を作成する

同じ手順で 2 つ目を作成します。

1. **「+ カスタム エバリュエーター」** → **「作成」**
2. 入力:
   - **Name**: `line_length_limit`
   - **Display name**: `Line Length Limit (80 chars)`
   - **Description**: `各行が 80 文字以内かを判定（行頭の "- " は除外）`
   - **Type**: **Code-based**
3. **Code** エディタに [snippets/line_length_limit.py](snippets/line_length_limit.py) の内容をコピペ:

   ```python
   MAX_LINE_LENGTH = 80


   def grade(sample: dict, item: dict) -> float:
       """各行が MAX_LINE_LENGTH 文字以内かを判定する。"""
       response = item.get("response", "") or item.get("sample", {}).get("output_text", "")
       if not response:
           return 0.0

       lines = [line for line in response.strip().splitlines() if line.strip()]
       if not lines:
           return 0.0

       over = 0
       for line in lines:
           body = line.lstrip()
           if body.startswith("- "):
               body = body[2:]
           if len(body) > MAX_LINE_LENGTH:
               over += 1

       return 1.0 if over == 0 else 0.0
   ```

4. **保存** / **作成**

### 3. Prompt-based: `no_preamble` を作成する

1. **「+ カスタム エバリュエーター」** → **「作成」**
2. 入力:
   - **Name**: `no_preamble`
   - **Display name**: `No Preamble`
   - **Description**: `要約に前置き / 後置きが混入していないかを 1〜5 で判定`
   - **Type**: **Prompt-based**
   - **Scoring method**: **Ordinal**、**Min**: `1`、**Max**: `5`
3. **Prompt** エディタに [snippets/no_preamble_prompt.txt](snippets/no_preamble_prompt.txt) の内容をコピペ:

   ```text
   あなたは要約品質のレビュアーです。要約結果に「前置き」「後置き」「メタ発言」が混入していないかを 1〜5 の 5 段階で評価してください。

   評価対象は箇条書きの要約のみで、それ以外の文（自己紹介、要約の説明、依頼への返答、補足コメント等）は混入していてはいけません。

   採点基準:
   1 - 前置き / 後置きが大量にあり、本来の要約箇条書き以外の文が支配的
   2 - 前置き / 後置きが目立つ。要約以外の段落が複数行ある
   3 - 一部に前置き / 後置きや補足が混じっている（例: 末尾に 1 行の説明）
   4 - ほぼ要約のみ。微小な前置き語（例: 文頭の「以下のとおりです：」等）が 1 つだけある
   5 - 完全に要約箇条書きのみ。前置き・後置き・メタ発言は一切なし

   入力文（参考: 要約対象の原文）:
   {{query}}

   エージェントの出力（採点対象）:
   {{response}}

   Output Format (JSON):
   {
     "result": <integer from 1 to 5>,
     "reason": "<どの行が前置き/後置きに該当したか、または該当なしの理由を 1〜2 文で>"
   }
   ```

4. **保存** / **作成**

> プロンプト中の `{{query}}` / `{{response}}` は **データセットの列名 / 評価ジョブで自動付与される列名** に対応します。**二重中括弧**でないと変数として認識されません。

### 4. 評価ジョブを作成して 3 つを適用する

1. 上部メニュー **「ビルド」** → 左メニュー **「評価」** → 右上 **「+ 新しい評価」**
2. **評価名**: `summarizer-custom-eval-run-01`
3. **何を評価しますか?**: **エージェント** → `Summarizer` を選択
4. **テストデータ**: STEP4 でアップロードした `summarizer-eval-set` を再利用
   - **列マッピング**: `query` → `query`（`ground_truth` は今回のカスタム エバリュエーターでは未使用）
5. **エバリュエーター**: 以下の 3 つを選択（`Custom` カテゴリに表示されます）
   - `three_line_format` — **pass_threshold**: `1.0`、**deployment_name**: 任意のデプロイ名（例: `gpt-5.4-mini`。コードでは未使用だが入力必須）
   - `line_length_limit` — 同上、**pass_threshold**: `1.0`
   - `no_preamble` — **threshold**: `4`、**deployment_name**: 判定 LLM のデプロイ名（実際に LLM が呼ばれる）
6. （任意）組み込みの **Relevance / Coherence / Fluency** も並べて選択しておくと、新旧の比較がしやすい
7. **送信 / 作成** で評価ジョブを開始

### 5. 結果を確認する

評価ジョブが完了したら、各カスタム エバリュエーターのスコアを確認します。

| 確認ポイント | 何を見るか |
| --- | --- |
| `three_line_format` の平均が 1.0 未満 | 行数 or 箇条書き形式が崩れているケースあり |
| `line_length_limit` の平均が 1.0 未満 | 80 文字超過の行を含むケースあり（Per-row で何文字だったか確認） |
| `no_preamble` の平均が 4 未満 | 前置き / 後置きを書きがち。`reason` 列で具体例を確認 |

低スコアのケースが見つかったら、`Summarizer` の Instructions を強化し、**新しい評価ジョブ名**（例: `summarizer-custom-eval-run-02`）で再実行してスコアの **before / after** を比較します（[STEP4](../04-evaluation/README.md#5-instructions-を改善して再評価する) と同じ Eval 駆動サイクル）。

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| Code-based エバリュエーターがエラーで `0.0` 固定になる | `grade()` 内で例外が出ていないか確認。エラー時はそのアイテムが自動で `0.0` 扱い。`try/except` でフォールバックするのが安全 |
| Prompt-based の結果がパース失敗扱いになる | プロンプト末尾の **JSON 出力フォーマット**（`result` / `reason`）が崩れていないか確認。`{` `}` を必ず含める |
| `{{query}}` / `{{response}}` が変数として展開されない | **二重中括弧**になっているか / プロンプト編集画面でプレビューに値が差し込まれているか確認 |
| `three_line_format` で常に `0.5` になる | `Summarizer` が `- ` ではなく `・` `*` `1.` 等で箇条書きを書いている可能性。Instructions を `- ` 始まり指定に強化、または評価器側を許容形式に拡張 |
| `three_line_format` / `line_length_limit` が **全件 0.0**（例: 0/3）になる | **エージェント評価で `response` が取れていない可能性**。エージェント出力は `item["sample"]["output_text"]` に入るため、`item.get("response", "") or item.get("sample", {}).get("output_text", "")` のようにフォールバックさせる |
| カタログにカスタム エバリュエーターが出てこない | プレビュー機能のため、対象プロジェクトのリージョン / 機能フラグの状況を確認。**作成時のエラー表示**も併せて確認 |
| 評価ジョブで Code-based がスキップされる | 列マッピングで `response` がエージェント出力にバインドされているか確認（エージェント評価なら自動付与される） |
| 評価実行中に `Failed to upload evaluation result ... putAsset ... HTTP 500` エラー | 評価計算は終わり、**結果をプロジェクトに紐づく Storage（Blob）へ PUT する段階**で失敗している。まずジョブ名を変えて再実行（一時的な 5xx が多い）。繰り返し発生する場合は、**プロジェクトに紐づく Storage アカウントのネットワーク制限 / プライベートエンドポイント要求 / Trusted Microsoft services 許可** など、社内ポリシー / ガバナンス設定を確認 |

## クリーンアップ

- 評価ジョブ `summarizer-custom-eval-run-01` / `-02`
- カスタム エバリュエーター `three_line_format` / `line_length_limit` / `no_preamble`
  - 不要になったら **Evaluator catalog** から該当バージョンを削除

## 次のステップ

- `Summarizer` 以外のエージェント（`Translator` や [STEP3](../03-human-in-the-loop/README.md) の `post-drafter`）にも応用可能なカスタム エバリュエーターを作る
  - 例: `Translator` 用に「英語が混入していないか」を Prompt-based で
  - 例: `post-drafter` 用に「ハッシュタグが 1〜3 個か」を Code-based で
- ワークフロー全体（`translate-summarize`）を End-to-End で評価し、最終出力に対して同じカスタム エバリュエーターを適用する
- スコアトレンドを Continuous Evaluation（本番運用での継続評価）にも持ち込み、Application Insights のトレースから自動評価する流れに発展させる

## 参考リンク

- [Custom evaluators (preview) — Microsoft Learn](https://learn.microsoft.com/azure/foundry/concepts/evaluation-evaluators/custom-evaluators)
- [Run evaluations from the Microsoft Foundry portal](https://learn.microsoft.com/azure/foundry/how-to/evaluate-generative-ai-app)
- [Built-in evaluators — Microsoft Learn](https://learn.microsoft.com/azure/foundry/concepts/built-in-evaluators)
