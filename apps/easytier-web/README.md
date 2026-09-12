# EasyTier-Web

EasyTier 官方 Web 控制台（`easytier-web-embed`）自托管版：内嵌前端、SQLite 存储，用于**可视化纳管组网节点并下发配置**，无需依赖官方公共控制台。

- 上游项目：<https://github.com/EasyTier/EasyTier>
- 官方文档：<https://easytier.cn/>
- 镜像：`easytier/easytier`（与本应用同版本的官方镜像）

## 首次登录

| 用户名 | 密码 |
| --- | --- |
| `admin` | `admin` |

`admin` 属于 `admins` 组、拥有全部权限，**登录后请立即在「修改密码」页面改成强密码**。

> 密码在浏览器登录页填**明文**即可（前端提交前会做一次 md5）。只有绕过界面直接调 API 时，才需要自己先 md5：`admin` 对应 `21232f297a57a5a743894a0e4a801fc3`。

## 组件与端口

容器内固定端口，宿主机端口由安装表单决定：

| 用途 | 容器端口 | 协议 | 默认宿主机端口 | 说明 |
| --- | --- | --- | --- | --- |
| Web 控制台 + REST API | 11211 | TCP | 11211 | 浏览器访问控制台；`easytier-core` 不需要连这个端口 |
| config server（设备接入） | 22020 | UDP | 22020 | 各节点 `easytier-core` 连这里拉取/上报配置 |

> 本应用使用 `easytier-web-embed` 二进制（内嵌前端）。官方镜像里另有不带前端的 `easytier-web`，只用它会出现「打开首页 404」。`--api-server-port` 与 `--web-server-port` 相同（都默认 11211）时，前端静态资源与 REST API 由同一端口提供服务。

## 安装前准备

需要在**云服务器安全组 / 本机防火墙**放行的端口：

| 端口 | 协议 | 用途 | 建议来源 |
| --- | --- | --- | --- |
| `11211`（或自定义控制台端口） | TCP | Web 控制台 + REST API | 仅你自己的 IP；这是管理入口 |
| `22020`（或自定义接入端口） | UDP | 组网节点接入（config server） | 组网节点所在网络 |

> **1Panel 默认把应用端口绑定到 `127.0.0.1`**（安全默认）：安装完成后 `docker ps` 会显示 `127.0.0.1:11211->11211/tcp`，此时只有服务器本机或反向代理能访问，仅在安全组放行不会生效。
> 若要浏览器直连控制台，安装时在「高级设置」勾选**允许外部访问（端口）**并选择 `0.0.0.0`（或具体公网 IP），映射即变为 `0.0.0.0:11211->11211/tcp`；
> 或保持默认绑定，用 1Panel 的「网站 → 反向代理」把域名指到 `http://127.0.0.1:11211`（推荐，可顺带加 HTTPS）。

## 纳管设备（让节点接入控制台）

1. 在控制台注册/创建一个账号（或使用 `admin`），记下用户名；
2. 在需要组网的机器上启动 `easytier-core`，把 config server 指向本应用：

```bash
# 用户名写在 URL 路径里
easytier-core --config-server udp://<服务器地址>:22020/<用户名> \
              --network-name <网络名> --network-secret <网络密钥> \
              --ipv4 <该节点在虚拟网络中的 IP>
```

3. 节点连上后即可在控制台里看到，并通过控制台为其下发网络配置。

如果希望**未知用户名的节点自动建号**（免去先建账号的步骤），在 `docker-compose.yml` 中为服务追加：

```yaml
    command:
      - ...            # 保留原有参数
      - --allow-auto-create-user
```

> 免 TUN 的纯转发节点可加 `--no-tun`；节点间通信端口（默认 11010/11011/11012/11013）由 `easytier-core` 自身监听，与本应用无关。
> 注册功能默认开启，若不希望公网用户自行注册，在 compose 的 command 里追加 `--disable-registration` 后重建。

## 数据与备份

- 数据目录：安装目录下的 `data/`，核心文件为 `data/et.db`（SQLite，含用户、设备、网络配置）；
- 备份：直接备份 `data/` 目录；恢复时还原目录后重建容器即可；
- 卸载应用前，若需保留数据，请先手动备份 `data/et.db`。

## 配置项说明（安装表单）

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PANEL_APP_PORT_HTTP` | `11211` | 控制台（Web + API）宿主机端口 |
| `PANEL_APP_PORT_CONFIG` | `22020` | 设备接入（config server）宿主机 UDP 端口 |
| `EASYTIER_API_HOST` | `http://127.0.0.1:11211` | **浏览器**访问控制台所用地址，前端据此调用 API；请改成你实际访问的地址，如 `http://1.2.3.4:11211` 或 `https://et.example.com` |
| `DATA_PATH` | `./data` | 数据目录（存放 `et.db`） |
| `TIME_ZONE` | `Asia/Shanghai` | 容器时区 |

> 镜像标签不放在安装表单里：**版本由版本目录决定**（本包为 `2.6.4/`，compose 中即 `easytier/easytier:v2.6.4`）。升级 = 新增一个版本目录，再在面板里切换，避免「版本选择」与「镜像标签」两个入口各填一次。

## 日志

面板「应用 → EasyTier-Web → 日志」显示的是容器 stdout。本包固定带 `--console-log-level=info`，启动即可看到建库/迁移/config server 监听等输出；若删掉该参数，`easytier-web-embed` 默认只输出 warn/error，日志页会看起来像“加载不出来”（空）。

## 常见问题

### 账号密码没错却登录不上 / 登录后又被弹回登录页

原因是 **`EASYTIER_API_HOST` 与你在浏览器里打开的地址不一致**：前端的 API 地址来自页面内嵌的 `api_meta.js`（由 `EASYTIER_API_HOST` 决定）。例如用 `http://ssh.ldsr.xyz:11211` 打开页面而该值为 `http://47.120.5.89:11211`，登录请求就变成**跨站请求**，会话 Cookie 是 `SameSite=Lax`，不会随之后的接口调用发送 → 表现为“密码明明对却登不上/反复跳登录页”。

处理：把 `EASYTIER_API_HOST` 改成你实际访问控制台用的地址（协议+主机+端口都要对，保存后会自动重建容器）；或在登录页的 **API Host** 输入框里改成正确地址（存浏览器本地）；浏览器里存过旧值时清一次站点数据再强刷。

自检：浏览器打开 `http://<你的地址>:<端口>/api_meta.js`，输出的 `api_host` 应与地址栏前缀一致。

### 注册时报 captcha verify error

`{"message":"captcha verify error, input: ..."}` 只有两种成因：验证码填错；或验证码的会话 Cookie 没带上（同样源于上面那个「页面地址与 API Host 不同源」，浏览器把验证码请求当第三方请求丢弃 Cookie）。改成同源后重新获取验证码再注册即可。

## 反向代理 / HTTPS（可选）

控制台是普通的 HTTP + REST 应用，可直接用 1Panel 的「网站 → 反向代理」把它挂到域名上（如 `https://et.example.com` → `http://127.0.0.1:11211`）。使用域名访问时，把 `EASYTIER_API_HOST` 设为该域名即可。

## 免责声明

本应用包为社区第三方打包，与 EasyTier 官方、1Panel 官方无直接关系，仅调用其公开发布的镜像。请自行评估风险，妥善保管 `data/et.db` 与账号密码。
