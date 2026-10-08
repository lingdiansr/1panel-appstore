# pdf2zh Zotero Python Server 打包设计

## 背景

将本仓库的 `pdf2zh` 应用从通用 Gradio GUI 切换为兼容 `guaguastandup/zotero-pdf2zh` 插件的 Python Server，使 Zotero 插件可以通过固定 HTTP 协议上传、翻译和下载 PDF。

同时清理 Wyse 上现有 1Panel 本地 `pdfmathtranslate` 应用的缓存目录，但保留配置和翻译结果。

## 范围

### 包含

- 将应用版本从 `1.9.11` 切换为 Zotero Server `4.1.7`。
- 在版本目录内构建 Python Server 镜像。
- 使用多架构 `awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4` 作为翻译引擎基础镜像。
- 固定下载 `guaguastandup/zotero-pdf2zh` 的 `v4.1.7/server.zip`。
- 暴露插件协议默认端口 `8890`。
- 持久化 Server 配置和翻译结果。
- 清理 Wyse 上现有应用的 `data/cache`，不删除 `config`、`files` 或应用目录。

### 不包含

- 不保留原来的 Gradio-only 启动命令。
- 不使用仅有 `arm64` 架构的 `vanxv/zotero-pdf2zh:latest`。
- 不挂载 Docker socket，不在容器内启动子容器。
- 不删除 Wyse 上的配置、翻译结果或整个应用。
- 不修改 Zotero 插件本身。

## 设计

### 应用目录

```text
apps/pdf2zh/
├── data.yml
├── README.md
├── logo.png
└── 4.1.7/
    ├── data.yml
    ├── Dockerfile
    └── docker-compose.yml
```

应用元数据的上游链接改为 `guaguastandup/zotero-pdf2zh`，应用说明改为 Zotero Python Server 部署说明。版本目录 `4.1.7` 与 Server 协议版本一致。

### 构建

Dockerfile 使用以下固定输入：

```text
基础镜像：awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4
Server 包：https://github.com/guaguastandup/zotero-pdf2zh/releases/download/v4.1.7/server.zip
```

构建阶段安装 Server 依赖 `flask`、`pypdf`、`toml`，不安装 Docker CLI，不访问 Docker socket。镜像内启动脚本直接调用基础镜像中已经存在的 `pdf2zh_next`。

### 容器运行

- 服务名：`pdf2zh`
- 容器端口：`8890/tcp`
- 宿主机端口：`PANEL_APP_PORT_HTTP`，默认 `8890`
- 启动命令：

```bash
python /app/server/server.py \
  --enable_venv=False \
  --check_update=False \
  --port=8890 \
  --env_tool=auto
```

- 重启策略：`always`
- 网络：外部 `1panel-network`
- 标签：`createdBy: "Apps"`

### 持久化

安装表单提供 `DATA_PATH`，默认值为 `./data`：

```text
${DATA_PATH}/config:/app/server/config
${DATA_PATH}/files:/app/server/translated
```

插件请求传入的配置保存在 `config/`，翻译生成文件保存在 `files/`。不挂载 Docker socket，避免插件 Server 通过宿主机 Docker 创建子容器。

### 插件协议

Server 必须提供以下兼容接口：

```text
GET  /health
GET  /api/config
GET  /api/tasks
GET  /api/history
GET  /translatedInfo
POST /translate
GET  /translatedFile/<filename>
```

Zotero 插件中填写：

```text
http://<服务器地址>:<宿主机端口>
```

默认示例：

```text
http://192.168.31.6:8890
```

### Wyse 缓存清理

只清理：

```text
/opt/1panel/apps/local/pdfmathtranslate/pdfmathtranslate/data/cache
```

保留：

```text
/opt/1panel/apps/local/pdfmathtranslate/pdfmathtranslate/data/config
/opt/1panel/apps/local/pdfmathtranslate/pdfmathtranslate/data/files
```

缓存目录当前属于 `root:root` 且权限为 `700`。清理需要 root 权限；若 SSH 会话无法无密码执行 sudo，则不绕过权限，记录阻塞并提供精确命令。

## 验收标准

- [ ] 新版本目录使用 `4.1.7`，不再启动 Gradio-only 服务。
- [ ] Dockerfile 固定基础镜像和 Server `v4.1.7` 下载地址。
- [ ] Compose 将宿主机端口映射到容器 `8890`，并挂载 config/files。
- [ ] YAML、Compose 和 Dockerfile 静态校验通过。
- [ ] 构建或运行后 `/health` 返回 HTTP 200 和 `status=ok`。
- [ ] `/api/config`、`/api/tasks`、`/translatedInfo` 返回插件协议响应。
- [ ] Wyse 上旧应用的 cache 被清理；config/files 保持不变。
- [ ] README、根 README、元数据和实际端口/路径一致。

## 取舍

选择在应用包内构建而不是使用 `vanxv/zotero-pdf2zh:latest`，因为当前已验证的预构建镜像仅有 `arm64`，无法覆盖 Wyse 的 `x86_64`。选择固定的 `awwaawwa` 基础镜像和 `v4.1.7` Server 包，避免直接依赖 `latest` 的代码漂移；代价是首次安装需要构建和联网下载依赖。
