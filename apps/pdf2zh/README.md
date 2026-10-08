# PDFMathTranslate（pdf2zh）

PDFMathTranslate（`pdf2zh`）是一个通过浏览器使用的 PDF 文档翻译服务，尽量保留公式、图表和原始排版。该应用包使用上游官方 Docker 镜像，不在 1Panel 安装过程中本地构建 Python 环境。

- 上游项目：<https://github.com/PDFMathTranslate/PDFMathTranslate>
- 中文文档：<https://github.com/PDFMathTranslate/PDFMathTranslate/blob/main/docs/README_zh-CN.md>
- 在线服务：<https://pdf2zh.com/>
- 许可证：AGPL-3.0
- 镜像：`byaidu/pdf2zh:1.9.11`

## 访问服务

安装完成后，在浏览器打开：

```text
http://<服务器地址>:<Web 端口>/
```

默认宿主机端口为 `7860`。应用容器内部固定使用 `7860/tcp`，安装时可以在表单中改宿主机端口。

## 首次使用

1. 打开 Web 界面。
2. 选择翻译服务、源语言和目标语言。
3. 按所选服务填写需要的 API 地址、API key 或其他参数。
4. 上传 PDF，或输入 PDF URL 后开始翻译。
5. 在结果区域下载单语或双语 PDF。

首次翻译可能需要从上游模型源下载布局模型。请确保服务器能够访问模型源，并预留足够的磁盘空间；下载失败时可查看「应用 → 日志」中的容器日志。

## 配置项

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PANEL_APP_PORT_HTTP` | `7860` | 宿主机 Web 端口，容器端口固定为 `7860` |
| `DATA_PATH` | `./data` | 配置、上传文件和翻译结果的持久化根目录 |

翻译服务和 API key 不放在 1Panel 安装表单中。上游 GUI 会根据所选翻译服务动态显示配置项，并将服务配置保存到持久化目录中。

## 数据与备份

应用会创建以下目录：

```text
<data path>/
├── config/       # PDFMathTranslate 配置及翻译服务配置
└── files/        # 上传文件与生成的 PDF
```

- 备份或迁移应用时，请同时保存 `config/` 和 `files/`。
- `config/` 可能包含翻译服务凭证，备份文件应限制访问权限。
- 删除应用前，如果需要保留翻译结果或服务配置，请先备份数据目录。

## 公网部署安全

该 GUI 默认不提供额外的用户登录认证。不要直接将它暴露到不受信任的公网；建议使用 1Panel「网站 → 反向代理」接入域名和 HTTPS，并在代理层增加访问控制。API key 和生成文件同样应按敏感数据保护。

## 版本升级

本应用当前版本为 `1.9.11`，对应镜像 `byaidu/pdf2zh:1.9.11`。后续升级通过新增版本目录完成；只要保持相同的 `DATA_PATH`，已保存的配置和结果可以继续使用。

## 免责声明

本应用包为社区第三方打包，与 PDFMathTranslate、1Panel 或镜像发布者无直接关系。请自行评估外部翻译服务、模型下载和生成文件的安全风险，并遵守上游 AGPL-3.0 许可证及相关服务条款。
