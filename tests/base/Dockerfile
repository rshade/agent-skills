FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y curl git jq iproute2 iptables && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js (required for npx skills)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="/root/.opencode/bin:${PATH}"

COPY test-skill.sh /usr/local/bin/test-skill
RUN chmod +x /usr/local/bin/test-skill

WORKDIR /workspace
ENTRYPOINT ["test-skill"]
