# 1panel-appstore（lingdiansr 第三方应用仓库）

一个面向 **1Panel** 的**多应用**第三方应用商店仓库：所有社区自打包应用集中在这一个仓库里，按官方应用目录结构组织，可通过 **1Panel 计划任务定时同步**、`install.sh` 一次性安装，或手动拷贝接入。

## 应用列表

| 应用 (key) | 名称 | 说明 | 版本 |
| --- | --- | --- | --- |
| `easytier-web` | [EasyTier-Web](apps/easytier-web) | EasyTier 官方 Web 控制台（`easytier-web-embed`）自托管版，内嵌前端 + SQLite，可视化纳管组网节点并下发配置 | 2.6.4 |

> 与官方商店中不带控制台的 `easytier`（`limit: 1`）**互不冲突**，两者的应用 key 不同，可同时安装。

## 快速接入

### 方式一：1Panel 计划任务定时同步（推荐）

在 1Panel 面板新建「计划任务 → Shell 脚本」，内容如下（每天自动把本仓库的应用同步到本地应用目录）：

```bash
#!/bin/bash
rm -rf /tmp/appstore_merge
git clone --depth=1 https://ghfast.top/https://github.com/lingdiansr/1panel-appstore /tmp/appstore_merge/appstore-lingdiansr
cp -rf /tmp/appstore_merge/appstore-lingdiansr/apps/* /opt/1panel/resource/apps/local/
rm -rf /tmp/appstore_merge
echo "lingdiansr 三方应用商店数据已更新"
```

> 海外服务器可去掉 `https://ghfast.top/` 前缀直连 GitHub；也可换成其他加速前缀（如 `https://gh-proxy.com/`）。
>
> 同步完成后，在面板「应用商店 → 本地应用」点「更新应用列表」即可看到应用。

### 方式二：一次性安装脚本

```bash
# 国内加速
curl -fsSL https://ghfast.top/https://raw.githubusercontent.com/lingdiansr/1panel-appstore/main/install.sh | bash -s -- https://ghfast.top

# 海外直连
curl -fsSL https://raw.githubusercontent.com/lingdiansr/1panel-appstore/main/install.sh | bash
```

### 方式三：手动拷贝

```bash
cd /opt/1panel/resource/apps/local
git clone --depth 1 https://ghfast.top/https://github.com/lingdiansr/1panel-appstore /tmp/lingdiansr-appstore
cp -rf /tmp/lingdiansr-appstore/apps/* /opt/1panel/resource/apps/local/
rm -rf /tmp/lingdiansr-appstore
```

## 仓库结构

```
1panel-appstore/
├── install.sh                 # 一键安装脚本（同步 apps/* 到本地应用目录）
├── README.md
└── apps/
    └── <app-key>/             # 应用目录，key 即 1Panel 中的应用标识
        ├── data.yml           # 应用声明（名称、标签、描述、图标、架构等）
        ├── README.md          # 应用说明（面板内展示）
        ├── logo.png           # 180x180、≤10KB
        └── <version>/         # 真实版本目录，版本号不以 v 开头
            ├── data.yml       # 安装表单（formFields，端口字段用 PANEL_APP_PORT_* 前缀）
            └── docker-compose.yml
```

## 私有部署 / 私有仓库

若把本仓库设为私有，同步脚本需带访问令牌：

```bash
git clone --depth=1 https://x-access-token:<PAT>@github.com/lingdiansr/1panel-appstore /tmp/appstore_merge/appstore-lingdiansr
```

## 免责声明

本仓库为社区第三方应用包集合，与各应用官方、1Panel 官方均无直接关系；应用镜像均引用各项目官方发布物。请自行评估风险后使用。
