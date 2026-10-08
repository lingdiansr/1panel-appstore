# pdf2zh Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reproducible 1Panel application package for the PDFMathTranslate browser GUI server.

**Architecture:** Add a new `apps/pdf2zh` application following the repository's existing metadata/version/Compose layout. Run the published multi-architecture `byaidu/pdf2zh:1.9.11` image in Gradio GUI mode on container port 7860, map a configurable host port, and persist upstream configuration plus translated files under one configurable data root.

**Tech Stack:** YAML, Docker Compose, 1Panel app metadata, Markdown, official Docker Hub image.

---

### Task 1: Add application metadata and version form

**Files:**
- Create: `apps/pdf2zh/data.yml`
- Create: `apps/pdf2zh/1.9.11/data.yml`

- [x] **Step 1: Add top-level application metadata**

Create `apps/pdf2zh/data.yml` with application key `pdf2zh`, tool type, Chinese and English descriptions, upstream URLs, cross-version updates enabled, limit `1`, and `amd64`/`arm64` architectures. Keep the field shape aligned with `apps/easytier-web/data.yml`.

- [x] **Step 2: Add the 1.9.11 install form**

Create `apps/pdf2zh/1.9.11/data.yml` with exactly two editable fields:

```yaml
additionalProperties:
  formFields:
    - default: 7860
      edit: true
      envKey: PANEL_APP_PORT_HTTP
      labelEn: Web port
      labelZh: Web 端口
      label:
        en: Web port
        zh: Web 端口
      required: true
      rule: paramPort
      type: number
    - default: "./data"
      edit: true
      envKey: DATA_PATH
      labelEn: Data directory
      labelZh: 数据目录
      label:
        en: Data directory
        zh: 数据目录
      required: true
      type: text
```

- [x] **Step 3: Parse both YAML files**

Run:

```bash
ruby -e 'require "yaml"; ARGV.each { |path| YAML.load_file(path); puts "ok #{path}" }' apps/pdf2zh/data.yml apps/pdf2zh/1.9.11/data.yml
```

Expected: two `ok` lines and exit code 0.

### Task 2: Add Compose runtime and documentation

**Files:**
- Create: `apps/pdf2zh/1.9.11/docker-compose.yml`
- Create: `apps/pdf2zh/README.md`
- Create: `apps/pdf2zh/logo.png`
- Modify: `README.md`

- [x] **Step 1: Add Compose service**

Create one service named `pdf2zh` using `byaidu/pdf2zh:1.9.11`, `restart: always`, command `pdf2zh -i --serverport 7860`, the configurable host-to-container TCP port mapping, the two data mounts, `createdBy: "Apps"`, and the external `1panel-network`.

- [x] **Step 2: Add application documentation**

Document the official image/version, browser URL, port variable, data layout, GUI configuration of translation services and API keys, first-use model download, no-default-auth warning, reverse-proxy recommendation, backup guidance, and upstream/license links. Keep every port, image tag, and mount path identical to Compose.

- [x] **Step 3: Add a repository-sized logo**

Add a non-empty PNG for the application icon. It must be 180x180 pixels or smaller than the repository's stated 10 KB limit, and it must be traceable to the upstream project branding rather than an unrelated placeholder.

- [x] **Step 4: Register the app in the root README**

Add `pdf2zh` to the application list and update the example repository structure only if needed to describe the new app. Do not change the existing EasyTier documentation.

- [x] **Step 5: Validate Compose syntax and repository whitespace**

Run:

```bash
docker compose -f apps/pdf2zh/1.9.11/docker-compose.yml config

git diff --check
```

Expected: Compose prints the normalized configuration without errors; `git diff --check` prints no output and exits 0.

### Task 3: Verify the published image and runtime path

**Files:**
- No source files; verification only.

- [x] **Step 1: Verify the Docker Hub tag and architectures**

Run:

```bash
curl -fsSL 'https://hub.docker.com/v2/repositories/byaidu/pdf2zh/tags/1.9.11' | ruby -rjson -e 'j = JSON.parse(STDIN.read); abort "wrong tag" unless j["name"] == "1.9.11"; arch = j.fetch("images").map { |i| i["architecture"] }.sort; abort "missing architectures: #{arch}" unless %w[amd64 arm64].all? { |a| arch.include?(a) }; puts "tag=#{j["name"]} architectures=#{arch.join(",")}"'
```

Expected: output includes `tag=1.9.11` and both `amd64` and `arm64`.

- [x] **Step 2: Render Compose with representative variables**

Run:

```bash
CONTAINER_NAME=pdf2zh-test PANEL_APP_PORT_HTTP=17860 DATA_PATH=/tmp/pdf2zh-data docker compose -f apps/pdf2zh/1.9.11/docker-compose.yml config
```

Expected: normalized output contains `byaidu/pdf2zh:1.9.11`, `17860:7860/tcp`, `/tmp/pdf2zh-data/config:/root/.config/PDFMathTranslate`, and `/tmp/pdf2zh-data/files:/app/pdf2zh_files`.

- [x] **Step 3: Run a real container smoke test when Docker is available**

Run:

```bash
mkdir -p /tmp/pdf2zh-data/config /tmp/pdf2zh-data/files
CONTAINER_NAME=pdf2zh-test PANEL_APP_PORT_HTTP=17860 DATA_PATH=/tmp/pdf2zh-data docker compose -f apps/pdf2zh/1.9.11/docker-compose.yml up -d
curl --fail --retry 12 --retry-delay 2 http://127.0.0.1:17860/
docker compose -f apps/pdf2zh/1.9.11/docker-compose.yml down
```

Expected: the HTTP request exits 0 and the cleanup command exits 0. If the host lacks Docker or the image cannot be pulled, record the exact blocker and complete all static checks instead.

### Task 4: Review and commit the package

**Files:**
- Review all files created in Tasks 1-2.

- [x] **Step 1: Review the diff against the design**

Check that the package has no API server, fixed API-key form fields, custom build, unrelated refactor, placeholder documentation, or untracked generated runtime data. Confirm the root README app list, metadata key, version, image tag, port, and persistence paths agree.

- [x] **Step 2: Commit the implementation**

Run:

```bash
git add apps/pdf2zh README.md docs/superpowers/plans/2026-10-08-pdf2zh-server.md
```

Expected: one commit containing only the pdf2zh package and its root README registration.
