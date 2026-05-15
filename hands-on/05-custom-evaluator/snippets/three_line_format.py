"""three-line-format custom evaluator (code-based).

Foundry ポータルの「カスタム エバリュエーター」(Code-based) のコードエディタに
そのままコピペして使う想定の ``grade()`` 関数です。

判定内容:
- ``response`` がちょうど 3 行か
- 各行が ``- ``（ハイフン + 半角スペース）で始まる箇条書きか

両方を満たせば 1.0、行数だけ 3 行なら 0.5、それ以外は 0.0 を返します。
"""


def grade(sample: dict, item: dict) -> float:
    """Summarizer の出力が「箇条書き 3 行」かを判定する。"""
    # データセット評価は item["response"]、
    # エージェント / モデル評価は item["sample"]["output_text"] に出力が入る。
    # 両方のターゲットで動くようフォールバックさせる。
    response = item.get("response", "") or item.get("sample", {}).get("output_text", "")

    if not response:
        return 0.0

    # 末尾の空行を除去してから行に分割
    lines = [line for line in response.strip().splitlines() if line.strip()]

    if len(lines) != 3:
        return 0.0

    if all(line.lstrip().startswith("- ") for line in lines):
        return 1.0

    # 行数だけは合っているが箇条書き形式ではない
    return 0.5
