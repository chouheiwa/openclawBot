# Read the doc: https://huggingface.co/docs/hub/spaces-sdks-docker
# OpenClaw AI Agent Gateway - HuggingFace Deployment

FROM node:22-bookworm

# Set non-interactive installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies (nginx, supervisor, utilities)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    ca-certificates \
    vim \
    git \
    sudo \
    unzip \
    nginx \
    supervisor \
    apache2-utils \
    openssl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install VNC, noVNC, Chrome and dependencies for Puppeteer
RUN apt-get update && apt-get install -y \
    # Chrome/Chromium dependencies
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    chromium \
    chromium-driver \
    # VNC and desktop environment
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    x11-utils \
    xauth \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install rclone and ttyd (precompiled binaries)
RUN cd /tmp \
    && curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip \
    && cd rclone-*-linux-amd64 \
    && cp rclone /usr/bin/ \
    && chown root:root /usr/bin/rclone \
    && chmod 755 /usr/bin/rclone \
    && cd /tmp \
    && rm -rf rclone-* \
    && curl -L https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Create user with UID 1000 (required by HuggingFace) and grant sudo privileges
RUN useradd -m -u 1000 user \
    && echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && mkdir -p /home/user/app \
    && chown -R user:user /home/user

# Set working directory
WORKDIR /home/user/app

# Copy package files
COPY --chown=user package*.json ./

# Switch to user before npm install
USER user

# Install npm dependencies as user
RUN npm install --production

# Copy application files
COPY --chown=user . .

# Copy nginx and supervisor configs as root
USER root
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /home/user/app/supervisord.conf
COPY start-services.sh /home/user/app/start-services.sh
RUN chown user:user /home/user/app/supervisord.conf /home/user/app/start-services.sh \
    && chmod +x /home/user/app/start-services.sh

USER user

# Make scripts executable
RUN chmod +x backup.sh restore.sh

# Create data directory for OpenClaw
RUN mkdir -p /home/user/.openclaw

# Set environment variables
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    DISPLAY=:99 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    VNC_PASSWORD=openclaw \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Expose port 7860 (required by HuggingFace Spaces)
EXPOSE 7860 6080

# Switch to root to start services (supervisor needs root for nginx)
USER root

# Start all services via start-services.sh
CMD ["/home/user/app/start-services.sh"]
