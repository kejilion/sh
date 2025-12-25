# 🚀 开发者应用入驻指南 (kejilion.sh)

欢迎为 `kejilion.sh` 贡献应用！通过在 `sh/apps/` 目录下创建 `.conf` 配置文件，您的应用将自动集成到脚本的应用市场中。

---

## 1. 快速开始
在 `sh/apps/` 目录下创建一个以应用名命名的配置文件，例如：`myapp.conf`。

## 2. 配置文件模板
每个配置文件应严格遵循以下结构，确保变量和函数命名规范：

```bash
# --- 基础信息 ---
local app_id="1000以上"
local app_name="应用显示名称"
local app_text="一句话简介，说明应用用途"
local app_url="示例官网: https://github.com/kejilion/sh/edit/main/apps"
local docker_name="容器启动后的名称"
local docker_port="默认访问端口"
local app_size="占用空间大小 (1-10)设置10代表要求10G空间才能装"

# --- 核心逻辑 ---

# 1. 安装函数
docker_app_install() {
    # 必须在 /home/docker/ 下创建应用目录
    mkdir -p /home/docker/myapp && cd /home/docker/myapp
    
    # 下载并配置 compose 文件
    curl -L -o docker-compose.yml "${gh_proxy}[raw.githubusercontent.com/](https://raw.githubusercontent.com/)..."
    
    # 端口处理（使用变量以便用户自定义）
    sed -i "s/8080:8080/${docker_port}:8080/g" docker-compose.yml
    
    # 启动容器
    docker compose up -d
    
    echo "安装完成"
}

# 2. 更新函数
docker_app_update() {
    cd /home/docker/myapp
    docker compose pull
    docker compose up -d
    echo "更新完成"
}

# 3. 卸载函数
docker_app_uninstall() {
    cd /home/docker/myapp
    docker compose down --rmi all
    rm -rf /home/docker/myapp
    echo "卸载完成"
}

# --- 结尾必须包含此行以完成注册 ---
docker_app_plus


```

## 3. 强制规范与原则

### 📁 目录路径规范
> **核心原则：数据不入系统盘，统一归档。**

* **【必须】**：所有持久化数据（Volume/Bind Mount）必须存储在 `/home/docker/[应用名]` 目录下。
* **【禁止】**：严禁将数据存放在 `/root`、`/etc`、`/var/lib` 或其他非指定根目录。
* **【理由】**：统一路径方便用户进行一键备份、整机迁移以及权限的统一管理。

### 🔄 容器生命周期
* **开机自启**：生成的 `docker-compose.yml` 中必须包含 `restart: always` 或 `restart: unless-stopped`。
* **干净卸载**：`docker_app_uninstall` 函数必须执行闭环操作，包含：
    * 停止并删除容器 (`docker compose down`)
    * 删除对应的镜像 (`--rmi all`)
    * **彻底物理删除** `/home/docker/[应用名]` 目录。

### 🆔 变量与语法说明
* **App ID**：当前版本已弱化 ID 概念，您可以省略或填入任意数值，系统目前主要以 `.conf` 文件名作为唯一识别依据。
* **Local 关键字**：由于配置文件是在函数内部被 `source` 加载的，请务必保留 `local` 声明，这能有效防止变量污染脚本的全局环境。

### 🌐 网络优化
* **镜像加速**：下载 GitHub 资源（如 `.yml` 或 `脚本`）时，请务必在 URL 前加上 `${gh_proxy}` 变量，以确保国内服务器的访问成功率。


---


## 4. 快捷启动与调用

一旦您的 `.conf` 文件被合入仓库，该应用将自动进入 **“第三方应用入驻”** 模块。此外，开发者可以向用户提供专属的极简安装指令：

#### 🚀 快捷安装指令模板：
```bash
bash <(curl -sL kejilion.sh) app [文件名]
```
示例：如果您的配置文件名为 myapp.conf，则调用指令为： bash <(curl -sL kejilion.sh) app myapp


---


## 5. 入驻流程

1.  **本地自测**：在自己的 VPS 上完整运行安装、更新、卸载流程，确保无报错。
2.  **路径审计**：检查 `/home/docker/` 目录下是否正确生成了应用文件夹，且没有文件“溢出”到其他地方。
3.  **提交申请**：将您的 `[应用名].conf` 文件通过 **Pull Request** 提交至本仓库的 `sh/apps/` 目录。
4.  **审核发布**：维护者审核逻辑安全后，您的应用将正式上线 `kejilion.sh` 菜单。
