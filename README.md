<p align="center">
  <img src="https://kejilion.sh/kejilionsh_logo.webp?v=2" alt="KEJILION.SH 科技lion一键脚本工具" width="620">
</p>

<h1 align="center">KEJILION.SH · 科技lion一键脚本工具</h1>

<p align="center">
  面向 Linux 服务器的综合脚本工具箱，集成系统管理、网络测试、Docker、LDNMP 建站、
  应用市场、备份迁移与安全防护。
</p>

<p align="center">
  <a href="https://github.com/kejilion/sh/stargazers"><img src="https://img.shields.io/github/stars/kejilion/sh?style=flat-square" alt="GitHub Stars"></a>
  <a href="https://github.com/kejilion/sh/network/members"><img src="https://img.shields.io/github/forks/kejilion/sh?style=flat-square" alt="GitHub Forks"></a>
  <a href="https://github.com/kejilion/sh/commits/main"><img src="https://img.shields.io/github/last-commit/kejilion/sh?style=flat-square" alt="Last Commit"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg?style=flat-square" alt="Apache-2.0 License"></a>
</p>

<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/简体中文-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="简体中文"></a>
  <a href="README.tw.md"><img src="https://img.shields.io/badge/繁體中文-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="繁體中文"></a>
  <a href="README.md"><img src="https://img.shields.io/badge/English-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="English"></a>
  <a href="README.kr.md"><img src="https://img.shields.io/badge/한국어-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="한국어"></a>
  <a href="README.ja.md"><img src="https://img.shields.io/badge/日本語-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="日本語"></a>
  <a href="README.ru.md"><img src="https://img.shields.io/badge/Русский-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Русский"></a>
  <a href="README.fa.md"><img src="https://img.shields.io/badge/فارسی-2F4F4F?style=for-the-badge&logo=google-chrome&logoColor=white" alt="فارسی"></a>
</p>

<p align="center">
  <a href="#介绍">介绍</a> ·
  <a href="#一键安装">一键安装</a> ·
  <a href="#支持系统">支持系统</a> ·
  <a href="#效果图预览">效果图预览</a> ·
  <a href="#核心功能">核心功能</a> ·
  <a href="#kpanel-web-管理面板">KPanel</a> ·
  <a href="#开源许可">开源许可</a>
</p>

## 介绍

科技Lion 的 Shell 脚本工具是一款全能脚本工具箱，专为 Linux 监控、测试和管理而设计。
无论您是初学者还是经验丰富的用户，该工具都能提供便捷的解决方案。脚本集成 Docker
管理、LDNMP 建站、网站优化与防御、备份还原迁移，以及各类系统工具和应用的安装管理，
让服务器维护更加简单。

KejiLion's Shell script is an all-in-one toolbox designed for Linux monitoring, testing, and
server management. It brings together Docker management, LDNMP website deployment, optimization,
protection, backup, restoration, migration, and common server applications in one interactive tool.

## 一键安装

使用 `root` 用户执行以下命令。

### 中文版

```bash
bash <(curl -sL kejilion.sh)
```

### English Version

```bash
bash <(curl -sL kejilion.sh) en
```

首次运行后可按脚本提示设置 `k` 快捷命令，后续直接输入 `k` 即可打开主菜单。

> [!IMPORTANT]
> 脚本包含软件安装、网络、防火墙、磁盘和网站环境等系统级操作。
> 请在执行前阅读终端提示，并提前备份重要网站、数据库、容器和配置。

## 支持系统

<p>
  <img src="https://img.shields.io/badge/Ubuntu-FFB6C1?style=for-the-badge&logo=ubuntu&logoColor=black" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Debian-AFEEEE?style=for-the-badge&logo=debian&logoColor=black" alt="Debian">
  <img src="https://img.shields.io/badge/CentOS-98FB98?style=for-the-badge&logo=centos&logoColor=black" alt="CentOS">
  <img src="https://img.shields.io/badge/Alpine_Linux-ADD8E6?style=for-the-badge&logo=alpinelinux&logoColor=black" alt="Alpine Linux">
  <img src="https://img.shields.io/badge/Kali-D3D3D3?style=for-the-badge&logo=kali-linux&logoColor=black" alt="Kali Linux">
  <img src="https://img.shields.io/badge/Arch-FFFFE0?style=for-the-badge&logo=archlinux&logoColor=black" alt="Arch Linux">
  <img src="https://img.shields.io/badge/Red_Hat-FFE4E1?style=for-the-badge&logo=redhat&logoColor=black" alt="Red Hat">
  <img src="https://img.shields.io/badge/Fedora-FFD700?style=for-the-badge&logo=fedora&logoColor=black" alt="Fedora">
  <img src="https://img.shields.io/badge/AlmaLinux-FFEFD5?style=for-the-badge&logo=almalinux&logoColor=black" alt="AlmaLinux">
  <img src="https://img.shields.io/badge/Rocky_Linux-FFFACD?style=for-the-badge&logo=rocky-linux&logoColor=black" alt="Rocky Linux">
