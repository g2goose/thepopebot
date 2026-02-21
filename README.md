# thepopebot

**Autonomous AI agents. All the power. None of the leaked API keys.**

---

## Why thepopebot?

**Secure by default** — Other frameworks hand credentials to the LLM and hope for the best. thepopebot is different: the AI literally cannot access your secrets, even if it tries. Secrets are filtered at the process level before the agent's shell even starts.

**The repository IS the agent** — Every action your agent takes is a git commit. You can see exactly what it did, when, and why. If it screws up, revert it. Want to clone your agent? Fork the repo — code, personality, scheduled jobs, full history, all of it goes with your fork.

**Free compute, built in** — Every GitHub account comes with free cloud computing time. thepopebot uses that to run your agent. One task or a hundred in parallel — the compute is already included.

**Self-evolving** — The agent modifies its own code through pull requests. Every change is auditable, every change is reversible. You stay in control.

---

## How It Works

```text
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  ┌─────────────────┐         ┌─────────────────┐                     │
│  │  Event Handler  │ ──1──►  │     GitHub      │                     │
│  │  (creates job)  │         │ (job/* branch)  │                     │
│  └────────▲────────┘         └────────┬────────┘                     │
│           │                           │                              │
│           │                           2 (triggers run-job.yml)       │
│           │                           │                              │
│           │                           ▼                              │
│           │                  ┌─────────────────┐                     │
│           │                  │  Docker Agent   │                     │
│           │                  │  (runs Pi, PRs) │                     │
│           │                  └────────┬────────┘                     │
│           │                           │                              │
│           │                           3 (creates PR)                 │
│           │                           │                              │
│           │                           ▼                              │
│           │                  ┌─────────────────┐                     │
│           │                  │     GitHub      │                     │
│           │                  │   (PR opened)   │                     │
│           │                  └────────┬────────┘                     │
│           │                           │                              │
│           │                           4a (auto-merge.yml)            │
│           │                           4b (update-event-handler.yml)  │
│           │                           │                              │
│           5 (Telegram notification)   │                              │
│           └───────────────────────────┘                              │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

You talk to your bot on Telegram (or hit a webhook). The Event Handler creates a job branch. GitHub Actions spins up a Docker container with the Pi coding agent. The agent does the work, commits the results, and opens a PR. Auto-merge handles the rest. You get a Telegram notification when it's done.

---

## Get FREE server time on Github

| | thepopebot | Other platforms |
|---|---|---|
| **Public repos** | Free. $0. GitHub Actions doesn't charge. | $20-100+/month |
| **Private repos** | 2,000 free minutes/month (every GitHub plan, including free) | $20-100+/month |
| **Infrastructure** | GitHub Actions (already included) | Dedicated servers |

You just bring your own [Anthropic API key](https://console.anthropic.com/).

---

## Get Started

### Prerequisites

| Requirement | Install |
|-------------|---------|
| **Node.js 18+** | [nodejs.org](https://nodejs.org) |
| **npm** | Included with Node.js |
| **Git** | [git-scm.com](https://git-scm.com) |
| **GitHub CLI** | [cli.github.com](https://cli.github.com) |
| **ngrok*** | [ngrok.com](https://ngrok.com/download) |

*\*ngrok is only required for local development. Production deployments don't need it.*

### Three steps

**Step 1** — Fork this repository:

[![Fork this repo](https://img.shields.io/badge/Fork_this_repo-238636?style=for-the-badge&logo=github&logoColor=white)](https://github.com/stephengpope/thepopebot/fork)

> GitHub Actions are disabled by default on forks. Go to the **Actions** tab in your fork and enable them.

**Step 2** — Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/thepopebot.git
cd thepopebot
```

**Step 3** — Run the setup wizard:

```bash
npm run setup
```

The wizard handles everything:

- Checks prerequisites (Node.js, Git, GitHub CLI, ngrok)
- Creates a GitHub Personal Access Token
- Collects API keys (Anthropic required; OpenAI, Groq, and [Brave Search](https://api-dashboard.search.brave.com/app/keys) optional)
- Sets GitHub repository secrets and variables
- Generates `event_handler/.env`
- Sets up Telegram bot (if you provide a bot token — see below)
- Starts the server + ngrok, registers webhooks and verifies everything works

> **Telegram bot token**: Get one from [@BotFather](https://t.me/BotFather) before running setup. Message `/newbot`, follow the prompts, and copy the token it gives you. If you skip this step or skip Telegram during setup, run `npm run setup-telegram` afterwards (see below).

**After setup, message your Telegram bot to create jobs!**

---

### If you skipped Telegram setup (or ngrok restarts)

Run the Telegram-only wizard to configure or reconfigure your bot:

**Terminal 1** — start the event handler:

```bash
cd event_handler && npm run dev
```

**Terminal 2** — start ngrok:

```bash
ngrok http 3000
```

**Terminal 3** — run the Telegram setup:

```bash
npm run setup-telegram
```

The wizard will ask for your ngrok URL, validate your bot token, register the webhook, and walk you through chat ID verification.

> **Note**: ngrok assigns a new URL every time you restart it (free plan). When that happens, re-run `npm run setup-telegram` to update the webhook — it takes about 30 seconds.

---

## Troubleshooting

### "Could not reach api.telegram.org" / "fetch failed" during bot token validation

The setup wizard couldn't connect to the Telegram API. Test it yourself:

```bash
curl https://api.telegram.org
```

Common causes and fixes:

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| curl also fails | No internet / DNS | Check your network connection |
| curl works but wizard fails | Node.js SSL or IPv6 issue | Set `NODE_OPTIONS=--dns-result-order=ipv4first` before running |
| Telegram blocked by ISP | Geo-restriction | Use a VPN or a remote server to run the event handler |

**Quick fix for Node.js IPv6 fallback issues:**

```bash
NODE_OPTIONS=--dns-result-order=ipv4first npm run setup-telegram
```

### Bot responds to verification code but not to regular messages

`TELEGRAM_CHAT_ID` is empty. Re-run `npm run setup-telegram` — the wizard will detect the missing chat ID and walk you through the verification step.

### 401 errors hitting `/ping` during setup

The server is still running with an old API key. Restart it after `npm run setup` writes a new `.env`:

```bash
# Ctrl+C the running server, then:
cd event_handler && npm run dev
```

### ngrok URL changed

Re-run `npm run setup-telegram`. It updates the GitHub webhook URL and re-registers the Telegram webhook automatically.

---

## Docs

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | Two-layer design, file structure, API endpoints, GitHub Actions, Docker agent |
| [Configuration](docs/CONFIGURATION.md) | Environment variables, GitHub secrets, repo variables, ngrok, Telegram setup |
| [Customization](docs/CUSTOMIZATION.md) | Personality, skills, operating system files, using your bot, security details |
| [Auto-Merge](docs/AUTO_MERGE.md) | Auto-merge controls, ALLOWED_PATHS configuration |
| [How to Use Pi](docs/HOW_TO_USE_PI.md) | Guide to the Pi coding agent |
| [Security](docs/SECURITY_TODO.md) | Security hardening plan |
