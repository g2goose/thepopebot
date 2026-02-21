# Configuration

## Environment Variables

All environment variables for the Event Handler (set in `event_handler/.env`):

| Variable | Description | Required |
|----------|-------------|----------|
| `API_KEY` | Authentication key for all endpoints (except `/telegram/webhook` and `/github/webhook` which use their own secrets) | Yes |
| `GH_TOKEN` | GitHub PAT for creating branches/files | Yes |
| `GH_OWNER` | GitHub repository owner | Yes |
| `GH_REPO` | GitHub repository name | Yes |
| `PORT` | Server port (default: 3000) | No |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token from BotFather | For Telegram |
| `TELEGRAM_CHAT_ID` | Restricts bot to this chat only | For security |
| `TELEGRAM_WEBHOOK_SECRET` | Secret for webhook validation | No |
| `GH_WEBHOOK_SECRET` | Secret for GitHub Actions webhook auth | For notifications |
| `ANTHROPIC_API_KEY` | Claude API key for chat functionality | For chat |
| `OPENAI_API_KEY` | OpenAI key for voice transcription | For voice |
| `EVENT_HANDLER_MODEL` | Claude model for chat (default: claude-sonnet-4) | No |

---

## GitHub Secrets

Set automatically by the setup wizard:

| Secret | Description | Required |
|--------|-------------|----------|
| `SECRETS` | Base64-encoded JSON with protected credentials | Yes |
| `LLM_SECRETS` | Base64-encoded JSON with LLM-accessible credentials | No |
| `GH_WEBHOOK_SECRET` | Random secret for webhook authentication | Yes |

---

## GitHub Repository Variables

Configure in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `GH_WEBHOOK_URL` | Event handler URL (e.g., your ngrok URL) | Yes | — |
| `AUTO_MERGE` | Set to `false` to disable auto-merge of job PRs | No | Enabled |
| `ALLOWED_PATHS` | Comma-separated path prefixes for auto-merge | No | `/logs` |
| `IMAGE_URL` | Docker image path (e.g., `ghcr.io/myorg/mybot`) | No | `stephengpope/thepopebot:latest` |
| `MODEL` | Anthropic model ID for the Pi agent (e.g., `claude-sonnet-4-5-20250929`) | No | Pi default |

---

## Telegram Setup

Telegram is configured by `npm run setup-telegram`. Run it:

- After the initial `npm run setup` if you skipped the bot token prompt
- Any time your ngrok URL changes (free plan regenerates the URL on restart)
- Any time the bot stops responding (webhook may be pointing at a stale URL)

### Prerequisites for `npm run setup-telegram`

Before running the wizard, start two processes in separate terminals:

```bash
# Terminal 1
cd event_handler && npm run dev

# Terminal 2
ngrok http 3000
```

Copy the `https://...ngrok...` URL from Terminal 2, then run:

```bash
npm run setup-telegram
```

### What the wizard does

1. Verifies the server is reachable through ngrok (`/ping`)
2. Updates `GH_WEBHOOK_URL` in your GitHub repository variables
3. Validates your Telegram bot token (get one from [@BotFather](https://t.me/BotFather))
4. Saves the token to `event_handler/.env` if new
5. Registers the Telegram webhook at `{ngrokUrl}/telegram/webhook`
6. Walks you through chat ID verification (send a code to your bot, paste back the reply)
7. Saves the chat ID to `.env` so the bot only responds to your chat

### Troubleshooting: "Could not reach api.telegram.org"

If the wizard fails with a network error during token validation, test connectivity manually:

```bash
curl https://api.telegram.org
```

If curl works but Node.js fails, try forcing IPv4 DNS resolution:

```bash
NODE_OPTIONS=--dns-result-order=ipv4first npm run setup-telegram
```

If Telegram is blocked by your ISP or network, run the event handler on a remote server (VPS, Railway, Render, etc.) instead of locally.

## ngrok URL Changes

ngrok assigns a new URL each time you restart it (unless you have a paid plan with a static domain). When your ngrok URL changes, run:

```bash
npm run setup-telegram
```

This verifies your server is running, updates the GitHub webhook URL, re-registers the Telegram webhook, and handles chat ID verification if needed.

---

## Manual Telegram Setup (Production)

If you're deploying to a platform where you can't run the setup script (Vercel, Railway, etc.), configure Telegram manually:

1. **Set environment variables** in your platform's dashboard (see `event_handler/.env.example` for reference):
   - `TELEGRAM_BOT_TOKEN` - Your bot token from @BotFather
   - `TELEGRAM_WEBHOOK_SECRET` - Generate with `openssl rand -hex 32`
   - `TELEGRAM_VERIFICATION` - A verification code like `verify-abc12345`

2. **Deploy and register the webhook:**

   ```bash
   curl -X POST https://your-app.vercel.app/telegram/register \
     -H "Content-Type: application/json" \
     -H "x-api-key: YOUR_API_KEY" \
     -d '{"bot_token": "YOUR_BOT_TOKEN", "webhook_url": "https://your-app.vercel.app/telegram/webhook"}'
   ```

   This registers your webhook with the secret from your env.

3. **Get your chat ID:**
   - Message your bot with your `TELEGRAM_VERIFICATION` code (e.g., `verify-abc12345`)
   - The bot will reply with your chat ID

4. **Set `TELEGRAM_CHAT_ID`:**
   - Add the chat ID to your environment variables
   - Redeploy

Now your bot only responds to your authorized chat.
