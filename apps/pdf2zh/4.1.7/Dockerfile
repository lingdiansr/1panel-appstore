ARG ZOTERO_PDF2ZH_FROM_IMAGE=awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4
FROM ${ZOTERO_PDF2ZH_FROM_IMAGE}

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip \
    && rm -rf /var/lib/apt/lists/*

RUN uv pip install --system --no-cache-dir flask pypdf toml

ARG SERVER_URL=https://github.com/guaguastandup/zotero-pdf2zh/releases/download/v4.1.7/server.zip
RUN curl -fL --retry 3 --retry-delay 2 "$SERVER_URL" -o /tmp/server.zip \
    && unzip -q /tmp/server.zip -d /app \
    && rm -f /tmp/server.zip \
    && mkdir -p /app/server/config /app/server/translated /opt/pdf2zh-defaults \
    && for f in config.json.example config.toml.example venv.json.example; do \
         if [ -f "/app/server/config/$f" ]; then cp "/app/server/config/$f" "/opt/pdf2zh-defaults/$f"; fi; \
       done

RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    'mkdir -p /app/server/config /app/server/translated' \
    'if [ ! -f /app/server/config/config.json ] && [ -f /opt/pdf2zh-defaults/config.json.example ]; then cp /opt/pdf2zh-defaults/config.json.example /app/server/config/config.json; fi' \
    'if [ ! -f /app/server/config/config.toml ] && [ -f /opt/pdf2zh-defaults/config.toml.example ]; then cp /opt/pdf2zh-defaults/config.toml.example /app/server/config/config.toml; fi' \
    'if [ ! -f /app/server/config/venv.json ] && [ -f /opt/pdf2zh-defaults/venv.json.example ]; then cp /opt/pdf2zh-defaults/venv.json.example /app/server/config/venv.json; fi' \
    'exec python /app/server/server.py --enable_venv=False --check_update=False --port=8890 --host=0.0.0.0 --env_tool=auto --enable_mirror=False' \
    > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai

EXPOSE 8890

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
