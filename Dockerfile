FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    DISPLAY=:0 \
    SCREEN_WIDTH=1280 \
    SCREEN_HEIGHT=800 \
    SCREEN_DEPTH=24 \
    VNC_PASSWORD=changeme \
    CHROME_FLAGS="--no-first-run --no-default-browser-check --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --disable-features=Translate,MediaRouter,OptimizationHints --password-store=basic --start-maximized"

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl wget gnupg locales tzdata \
      supervisor \
      xfce4 xfce4-terminal dbus-x11 x11-xserver-utils x11-utils \
      xvfb x11vnc \
      python3 python3-pip \
      net-tools netcat-openbsd procps git \
      jq \
    && rm -rf /var/lib/apt/lists/*

# Setup locale
RUN sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install noVNC + websockify
RUN mkdir -p /opt/novnc && \
    cd /opt/novnc && \
    git clone --depth=1 https://github.com/novnc/noVNC.git . && \
    git clone --depth=1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify && \
    ln -s vnc.html index.html

# Install Google Chrome Stable
RUN install -m 0755 -d /etc/apt/keyrings && \
    wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/keyrings/google-linux.gpg > /dev/null && \
    chmod a+r /etc/apt/keyrings/google-linux.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user and dirs
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} chrome && useradd -m -u ${UID} -g ${GID} -s /bin/bash chrome && \
    mkdir -p /home/chrome/downloads /home/chrome/profile /var/log/supervisor && \
    chown -R chrome:chrome /home/chrome /var/log/supervisor

# X startup and supervisord configs
COPY ops/supervisord.conf /etc/supervisor/supervisord.conf
COPY ops/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

EXPOSE 6080 5900
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 CMD /usr/local/bin/healthcheck.sh || exit 1

USER chrome
WORKDIR /home/chrome

# Default command runs supervisord that manages all processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]


