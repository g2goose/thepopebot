# Unified Coding Agent Docker Image — Plan

## Context

We maintain 4 separate Claude Code Docker images (`job`, `headless`, `workspace`, `cluster-worker`) that share ~80% of their code. This plan consolidates them into a single image + modular entrypoint that selects the right path based on env vars.

## Decisions

- **Playwright**: Always included. One image, no variants.
- **Non-root user**: `coding-agent` with home at `/home/coding-agent`
- **Directory**: `docker/coding-agent/`
- **Lifecycle**: Not a Dockerfile concern — controlled by whether entrypoint exits or blocks, and caller's AutoRemove/removeContainer behavior.

## Directory Structure

```
docker/coding-agent/
├── Dockerfile
├── entrypoint.sh              # Thin orchestrator — sources stages in order
├── commands/                   # Claude Code custom commands (from headless/workspace)
├── .tmux.conf                  # tmux config (from workspace)
└── scripts/
    ├── setup-auth.sh           # Secrets unpacking (SECRETS/LLM_SECRETS JSON → env vars)
    ├── setup-git.sh            # Git identity from GH_TOKEN
    ├── setup-workspace.sh      # Clone, reset, or skip (bind-mount)
    ├── setup-branch.sh         # Feature branch checkout/create
    ├── setup-skills.sh         # npm install in active skills
    ├── setup-logging.sh        # Create LOG_DIR, write initial meta.json
    ├── post-run-git.sh         # Git commit/push/PR after claude exits
    ├── post-run-logging.sh     # Finalize meta.json with endedAt
    └── claude/
        ├── setup-auth.sh       # Unset API key, export OAuth token
        ├── setup-trust.sh      # ~/.claude/settings.json + ~/.claude.json
        ├── setup-context.sh    # Chat context file + SessionStart hook
        ├── setup-mcp.sh        # Register Playwright MCP server
        ├── setup-prompt.sh     # Build system prompt from MD files / inline
        └── run.sh              # Build claude args + invoke (headless or interactive)
```

---

## Step 1: Dockerfile

Single superset image. Base `ubuntu:24.04`.

**System packages**: git, curl, jq, build-essential, locales, ca-certs, gnupg, procps, tmux, fonts-noto-color-emoji, fonts-symbola

**Tools installed**:
- Node.js 22 (nodesource)
- GitHub CLI (official apt repo)
- ttyd 1.7.7 (binary download)
- Claude Code (`npm install -g @anthropic-ai/claude-code`)
- Playwright Chromium (`npx playwright install --with-deps chromium`)

**User**: `coding-agent` (non-root), home `/home/coding-agent`
**WORKDIR**: `/home/coding-agent/workspace`
**COPY**: `scripts/`, `commands/`, `.tmux.conf`, `entrypoint.sh`
**ENV**: `PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers`

Status: [ ] TODO

---

## Step 2: Entrypoint (thin orchestrator)

Sources each stage script in order. Scripts check their own env vars and skip if not relevant.

```bash
#!/bin/bash
set -e

# --- General setup ---
source /scripts/setup-auth.sh
source /scripts/setup-git.sh
source /scripts/setup-workspace.sh
source /scripts/setup-branch.sh
source /scripts/setup-skills.sh
source /scripts/setup-logging.sh

# --- Claude Code setup ---
source /scripts/claude/setup-auth.sh
source /scripts/claude/setup-trust.sh
source /scripts/claude/setup-context.sh
source /scripts/claude/setup-mcp.sh
source /scripts/claude/setup-prompt.sh

# --- Run ---
set +e
source /scripts/claude/run.sh
# EXIT_CODE is now set (interactive mode never reaches here — exec replaces process)

# --- Post-run ---
source /scripts/post-run-git.sh
source /scripts/post-run-logging.sh
exit $EXIT_CODE
```

Status: [ ] TODO

---

## Step 3: Stage Scripts

### 3a. `setup-auth.sh` — Secrets + OAuth
- If `SECRETS` set: unpack JSON → env vars via jq eval
- If `LLM_SECRETS` set: unpack JSON → env vars via jq eval
- Always: `unset ANTHROPIC_API_KEY`
- Always: `export CLAUDE_CODE_OAUTH_TOKEN`

Status: [ ] TODO

### 3b. `setup-git.sh` — Git Identity
- If `GH_TOKEN` set: `gh auth setup-git`, derive name/email from `gh api user`
- If `GH_TOKEN` empty: skip entirely

Status: [ ] TODO

### 3c. `setup-workspace.sh` — Get the Code
Controlled by `GIT_STRATEGY` env var:

| Value | Behavior | Used by |
|-------|----------|---------|
| `clone-job` | `git clone --single-branch --depth 1 $REPO_URL` into WORKDIR | job |
| `clone-or-reset` | Clone if no .git, else fetch+reset+clean | headless, workspace |
| `bind-mount` (default) | Skip — code already mounted | cluster-worker |

Status: [ ] TODO

### 3d. `setup-branch.sh` — Feature Branch
- If `FEATURE_BRANCH` set AND `PERMISSION` != `investigate`: create or checkout
- Otherwise: skip

