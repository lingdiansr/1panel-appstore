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
    && mkdir -p /app/server/config /app/server/translated

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Shanghai

EXPOSE 8890

CMD ["python", "/app/server/server.py", "--enable_venv=False", "--check_update=False", "--port=8890", "--host=0.0.0.0", "--env_tool=system", "--enable_mirror=False"]
