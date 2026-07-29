<p align="center">
  <img src="https://kejilion.sh/kejilionsh_logo.webp?v=2" alt="科技lion一键脚本工具" width="620">
</p>

<h1 align="center">科技lion一键脚本工具</h1>

<p align="center">
  面向 Linux 服务器的综合运维脚本，集成系统管理、Docker、LDNMP 建站、
  应用市场、网络测试、备份迁移与安全防护。
</p>

<p align="center">
  <a href="https://github.com/kejilion/sh/stargazers"><img src="https://img.shields.io/github/stars/kejilion/sh?style=flat-square" alt="GitHub Stars"></a>
  <a href="https://github.com/kejilion/sh/network/members"><img src="https://img.shields.io/github/forks/kejilion/sh?style=flat-square" alt="GitHub Forks"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg?style=flat-square" alt="Apache-2.0 License"></a>
  <a href="https://github.com/kejilion/sh/commits/main"><img src="https://img.shields.io/github/last-commit/kejilion/sh?style=flat-square" alt="Last Commit"></a>
</p>

<p align="center">
  <a href="README.md">简体中文</a> ·
  <a href="README.tw.md">繁體中文</a> ·
  <a href="README.kr.md">한국어</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.fa.md">فارسی</a>
</p>

<p align="center">
  <a href="#快速开始">快速开始</a> ·
  <a href="#核心能力">核心能力</a> ·
  <a href="#常用命令">常用命令</a> ·
  <a href="#kpanel-web-管理面板">KPanel</a> ·
  <a href="#支持系统">支持系统</a> ·
  <a href="#项目文档">项目文档</a>
</p>

## 项目介绍

科技lion一键脚本是一套面向 Linux 服务器的交互式运维工具箱。它将常用系统操作、
Docker 管理、网站搭建、应用部署、网络测试和数据维护集中到统一菜单，并提供 `k`
快捷命令，适合新手快速使用，也方便熟悉 SSH 的用户提高日常运维效率。

脚本直接读取和管理宿主机真实资源。通过脚本、SSH、Docker Compose 或
[KPanel](https://github.com/kejilion/KPanel) 创建的资源，可以继续由其他入口发现和管理。

## 快速开始

使用 `root` 用户执行。

### 中文版

```bash
bash <(curl -sL kejilion.sh)
```

### English

```bash
bash <(curl -sL kejilion.sh) en
```

首次运行后可按提示设置快捷命令。后续输入 `k` 即可打开主菜单。

> [!IMPORTANT]
> 脚本包含软件安装、网络配置、防火墙、磁盘和网站环境等系统级操作。
> 请确认服务器数据已备份，并在执行前阅读终端中的影响范围和确认提示。

## 核心能力

- **系统信息与维护**：查看 CPU、内存、磁盘、负载、网络和流量，管理更新、清理、
  时区、Swap、DNS、软件源、SSH、用户及常用系统服务。
- **Docker 管理**：安装 Docker，管理容器、镜像、网络和存储卷，查看日志与资源状态，
  并提供备份、还原和迁移能力。
- **LDNMP 与网站管理**：部署 Nginx、MySQL、PHP、Redis，创建 WordPress、静态站、
  PHP 站、反向代理、负载均衡和常见建站程序。
- **网站防护与优化**：提供 Fail2Ban、WAF、防火墙、CC 防护、性能优化、缓存清理、
  证书管理和环境更新。
- **应用市场**：集中安装和管理常用面板、网盘、监控、AI、开发、媒体和网络工具。
- **网络与性能测试**：提供测速、回程路由、流媒体解锁、IP 质量、硬件性能和综合测评。
- **备份与迁移**：支持网站、数据库、Docker 数据和服务器间的数据备份与恢复。
- **快捷命令**：常用业务可以直接通过 `k` 子命令进入，无需逐级查找菜单。

## 常用命令

| 操作 | 命令 |
| --- | --- |
| 打开脚本主菜单 | `k` |
| 查看系统信息 | `k info` |
| Docker 管理 | `k docker` |
| LDNMP 与站点管理 | `k web` |
| 安装 WordPress | `k wp example.com` |
| 创建反向代理 | `k fd example.com` |
| 应用市场 | `k app` |
| 管理指定应用 | `k app 1panel` |
| Fail2Ban 管理 | `k f2b` |
| SSH 密钥管理 | `k sshkey` |

运行脚本内的“命令行帮助”可以查看当前版本支持的完整命令列表。

## KPanel Web 管理面板

如果希望在浏览器中管理服务器，可以通过应用入口一键部署 KPanel：

```bash
bash <(curl -sL kejilion.sh) app kpanel
```

KPanel 是 `kejilion.sh` 的现代 Web 管理形态。脚本、SSH、Compose 和 KPanel
管理的是同一批宿主机真实资源，可在不同入口之间继续发现和管理。

- [KPanel GitHub 项目](https://github.com/kejilion/KPanel)
- [KPanel 一键部署与功能介绍](https://blog.kejilion.pro/kpanel-kejilion-web-server-panel/)

## 支持系统

脚本持续适配以下 Linux 发行版：

- Debian、Ubuntu、Kali Linux
- CentOS、Rocky Linux、AlmaLinux、Red Hat Enterprise Linux、Fedora
- Arch Linux
- Alpine Linux

不同发行版的软件包、网络栈和服务管理方式存在差异，部分功能会根据当前系统能力动态开放。

## 效果图预览

<p>
  <img src="https://kejilion.sh/img/screenshots/kejilionsh.webp" alt="科技lion一键脚本中文版界面" width="49%">
  <img src="https://kejilion.sh/img/screenshots/kejilionsh_en.webp" alt="KejiLion Shell Script English interface" width="49%">
</p>

## 项目文档

- [脚本更新日志](kejilion_sh_log.txt)
- [应用市场说明](apps/README.md)
- [问题反馈](https://github.com/kejilion/sh/issues)
- [KPanel Web 管理面板](https://github.com/kejilion/KPanel)
- [科技lion官方网站](https://kejilion.sh/)

## 安全建议

- 仅从官方域名和本仓库获取脚本，执行前可先审阅源码。
- 重要网站、数据库、Docker 数据和系统配置应定期备份。
- 生产服务器建议先确认命令影响范围，再执行升级、卸载、磁盘或网络相关操作。
- 提交问题时请隐藏密码、Token、私钥、公网 IP 等敏感信息。

## 支持项目

如果这个项目对你有帮助，欢迎 Star、提交 Issue 或参与改进。

USDT TRC20：

```text
TCP3PLGUTG9Z4z4tnHHSLbw5bgp8NXhTT3
```

## 开源许可

本项目采用 [Apache License 2.0](LICENSE) 开源。

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=kejilion/sh&type=Date)](https://star-history.com/#kejilion/sh&Date)
