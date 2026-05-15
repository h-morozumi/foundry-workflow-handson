"""line-length-limit custom evaluator (code-based).

Foundry ポータルの「カスタム エバリュエーター」(Code-based) のコードエディタに
そのままコピペして使う想定の ``grade()`` 関数です。

判定内容:
- ``response`` の各行が 80 文字以内に収まっているか
- 行頭の ``- `` 記号は文字数に含めずに本文部分の長さを測る
"""

MAX_LINE_LENGTH = 80


def grade(sample: dict, item: dict) -> float:
    """各行が ``MAX_LINE_LENGTH`` 文字以内かを判定する。"""
    # データセット評価は item["response"]、
    # エージェント / モデル評価は item["sample"]["output_text"] に出力が入る。
    # 両方のターゲットで動くようフォールバックさせる。
    response = item.get("response", "") or item.get("sample", {}).get("output_text", "")

    if not response:
        return 0.0

    lines = [line for line in response.strip().splitlines() if line.strip()]
    if not lines:
        return 0.0

    over = 0
    for line in lines:
        body = line.lstrip()
        # 行頭の "- " は文字数カウント対象外
        if body.startswith("- "):
            body = body[2:]
        if len(body) > MAX_LINE_LENGTH:
            over += 1

    # 1 行でも超過なら 0.0、全行 OK で 1.0
    return 1.0 if over == 0 else 0.0
