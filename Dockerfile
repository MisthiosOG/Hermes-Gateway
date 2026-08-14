FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

ARG HERMES_REF=v2026.8.3
ENV HERMES_REF=${HERMES_REF}

# Original deps + openssh-server for SSH access via Railway TCP proxy.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates git tini openssh-server && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# --- SSH config: root login + password auth, port 22 ---
RUN mkdir -p /run/sshd && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN git clone --depth 1 --branch ${HERMES_REF} https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    uv pip install --system --no-cache -e ".[all,messaging,tts-premium,honcho,bedrock,anthropic,edge-tts,hindsight,vision]" && \
    cd /opt/hermes-agent/web && \
    npm install --silent && \
    npm run build && \
    cd /opt/hermes-agent/ui-tui && \
    npm install --silent --no-fund --no-audit --progress=false && \
    npm run build && \
    rm -rf /opt/hermes-agent/web /opt/hermes-agent/.git /root/.npm

RUN printf 'docker\n' > /opt/hermes-agent/.install_method

COPY requirements.txt /app/requirements.txt
RUN uv pip install --system --no-cache -r /app/requirements.txt

RUN mkdir -p /data/.hermes

COPY server.py /app/server.py
COPY templates/ /app/templates/
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV HOME=/data
ENV HERMES_HOME=/data/.hermes
ENV HERMES_TUI_DIR=/opt/hermes-agent/ui-tui

# SSH_ROOT_PASSWORD: set this in Railway service variables.
# If unset, defaults to "pow1fu".
ENV SSH_ROOT_PASSWORD=pow1fu

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/app/start.sh"]
