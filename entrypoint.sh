#!/bin/bash
set -e

# Generate UUID for this job run
JOB_ID=$(cat /proc/sys/kernel/random/uuid)
echo "Job ID: ${JOB_ID}"

# Validate Pi auth.json is mounted
if [ ! -f /root/.pi/agent/auth.json ]; then
    echo "ERROR: auth.json not mounted at /root/.pi/agent/auth.json"
    exit 1
fi

# Start Chrome headless
chromium --headless --no-sandbox --disable-gpu --remote-debugging-port=9222 &
CHROME_PID=$!
sleep 2

# Git setup
git config --global user.name "popebot"
git config --global user.email "popebot@example.com"
if [ -n "$GITHUB_TOKEN" ]; then
    git config --global credential.helper store
    echo "https://${GITHUB_TOKEN}@github.com" > ~/.git-credentials
    chmod 600 ~/.git-credentials
fi

# Clone repo if REPO_URL set, otherwise assume /job is mounted
if [ -n "$REPO_URL" ]; then
    # Fast clone: single branch, shallow (depth 1)
    git clone --single-branch --branch "$BRANCH" --depth 1 "${REPO_URL}" /job
    cd /job
else
    cd /job
fi

# Setup log directory
LOG_DIR="/job/workspace/logs"
mkdir -p "${LOG_DIR}"

# Run Pi (print mode - execute and exit)
pi -p "$(cat /job/workspace/job.md)" --session-dir "${LOG_DIR}"

# Rename Pi's session file to UUID.jsonl
mv "${LOG_DIR}"/session-*.jsonl "${LOG_DIR}/${JOB_ID}.jsonl" 2>/dev/null || true

# Commit and push results (only if cloned from remote)
if [ -n "$REPO_URL" ]; then
    git add workspace/logs/
    git commit -m "popebot: job ${JOB_ID} completed" || true
    git push
fi

# Cleanup
kill $CHROME_PID 2>/dev/null || true

echo "Done. Job ID: ${JOB_ID}"
