# Cloud Agent base image for Q-Reversi Flutter development.
# Cursor clones the repo at runtime; do not COPY the project here.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome-stable

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    sudo \
    unzip \
    wget \
    xz-utils \
    zip \
    libglu1-mesa \
    libgtk-3-0 \
    libnss3 \
    libxss1 \
    libasound2t64 \
    fonts-liberation \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Google Chrome (for computer use / UI verification)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Flutter SDK (stable channel, matches GitHub Actions flutter-version: 3.x)
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_HOME}" \
    && flutter config --no-analytics \
    && flutter precache --web \
    && flutter doctor -v