</p>

不同发行版的软件包、网络栈和服务管理方式存在差异，脚本会根据当前系统能力开放对应功能。

## 效果图预览

<p>
  <img src="https://kejilion.sh/img/screenshots/kejilionsh.webp" alt="科技lion一键脚本中文版" width="49%">
  <img src="https://kejilion.sh/img/screenshots/kejilionsh_en.webp" alt="KejiLion Shell Script English Version" width="49%">
</p>

## 核心功能

- **系统信息概览**：快速展示 CPU、内存、磁盘、带宽等运行状态。<br>
  *System status overview: CPU, memory, disk, bandwidth, and more.*
- **网络测试工具**：集成测速、回程、延迟、丢包检测等工具。<br>
  *Network tools: speed tests, route tracing, latency, and packet loss tests.*
- **Docker 容器管理**：提供容器、镜像、网络、存储卷和日志管理。<br>
  *Docker management for containers, images, networks, volumes, and logs.*
- **LDNMP 一键部署**：快速搭建 Nginx、MySQL、PHP、Redis 网站环境。<br>
  *One-click LDNMP stack deployment for Nginx, MySQL, PHP, and Redis.*
- **网站防御与优化**：提供 CC 防护、防爬虫、防火墙和性能优化。<br>
  *Website protection and optimization with anti-CC, anti-crawler, firewall, and tuning tools.*
- **备份与迁移**：支持站点和数据库备份、恢复与远程迁移。<br>
  *Backup and migration for websites, databases, restoration, and remote transfer.*
- **BBR 加速优化**：管理内核加速与网络拥塞控制算法。<br>
  *Network acceleration and TCP congestion control optimization.*
- **应用市场集成**：一键安装和管理常用面板、服务与应用。<br>
  *App market integration for one-click deployment and management.*
- **自动更新机制**：检测脚本版本并提供更新入口。<br>
  *Update detection keeps the script features current.*

## KPanel Web 管理面板

偏好浏览器操作时，可以通过 `kejilion.sh` 应用入口一键部署 KPanel：

```bash
bash <(curl -sL kejilion.sh) app kpanel
```

KPanel 是 `kejilion.sh` 的现代 Web 管理形态。脚本、SSH、Docker Compose 和 KPanel
创建的真实资源可以互相发现并继续管理。

- [KPanel GitHub 项目](https://github.com/kejilion/KPanel)
- [KPanel 一键部署与功能介绍](https://blog.kejilion.pro/kpanel-kejilion-web-server-panel/)

## 项目文档

- [脚本更新日志](kejilion_sh_log.txt)
- [应用市场说明](apps/README.md)
- [问题反馈](https://github.com/kejilion/sh/issues)
- [科技lion官方网站](https://kejilion.sh/)

## 使用与安全

- 仅从官方域名和本仓库获取脚本，执行前可先审阅源码。
- 重要网站、数据库、Docker 数据和系统配置应定期备份。
- 生产服务器执行升级、卸载、磁盘或网络操作前，应确认终端显示的影响范围。
- 提交问题时，请隐藏密码、Token、私钥和公网 IP 等敏感信息。

## 支持我们

觉得脚本还可以，欢迎 Star、反馈问题或参与改进。

Feel free to support the project with USDT TRC20:

```text
TCP3PLGUTG9Z4z4tnHHSLbw5bgp8NXhTT3
```

## 开源许可

本项目采用 [Apache License 2.0](LICENSE) 开源。

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=kejilion/sh&type=Date)](https://star-history.com/#kejilion/sh&Date)
