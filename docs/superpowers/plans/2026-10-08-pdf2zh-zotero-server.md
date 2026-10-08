# pdf2zh Zotero Python Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Gradio-only pdf2zh package with a multi-architecture Zotero Python Server package compatible with `guaguastandup/zotero-pdf2zh`.

**Architecture:** Build a self-contained image from the pinned `awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4` engine image, install the Python Server dependencies, and unpack the pinned `v4.1.7/server.zip`. Run `/app/server/server.py` directly on container port 8890 without Docker socket access. Persist `/app/server/config` and `/app/server/translated` through the 1Panel data root.

**Tech Stack:** YAML, Dockerfile, Docker Compose, Flask Python Server distribution, 1Panel metadata, Markdown.

---

### Task 1: Replace application metadata and install form

**Files:**
- Modify: `apps/pdf2zh/data.yml`
- Delete: `apps/pdf2zh/1.9.11/data.yml`
- Delete: `apps/pdf2zh/1.9.11/docker-compose.yml`
- Create: `apps/pdf2zh/4.1.7/data.yml`

- [x] **Step 1: Point metadata to the Zotero Server project**

Set the application title/description to describe the Zotero Python Server, update `github` to `guaguastandup/zotero-pdf2zh`, update the document URL to its Server/Docker guide, retain `pdf2zh` as the application key, and keep `amd64`/`arm64` architectures.

- [x] **Step 2: Add the 4.1.7 form**

Create exactly two fields: `PANEL_APP_PORT_HTTP` default `8890` with `paramPort`, and `DATA_PATH` default `./data`. Use labels that identify the Python Server port and persistent data directory.

- [x] **Step 3: Confirm old GUI version files are gone**

Ensure no Compose or form file still references `7860`, `byaidu/pdf2zh:1.9.11`, or `pdf2zh -i`.

### Task 2: Add the self-contained Python Server image

**Files:**
- Create: `apps/pdf2zh/4.1.7/Dockerfile`
- Create: `apps/pdf2zh/4.1.7/docker-compose.yml`

- [x] **Step 1: Create the pinned Dockerfile**

Use:

```dockerfile
ARG ZOTERO_PDF2ZH_FROM_IMAGE=awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4
FROM ${ZOTERO_PDF2ZH_FROM_IMAGE}
WORKDIR /app
RUN uv pip install --system --no-cache-dir flask pypdf toml
ARG SERVER_URL=https://github.com/guaguastandup/zotero-pdf2zh/releases/download/v4.1.7/server.zip
RUN curl -fL --retry 3 --retry-delay 2 "$SERVER_URL" -o /tmp/server.zip \
    && unzip -q /tmp/server.zip -d /app \
    && rm -f /tmp/server.zip
RUN mkdir -p /app/server/config /app/server/translated
EXPOSE 8890
CMD ["python", "/app/server/server.py", "--enable_venv=False", "--check_update=False", "--port=8890", "--host=0.0.0.0", "--env_tool=auto"]
```

Install `curl` and `unzip` only if the pinned base image does not already provide them; do not add Docker CLI or Docker socket access.

- [x] **Step 2: Create the Compose service**

Use a `build` context of `.`, build args for the pinned base and Server zip, map `${PANEL_APP_PORT_HTTP}:8890`, mount `${DATA_PATH}/config:/app/server/config` and `${DATA_PATH}/files:/app/server/translated`, set `TZ=Asia/Shanghai`, `restart: always`, `createdBy: "Apps"`, and external `1panel-network`.

- [x] **Step 3: Render static Compose configuration**

Run:

```bash
CONTAINER_NAME=pdf2zh-test PANEL_APP_PORT_HTTP=18890 DATA_PATH=/tmp/pdf2zh-data podman compose -f apps/pdf2zh/4.1.7/docker-compose.yml config
```

Expected: output contains `18890:8890`, both mounts, the pinned base image in build args, and the `server.py` command.

### Task 3: Update documentation and repository registration

**Files:**
- Modify: `apps/pdf2zh/README.md`
- Modify: `README.md`

- [x] **Step 1: Document Zotero Server usage**

Replace GUI instructions with the Python Server protocol, Zotero field value format, default port 8890, `/health` check, persistence layout, first-build requirements, firewall/reverse-proxy guidance, and the fact that the package does not provide the old Gradio GUI.

- [x] **Step 2: Register version 4.1.7**

Update the root application table from `1.9.11` to `4.1.7` and describe the app as the Zotero Python Server. Do not alter EasyTier documentation.

- [x] **Step 3: Validate docs and metadata consistency**

Search changed files for stale `7860`, `1.9.11`, `byaidu/pdf2zh`, `pdf2zh -i`, and GUI-only claims. Expected: no stale references outside historical plan/spec content that explicitly explains the migration.

### Task 4: Verify the package and commit

**Files:**
- Review all files in Tasks 1-3.

- [x] **Step 1: Parse YAML and assert package contract**

Use a throwaway Python script to parse metadata/form/Compose and assert application key `pdf2zh`, version form defaults `8890`/`./data`, image build args, port `8890`, and both mounts.

- [x] **Step 2: Validate Dockerfile and Server archive availability**

Run `git diff --check` and an HTTP header check for the pinned Server zip URL. Do not claim a full build until the container engine can pull the base image and build dependencies.

- [x] **Step 3: Build/run smoke test when the environment permits**

Build and start with Podman or Docker, then verify:

```bash
curl --fail http://127.0.0.1:18890/health
curl --fail http://127.0.0.1:18890/api/config
curl --fail http://127.0.0.1:18890/api/tasks
curl --fail http://127.0.0.1:18890/translatedInfo
```

Expected: the downloaded `v4.1.7/server.zip` passed a temporary local protocol smoke test: `/health`, `/api/config`, `/api/tasks`, and `/translatedInfo` returned HTTP 200. The container build was also attempted, but the local Podman registry mirror failed while pulling the pinned base image with `parsing image configuration ... EOF`.

- [x] **Step 4: Commit implementation**

Run:

```bash
git add apps/pdf2zh README.md docs/superpowers/plans/2026-10-08-pdf2zh-zotero-server.md
git commit -m "feat: package zotero python server"
```
