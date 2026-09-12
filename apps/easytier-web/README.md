# EasyTier-Web

EasyTier 官方 Web 控制台（`easytier-web-embed`）自托管版：内嵌前端、SQLite 存储，用于**可视化纳管组网节点并下发配置**，无需依赖官方公共控制台。

- 上游项目：<https://github.com/EasyTier/EasyTier>
- 官方文档：<https://easytier.cn/>
- 镜像：`easytier/easytier`（与本应用同版本的官方镜像）

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

## 首次登录（重要）

控制台数据库初始化时会写入种子账号，**默认凭据为**：

```
用户名：admin
密码：21232f297a57a5a743894a0e4a801fc3      # 即 md5("admin")
```

该账号属于 `admins` 组，拥有全部权限。**安装完成后请立即登录并修改密码**（控制台内「用户/设置」处修改），或直接调用接口：

```bash
# 1) 登录拿会话
curl -c /tmp/et-cookie -X POST "http://<服务器地址>:11211/api/v1/auth/login" \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"21232f297a57a5a743894a0e4a801fc3"}'

# 2) 修改密码（改完即退出登录）
curl -b /tmp/et-cookie -X PUT "http://<服务器地址>:11211/api/v1/auth/password" \
     -H "Content-Type: application/json" \
     -d '{"new_password":"<你的强密码>"}'

# 3) 删除本地 cookie 文件
rm -f /tmp/et-cookie
```

> 注册功能默认开启（`--disable-registration` 可关闭）。若不希望公网用户自行注册，请在控制台修改密码后，在应用安装目录的 `docker-compose.yml` 里为该服务追加 `--disable-registration`，再在面板中重建容器。

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
| `EASYTIER_VERSION` | `v2.6.4` | 镜像标签 |
| `DATA_PATH` | `./data` | 数据目录（存放 `et.db`） |
| `TIME_ZONE` | `Asia/Shanghai` | 容器时区 |

> `EASYTIER_API_HOST` 填错时，控制台登录页仍可手动修改 API 地址（会记在浏览器本地存储里）。

## 反向代理 / HTTPS（可选）

控制台是纯 HTTP + WebSocket/普通 REST 的普通 Web 应用，可直接用 1Panel 的「网站 → 反向代理」把它挂到域名上（如 `https://et.example.com` → `http://127.0.0.1:11211`）。使用域名访问时，把 `EASYTIER_API_HOST` 设为该域名即可。

## 免责声明

本应用包为社区第三方打包，与 EasyTier 官方、1Panel 官方无直接关系，仅调用其公开发布的镜像。请自行评估风险，妥善保管 `data/et.db` 与账号密码。
