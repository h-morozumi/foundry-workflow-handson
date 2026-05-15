# AGENTS.md

This repository collects hands-on content and demos for Microsoft Foundry. The notes below guide AI coding agents working in this repository.

## Project Overview

- **Purpose**: Hands-on materials for learning Microsoft Foundry (formerly Azure AI Foundry) — Prompt Agents, agent workflows (sequential / loop / human-in-the-loop), and evaluation (built-in & custom evaluators).
- **Primary delivery**: Browser-based hands-on using the Microsoft Foundry portal (<https://ai.azure.com>). **All current STEPs run entirely in the portal.** No local Python execution is required by the learner.
- **Current contents**: 5 STEPs under `hands-on/` (`01-translate-summarize` ～ `05-custom-evaluator`). STEP4 / STEP5 ship sample data and evaluator code under each STEP's `snippets/` directory; learners copy-paste them into the portal.
- **Language / Runtime (only when code is added)**: Python 3.11+.
- **Package / environment manager**: Always use [`uv`](https://docs.astral.sh/uv/). Do not use `pip`, `venv`, `poetry`, or `conda`.
- **Topics**: Foundry projects / Prompt Agents, agent workflows (Workflows designer), Evaluations (built-in & custom), and — as a future extension — Microsoft Agent Framework / SDK samples.

## Mandatory Rules

1. **Keep hands-on portal-first.** Do not introduce local Python execution into the learner flow unless a sample explicitly requires it. Snippets shipped under `hands-on/<step>/snippets/` are intended to be **pasted into the Foundry portal**, not executed locally.
2. **Do not use any package manager other than `uv`.** When source code is added, manage it with `uv` (`uv init`, `uv add <pkg>`, `uv sync`, `uv run <cmd>`).
3. **Do not create `requirements.txt`.** Manage dependencies in `pyproject.toml` (managed by `uv`). Use `uv export` only when an export is explicitly required.
4. **Never commit secrets.** Put endpoints, API keys, and connection strings in `.env` (already in `.gitignore`), or use Azure Key Vault / Managed Identity. Provide `.env.example` as a template.
5. **Each hands-on / demo lives in its own subdirectory** under `hands-on/`, with its own `README.md` written in Japanese. Numbered prefix (`NN-short-slug`) keeps ordering. Sample data / evaluator scripts / prompt templates go under `hands-on/<step>/snippets/`. Put shared code (only if needed) in `src/`.
6. **For notebooks (`.ipynb`)**, also use a `uv`-managed virtual environment (e.g. `uv run --with jupyter jupyter lab`).
7. **Documentation, comments, and README prose must be written in Japanese.** Code identifiers and commit message prefixes stay in English.
8. **Do not hardcode endpoints, model names, or deployment names.** When code is added, read them from environment variables (e.g. `PROJECT_ENDPOINT`, `MODEL_DEPLOYMENT_NAME`).
9. **Use [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/) to provision Azure infrastructure.** Author IaC templates in **Bicep**, and prefer [Azure Verified Modules (AVM)](https://aka.ms/avm) for resource modules. Avoid Terraform, ARM JSON, or manual portal-based resource creation unless an explicit requirement calls for them.

## Common Commands (when code is added)

| Purpose | Command |
| --- | --- |
| Initialize a project | `uv init` |
| Pin Python version | `uv python pin 3.11` |
| Add a dependency | `uv add azure-ai-projects azure-identity` |
| Add a dev dependency | `uv add --dev pytest ruff` |
| Sync the virtual environment | `uv sync` |
| Run a script | `uv run python path/to/script.py` |
| Run tests | `uv run pytest` |
| Lint / Format | `uv run ruff check .` / `uv run ruff format .` |
| Launch Jupyter | `uv run --with jupyter jupyter lab` |

## Current Directory Layout

```
foundry-workflow-demo/
├── AGENTS.md                                # This file (rules for AI coding agents)
├── README.md                                # Repository overview / hands-on index (Japanese)
├── LICENSE
├── skills-lock.json
├── azure.yaml                               # azd service definition
├── infra/                                   # Bicep IaC for Foundry account / project / model deployment
│   ├── main.bicep
│   ├── main.bicepparam
│   ├── abbreviations.json
│   └── modules/
└── hands-on/
    ├── 01-translate-summarize/              # STEP1: Sequential (Translator → Summarizer)
    │   └── README.md
    ├── 02-quiz-review-loop/                 # STEP2: Loop (SetVariable / ConditionGroup / GotoAction)
    │   └── README.md
    ├── 03-human-in-the-loop/                # STEP3: HIL (Question / SendActivity)
    │   └── README.md
    ├── 04-evaluation/                       # STEP4: Built-in evaluators
    │   ├── README.md
    │   └── snippets/
    │       └── summarizer-eval-set.jsonl    # Evaluation dataset (paste into portal)
    └── 05-custom-evaluator/                 # STEP5: Custom evaluators (Code / Prompt-based)
        ├── README.md
        └── snippets/
            ├── line_length_limit.py         # Code-based evaluator source
            ├── three_line_format.py         # Code-based evaluator source
            └── no_preamble_prompt.txt       # Prompt-based evaluator template
```

> When SDK / code samples are added in the future, expect additional top-level files such as `pyproject.toml`, `uv.lock`, `.python-version`, `.env.example`, and an optional `src/` directory.

## Azure Infrastructure Conventions

Conventions for creating and deploying Azure resources.

- **Orchestration**: Use [Azure Developer CLI (`azd`)](https://learn.microsoft.com/azure/developer/azure-developer-cli/). Place `azure.yaml` at the repo root and an `infra/` directory beside it, and drive everything through `azd up` / `azd provision` / `azd deploy`.
- **IaC language**: Use **Bicep** (ARM JSON and Terraform are not the default choice). Use `infra/main.bicep` as the entry point and define parameters in `main.bicepparam`.
- **Modules**: Prefer [Azure Verified Modules (AVM)](https://aka.ms/avm) (`br/public:avm/res/...`) for individual resources. Only place hand-authored modules under `infra/modules/` when no AVM module is available.
- **Naming / tags**: Keep resource names and tags (e.g. `azd-env-name`) consistent by combining `azd env` variables (such as `AZURE_ENV_NAME`) with `abbreviations.json`.
- **Secrets**: Do not include connection strings or keys in Bicep outputs; reference them via Key Vault or Managed Identity. Restrict values managed with `azd env set` to non-sensitive ones.
- **Recommended layout**:

  ```
  infra/
  ├── main.bicep              # Subscription / resource-group scoped entry point
  ├── main.bicepparam         # Parameter definitions
  ├── abbreviations.json      # Per-resource-type abbreviations
  └── modules/                # Only hand-authored modules not covered by AVM
  azure.yaml                  # azd service definition
  ```

- **Reference**: Verify the latest Bicep / AVM best practices with the Bicep MCP `get_bicep_best_practices` tool.

## Microsoft Foundry Guidance

- Hands-on content currently runs **entirely in the Microsoft Foundry portal** (<https://ai.azure.com>). Do not introduce local execution steps unless a sample explicitly requires them.
- **Workflows can only be created / edited in the Foundry portal** at this time. The VS Code Foundry Toolkit can browse / run them but cannot author them — keep STEP READMEs aligned with this constraint.
- For Foundry agent / model / project operations, follow the `microsoft-foundry` skill.
- For code generation using Microsoft Agent Framework, follow the `microsoft-foundry-agent-framework-code-gen` skill.
- For end-to-end agent development workflow guidance, follow the `vscode-microsoft-foundry` skill.
- For authentication in any code added later, prefer `DefaultAzureCredential` from `azure-identity`. Assume `az login` locally.

## Hands-on Authoring Conventions

- Each STEP `README.md` should include: **学習ゴール / 前提条件 / 作るもの / 手順 / 動作確認 / トラブルシューティング / クリーンアップ / 次のステップ**.
- Cross-link prerequisite STEPs (e.g. STEP4 / STEP5 depend on the `Summarizer` from STEP1) using relative links.
- Reference the repository-level prerequisite list (`../../README.md#前提条件`) instead of duplicating it.
- Place any artifact a learner needs to upload or paste (datasets, evaluator code, prompt templates) under `hands-on/<step>/snippets/` and reference it from the README with a relative link.
- Keep model names generic (e.g. `gpt-5-mini` / `gpt-4.1-mini`) and let the learner choose what is deployed in their project.

## Language Policy

- Responses to the user, README files, and comments: **Japanese**.
- Internal reasoning, code identifiers, file / directory names, and commit message prefixes: English is fine.