Status: [ ] TODO

### 3e. `setup-trust.sh` — Claude Code Config
- Always: write `~/.claude/settings.json` (trust, dark theme, skip dangerous prompt)
- Always: write `~/.claude.json` (onboarding complete, project trust, WebSearch allowed)
- If `CHAT_CONTEXT` set: write `.claude/chat-context.txt` + add SessionStart hook

Status: [ ] TODO

### 3f. `setup-extras.sh` — Optional Features
- If `ENABLE_SKILLS=1`: npm install in each `skills/active/*/`
- If `ENABLE_PLAYWRIGHT=1`: `claude mcp add playwright`
- If `SYSTEM_PROMPT_FILES` set: concat listed MD files, resolve `{{datetime}}`
- If `JOB_CONFIG` path exists: read title + description from JSON

Status: [ ] TODO

### 3g. `run-claude.sh` — Invoke Claude Code
Two paths based on `MODE`:

**`MODE=headless`** (default):
- Build args: `-p "$PROMPT"`, `--verbose`, `--output-format stream-json`
- Add `--model $LLM_MODEL` if set
- Add permission flag based on `PERMISSION`: `dangerous` → `--dangerously-skip-permissions`, `plan`/`investigate` → `--permission-mode plan`
- Add system prompt flag if available
- Tee to `$LOG_DIR` if set, otherwise stdout
- Capture `EXIT_CODE`

**`MODE=interactive`**:
- Start claude in tmux: `tmux -u new-session -d -s claude 'claude --dangerously-skip-permissions'`
- `exec ttyd --writable -p "${PORT:-7681}" tmux attach -t claude`
- Never returns — container stays alive until killed

Status: [ ] TODO

### 3h. `post-run.sh` — After Claude Exits
Controlled by `POST_RUN` env var:

| Value | Behavior | Used by |
|-------|----------|---------|
| `create-pr` | Commit all (or logs-only on fail), push, remove logs, push, `gh pr create` | job |
| `rebase-push` | `git add -A`, commit, rebase on base branch (AI merge-back fallback), force-push | headless |
| `none` (default) | Write `endedAt` to meta.json if logging, exit | cluster-worker, investigate |

Status: [ ] TODO

---

## Step 4: Update Callers

After the image works, update these files to use the new image + env var interface:
- `lib/tools/docker.js` — `runContainer`, `runCodeWorkspaceContainer`, `runHeadlessCodeContainer`, `runClusterWorkerContainer`
- `lib/cluster/execute.js` — cluster worker spawning
- `lib/code/actions.js` — workspace lifecycle
- `templates/.github/workflows/run-job.yml` — job workflow

Status: [ ] TODO

---

## Env Var Reference

### Core Mode Selection
| Variable | Values | Default | Purpose |
|----------|--------|---------|---------|
| `MODE` | `headless`, `interactive` | `headless` | Execution mode |
| `PERMISSION` | `dangerous`, `plan`, `investigate` | `dangerous` | Claude Code permission level |
| `GIT_STRATEGY` | `clone-job`, `clone-or-reset`, `bind-mount` | `bind-mount` | How workspace gets code |
| `POST_RUN` | `create-pr`, `rebase-push`, `none` | `none` | What happens after claude exits |

### Git / Repo
| Variable | Required | Purpose |
|----------|----------|---------|
| `REPO_URL` | For clone-job | Full git clone URL |
| `REPO` | For clone-or-reset | GitHub `owner/repo` slug |
| `BRANCH` | For clone modes | Branch to clone/checkout |
| `FEATURE_BRANCH` | No | Feature branch to create/checkout |

### Auth
| Variable | Required | Purpose |
|----------|----------|---------|
| `GH_TOKEN` | For git ops | GitHub CLI auth |
| `CLAUDE_CODE_OAUTH_TOKEN` | Yes | Claude Code auth |
| `SECRETS` | No | JSON blob of additional env vars |
| `LLM_SECRETS` | No | JSON blob of LLM-specific env vars |

### Claude Code
| Variable | Required | Purpose |
|----------|----------|---------|
| `PROMPT` | For headless | The task prompt (`-p` flag) |
| `SYSTEM_PROMPT` | No | Inline system prompt text |
| `SYSTEM_PROMPT_FILES` | No | Comma-separated config MD filenames to concat |
| `LLM_MODEL` | No | Model override |

### Optional Features
| Variable | Default | Purpose |
|----------|---------|---------|
| `ENABLE_SKILLS` | `0` | Install npm deps in skills/active/* |
| `ENABLE_PLAYWRIGHT` | `0` | Register Playwright MCP server |
| `CHAT_CONTEXT` | — | JSON planning conversation for SessionStart hook |
| `LOG_DIR` | — | Directory for session logs (tee stdout/stderr) |
| `PORT` | `7681` | ttyd port (interactive mode only) |

### Job-Specific (POST_RUN=create-pr)
| Variable | Purpose |
|----------|---------|
| `JOB_TITLE` | PR title and commit message |
| `JOB_DESCRIPTION` | PR body and prompt suffix |
| `JOB_ID` | Log directory name (extracted from branch if not set) |
