# pdf2zh Server 打包设计

## 背景

为本 1Panel 第三方应用仓库增加 PDFMathTranslate（pdf2zh）的浏览器 GUI 服务包，用户可以通过 1Panel 安装后在浏览器中使用 PDF 文档翻译功能。

## 范围

### 包含

- 新增 `pdf2zh` 应用目录及 1Panel 应用元数据。
- 使用上游已发布的 `byaidu/pdf2zh:1.9.11` 多架构镜像。
- 通过 `pdf2zh -i --serverport 7860` 启动 Gradio GUI。
- 暴露可配置的宿主机 Web 端口，默认 `7860`。
- 持久化 PDFMathTranslate 配置和翻译结果。
- 编写安装、配置、数据、安全和故障排查说明。

### 不包含

- 不实现或恢复上游已标记弃用的 HTTP API。
- 不在 1Panel 表单中复制各翻译服务的 API key 字段。
- 不在本仓库构建上游 Python 镜像。
- 不增加任务队列、用户系统或额外鉴权服务。

## 设计

### 应用目录

```text
apps/pdf2zh/
├── data.yml
├── README.md
├── logo.png
└── 1.9.11/
    ├── data.yml
    └── docker-compose.yml
```

`data.yml` 使用应用 key `pdf2zh`，应用类型为工具，架构声明为 `amd64` 与 `arm64`。版本目录名为 `1.9.11`，与官方 Docker Hub 镜像的稳定版本标签一致。

### 容器

- 镜像：`byaidu/pdf2zh:1.9.11`
- 服务名：`pdf2zh`
- 容器端口：`7860/tcp`
- 启动命令：`pdf2zh -i --serverport 7860`
- 重启策略：`always`
- 网络：加入外部 `1panel-network`
- 标签：`createdBy: "Apps"`

宿主机端口由 `PANEL_APP_PORT_HTTP` 映射到容器 `7860`。

### 持久化

安装表单提供 `DATA_PATH`，默认值为 `./data`。Compose 使用两个子目录：

```text
${DATA_PATH}/config:/root/.config/PDFMathTranslate
${DATA_PATH}/files:/app/pdf2zh_files
```

上游 GUI 将翻译服务配置、API key 的持久化值、语言偏好等写入配置目录；上传文件和翻译输出写入 `pdf2zh_files`。拆分挂载可避免将容器配置和业务文件混在同一容器路径中。

### 安装表单

| 环境变量 | 默认值 | 类型 | 说明 |
| --- | --- | --- | --- |
| `PANEL_APP_PORT_HTTP` | `7860` | number | 宿主机 Web 端口，使用 `paramPort` 校验 |
| `DATA_PATH` | `./data` | text | 配置和翻译结果的持久化根目录 |

不将翻译服务和 API key 做成固定表单字段，因为上游 GUI 已根据服务动态显示配置项，并且服务列表会随上游版本变化。

## 用户流程

1. 在 1Panel 应用商店安装 `pdf2zh`。
2. 使用默认或自定义 Web 端口完成安装。
3. 打开 `http://<主机地址>:<端口>/`。
4. 在 GUI 中选择翻译服务、源语言和目标语言，按所选服务填写配置。
5. 上传 PDF 或输入 PDF URL，执行翻译并下载输出文件。
6. 需要升级时，使用新的版本目录；当前版本的配置和结果继续由 `DATA_PATH` 保留。

## 错误处理与安全

- 镜像拉取失败、模型下载失败和翻译服务凭证错误由容器日志和 GUI 错误提示暴露，不在应用包中静默处理。
- 首次翻译可能下载上游布局模型，需要外网访问和足够磁盘空间。
- 默认 GUI 不提供额外的面板级登录认证。公网部署必须通过 1Panel 反向代理、访问控制或其他边界认证保护。
- `DATA_PATH/config` 包含翻译服务配置和可能的敏感凭证，README 必须提醒用户限制目录权限并纳入备份保护。

## 验收标准

- [ ] 1Panel 应用目录、元数据、版本数据和 Compose 文件结构与仓库现有应用一致。
- [ ] YAML 文件可解析，应用 key、版本、端口字段和架构声明正确。
- [ ] Compose 使用官方 `byaidu/pdf2zh:1.9.11` 镜像并以 GUI server 模式启动。
- [ ] `PANEL_APP_PORT_HTTP` 能控制宿主机 Web 端口，容器端口固定为 `7860`。
- [ ] `DATA_PATH` 同时持久化上游配置和翻译结果目录。
- [ ] 实际运行时 Web GUI 可访问，重建容器后挂载目录仍可使用。
- [ ] README 的镜像、端口、挂载、首次启动、配置和安全说明与 Compose 一致。

## 取舍

选择官方预构建镜像而不是应用安装时构建源码，原因是仓库现有应用均引用官方镜像，且 1Panel 安装过程不应额外承担 Python 依赖构建、PyPI 下载和编译失败风险。选择已发布的 `1.9.11` 而不是源码主线显示的未确认镜像版本，以保证版本目录和镜像标签可复现。
