#!/bin/bash

# 设置OpenSSH的版本号
OPENSSH_VERSION=$(curl -s https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/ | grep -oP 'openssh-\K[0-9]+\.[0-9]+p[0-9]+' | sort -V | tail -n 1)
SOURCE_ARCHIVE="openssh-${OPENSSH_VERSION}.tar.gz"
SOURCE_DIR=""
DOWNLOAD_DIR=$(pwd)
DEPENDENCY_PACKAGES=()
REMOVABLE_PACKAGES=()


# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统类型。"
    exit 1
fi

# 等待并检查锁文件
wait_for_lock() {
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "等待dpkg锁释放..."
        sleep 1
    done
}

# 修复dpkg中断问题
fix_dpkg() {
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}

# 检查软件包是否已安装
is_package_installed() {
    local package=$1
    case $OS in
        ubuntu|debian)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "ok installed"
            ;;
        centos|rhel|almalinux|rocky|fedora)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        alpine)
            apk info -e "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# 只记录本次升级新增的构建依赖，避免误删系统原有软件包
track_removable_packages() {
    REMOVABLE_PACKAGES=()
    local package

    for package in "${DEPENDENCY_PACKAGES[@]}"; do
        case "$package" in
            wget|ntpdate)
                continue
                ;;
        esac

        if ! is_package_installed "$package"; then
            REMOVABLE_PACKAGES+=("$package")
        fi
    done
}

# 安装依赖包
install_dependencies() {
    case $OS in
        ubuntu|debian)
            DEPENDENCY_PACKAGES=(build-essential zlib1g-dev libssl-dev libpam0g-dev wget ntpdate)
            track_removable_packages
            wait_for_lock
            fix_dpkg
            DEBIAN_FRONTEND=noninteractive apt update
            DEBIAN_FRONTEND=noninteractive apt install -y -o Dpkg::Options::="--force-confnew" "${DEPENDENCY_PACKAGES[@]}"
            ;;
        centos|rhel|almalinux|rocky|fedora)
            DEPENDENCY_PACKAGES=(gcc make zlib-devel openssl-devel pam-devel wget ntpdate)
            if [ "$OS" != "fedora" ]; then
                DEPENDENCY_PACKAGES=(epel-release "${DEPENDENCY_PACKAGES[@]}")
            fi
            track_removable_packages
            yum install -y "${DEPENDENCY_PACKAGES[@]}"
            ;;
        alpine)
            DEPENDENCY_PACKAGES=(build-base zlib-dev openssl-dev pam-dev wget ntpdate)
            track_removable_packages
            apk add "${DEPENDENCY_PACKAGES[@]}"
            ;;
        *)
            echo "不支持的操作系统：$OS"
            exit 1
            ;;
    esac
}


# 下载、编译和安装OpenSSH
install_openssh() {
    wget --no-check-certificate "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/${SOURCE_ARCHIVE}"

    # 解压最新的 .tar.gz 文件
    tar -xzf "$SOURCE_ARCHIVE"

    # 获取解压出来的目录名并进入（自动适配）
    DIR_NAME=$(tar -tzf "$SOURCE_ARCHIVE" | head -1 | cut -f1 -d"/")
    SOURCE_DIR="$DIR_NAME"
    cd "$DIR_NAME"


    ./configure
    make
    make install
}

# 重启SSH服务
restart_ssh() {
    mv /usr/bin/ssh /usr/bin/ssh.bak
    ln -s /usr/local/bin/ssh /usr/bin/ssh
    case $OS in
        ubuntu|debian)
            systemctl restart ssh
            ;;
        centos|rhel|almalinux|rocky|fedora)
            systemctl restart sshd
            ;;
        alpine)
            rc-service sshd restart
            ;;
        *)
            echo "不支持的操作系统：$OS"
            exit 1
            ;;
    esac
}

# 设置路径优先级
set_path_priority() {
    NEW_SSH_PATH=$(which sshd)  # 假设新版本的sshd和ssh在同一个目录
    NEW_SSH_DIR=$(dirname "$NEW_SSH_PATH")

    if [[ ":$PATH:" != *":$NEW_SSH_DIR:"* ]]; then
        export PATH="$NEW_SSH_DIR:$PATH"
        echo "export PATH=\"$NEW_SSH_DIR:\$PATH\"" >> ~/.bashrc
    fi
}

# 验证更新
verify_installation() {
    echo "SSH版本信息："
    ssh -V
    sshd -V
}

# 清理下载的文件
remove_dependencies() {
    if [ ${#REMOVABLE_PACKAGES[@]} -eq 0 ]; then
        return
    fi

    case $OS in
        ubuntu|debian)
            wait_for_lock
            DEBIAN_FRONTEND=noninteractive apt remove -y --purge "${REMOVABLE_PACKAGES[@]}"
            DEBIAN_FRONTEND=noninteractive apt autoremove -y --purge
            ;;
        centos|rhel|almalinux|rocky|fedora)
            yum remove -y "${REMOVABLE_PACKAGES[@]}"
            yum autoremove -y >/dev/null 2>&1 || true
            ;;
        alpine)
            apk del "${REMOVABLE_PACKAGES[@]}"
            ;;
    esac
}

clean_package_cache() {
    case $OS in
        ubuntu|debian)
            DEBIAN_FRONTEND=noninteractive apt clean
            rm -rf /var/lib/apt/lists/*
            ;;
        centos|rhel|almalinux|rocky|fedora)
            yum clean all
            rm -rf /var/cache/yum
            rm -rf /var/cache/dnf
            ;;
        alpine)
            rm -rf /var/cache/apk/*
            ;;
    esac
}

clean_up() {
    remove_dependencies
    clean_package_cache

    cd "$DOWNLOAD_DIR" || return 1
    rm -f "$SOURCE_ARCHIVE"
    if [ -n "$SOURCE_DIR" ]; then
        rm -rf "$SOURCE_DIR"
    fi
}


# 标题
check_openssh_test() {
echo "SSH高危漏洞修复工具"
echo "视频介绍: https://www.bilibili.com/video/BV1dm421G7dy?t=0.1"
echo "--------------------------"
}

# 检查OpenSSH版本
check_openssh_version() {
    current_version=$(ssh -V 2>&1 | awk '{print $1}' | cut -d_ -f2 | cut -d'p' -f1)

    # 版本范围
    min_version=8.5
    max_version=9.8

    if awk -v ver="$current_version" -v min="$min_version" -v max="$max_version" 'BEGIN{if(ver>=min && ver<=max) exit 0; else exit 1}'; then
      check_openssh_test
      echo "SSH版本: $current_version  在8.5到9.8之间，需要修复。"
      read -p "确定继续吗？(Y/N): " choice
          case "$choice" in
            [Yy])
              install_dependencies
              install_openssh
              restart_ssh
              set_path_priority
              verify_installation
              clean_up

              ;;
            [Nn])
              echo "已取消"
              exit 1
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              exit 1
              ;;
          esac
    else
      check_openssh_test
      echo "SSH版本: $current_version  不在8.5到9.8之间，无需修复。"
      exit 1
    fi

}


check_openssh_version
