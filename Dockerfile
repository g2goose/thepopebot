FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y \
    chromium \
    git \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @mariozechner/pi-coding-agent

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /job/workspace

ENTRYPOINT ["/entrypoint.sh"]
