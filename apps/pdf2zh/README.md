# PDFMathTranslate Zotero Python Server

本应用包提供与 Zotero PDF2zh 插件兼容的 Python Server。它不是通用的 Gradio GUI；服务端负责接收 Zotero 插件的翻译请求、执行 `pdf2zh_next`、报告任务进度并提供生成文件下载。

- Server 项目：<https://github.com/guaguastandup/zotero-pdf2zh>
- Server 文档：<https://github.com/guaguastandup/zotero-pdf2zh/blob/main/docs/zh/guide/docker.md>
- 翻译引擎：<https://github.com/PDFMathTranslate/PDFMathTranslate-next>
- Server 版本：`4.1.7`
- 翻译引擎镜像：`awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4`

## Zotero 插件配置

安装完成后，在 Zotero PDF2zh 插件的 **Python Server IP** 中填写：

```text
http://<服务器地址>:<宿主机端口>
```

默认端口为 `8890`，例如：

```text
http://192.168.31.6:8890
```

插件的连接检查接口为：

```text
GET /health
```

如果返回包含 `status: ok` 的 JSON，说明 Server 已启动。服务端没有额外的 Web 登录层；请只在可信网络开放端口，或通过 1Panel 反向代理、HTTPS 和访问控制保护。

## 支持的插件接口

本包兼容 Zotero PDF2zh Server 协议，包括：

```text
GET  /health
GET  /api/config
GET  /api/tasks
GET  /api/history
GET  /translatedInfo
POST /translate
GET  /translatedFile/<filename>
```

## 首次安装

本版本在 1Panel 安装时构建镜像，构建过程需要：

- 拉取 `awwaawwa/pdfmathtranslate-next:v2.9.0-babeldoc-v0.6.4`；
- 下载 Zotero Server `v4.1.7/server.zip`；
- 安装 Flask、PyPDF 和 TOML 依赖。

首次构建时间和占用空间会明显高于只拉取预构建镜像的应用。构建和首次翻译都需要服务器访问镜像、GitHub Release 及模型源。

## 配置项

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PANEL_APP_PORT_HTTP` | `8890` | 宿主机 Python Server 端口，容器端口固定为 `8890` |
| `DATA_PATH` | `./data` | Server 配置和翻译结果的持久化根目录 |

## 数据与备份

应用会创建以下目录：

```text
<data path>/
├── config/       # Server 配置和插件传入的翻译配置
└── files/        # 翻译生成的 PDF 与历史结果
```

- 备份或迁移应用时，请同时保存 `config/` 和 `files/`。
- `config/` 可能包含翻译服务 API key，备份文件应限制访问权限。
- 删除应用前，如果需要保留配置或翻译结果，请先备份数据目录。

## 与 Gradio GUI 的区别

本包专门服务 Zotero 插件，不再启动 `pdf2zh -i` Gradio GUI，也不提供 Gradio `/gradio_api/*` 接口。需要浏览器 GUI 的用户应使用 PDFMathTranslate 官方 GUI 镜像，而不是本应用版本。

## 版本升级

本应用当前版本为 `4.1.7`，对应 Zotero Server `v4.1.7`。后续升级应新增版本目录，并保持 `DATA_PATH` 不变以继续使用已有配置和结果。

## 免责声明

本应用包为社区第三方打包，与 Zotero PDF2zh、PDFMathTranslate、1Panel 或镜像发布者无直接关系。请自行评估外部翻译服务、模型下载和生成文件的安全风险，并遵守上游许可证及相关服务条款。
