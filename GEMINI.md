# GEMINI.md - thepopebot Project Context

## Project Overview

**thepopebot** is an autonomous AI agent infrastructure designed to run secure, self-evolving agents using GitHub Actions for free compute. It uses a "two-layer" architecture to isolate sensitive credentials from the LLM while allowing the agent to modify its own repository.

### Architecture

1. **Event Handler (Orchestrator):** A Node.js Express server (`event_handler/`) that manages Telegram interactions, processes webhooks, and schedules cron jobs. It creates GitHub "job branches" to trigger agent execution.
2. **Docker Agent (Worker):** A containerized environment triggered by GitHub Actions (`run-job.yml`). It runs the **Pi coding agent** (powered by Claude) to perform tasks, commit changes, and open Pull Requests.
3. **Operating System (Config):** The `operating_system/` directory acts as the agent's "brain," containing its personality (`SOUL.md`), scheduled tasks (`CRONS.json`), and event triggers (`TRIGGERS.json`).

---

## Building and Running

### Prerequisites

- Node.js 18+
- GitHub CLI (`gh`) authenticated
- ngrok (for local webhook development)
- Anthropic API Key (Required)

### Setup and Initialization

The project includes a comprehensive interactive setup wizard.

- **Full Setup:** `npm run setup`
- **Telegram Only Setup:** `npm run setup-telegram`

### Running the Event Handler

The event handler must be running to receive webhooks and manage crons.

- **Production:** `cd event_handler && npm start`
- **Development:** `cd event_handler && npm run dev` (uses nodemon)

### Testing

- **Status Check:** `curl http://localhost:3000/ping -H "x-api-key: YOUR_API_KEY"`
- **Manual Job Trigger:** Send a POST to `/webhook` with `{"job": "task description"}`.

---

## Development Conventions

### The "Operating System" Metaphor

- **SOUL.md:** Define the agent's identity and values here.
- **CRONS.json:** Add scheduled tasks. Types: `agent` (runs a Pi job), `command` (runs a shell command), `http` (hits a URL).
- **TRIGGERS.json:** Map incoming webhooks to actions.

### Self-Modification

The agent is designed to be **self-evolving**. It has a dedicated skill (`.pi/skills/modify-self/`) for updating its own code. All changes are made via PRs on `job/*` branches.

### Security and Secrets

- **Secrets Isolation:** Credentials in `.env` or GitHub Secrets are filtered before being exposed to the agent's shell.
- **LLM Secrets:** Only keys specifically intended for the LLM (e.g., OpenAI/Brave keys) are passed to the agent container via `LLM_SECRETS`.

### Code Structure

- `event_handler/tools/`: Contains logic for GitHub, Telegram, and Job creation.
- `event_handler/claude/`: Handles LLM conversation logic and tool usage for the Telegram interface.
- `docs/`: Comprehensive documentation on Architecture, Configuration, and Security.

---

## Key Files for Reference

- `README.md`: High-level workflow and "Why"
- `docs/ARCHITECTURE.md`: Technical deep-dive into the two-layer system
- `operating_system/SOUL.md`: The agent's personality definition
- `event_handler/server.js`: Main entry point for the orchestration layer
- `setup/setup.mjs`: The initialization logic
