#!/bin/bash

# 设置OpenSSH的版本号
OPENSSH_VERSION="9.8p1"
MIN_OPENSSH_VERSION="8.5"
MAX_OPENSSH_VERSION="9.7"

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

# 安装依赖包
install_dependencies() {
    wait_for_lock
    case $OS in
        ubuntu|debian)
            DEBIAN_FRONTEND=noninteractive apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential zlib1g-dev libssl-dev libpam0g-dev wget ntpdate -o Dpkg::Options::="--force-confnew"
            ;;
        centos|rhel|fedora)
            yum install -y epel-release
            yum groupinstall -y "Development Tools"
            yum install -y zlib-devel openssl-devel pam-devel wget ntpdate
            ;;
        alpine)
            apk add build-base zlib-dev openssl-dev pam-dev wget ntpdate
            ;;
        *)
            echo "不支持的操作系统：$OS"
            exit 1
            ;;
    esac
}

# 同步系统时间
sync_time() {
    ntpdate time.nist.gov
}

# 检查OpenSSH版本
check_openssh_version() {
    CURRENT_VERSION=$(ssh -V 2>&1 | awk '{print $2}' | cut -d'p' -f1)
    if [[ "$CURRENT_VERSION" < "$MIN_OPENSSH_VERSION" || "$CURRENT_VERSION" > "$MAX_OPENSSH_VERSION" ]]; then
        echo "当前OpenSSH版本: $CURRENT_VERSION 无需修复！"
        exit 1
    fi
}

# 下载、编译和安装OpenSSH
install_openssh() {
    wget --no-check-certificate https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz
    tar -xzf openssh-${OPENSSH_VERSION}.tar.gz
    cd openssh-${OPENSSH_VERSION}
    ./configure
    make
    make install
}

# 重启SSH服务
restart_ssh() {
    case $OS in
        ubuntu|debian)
            systemctl restart ssh
            ;;
        centos|rhel|fedora)
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
clean_up() {
    cd ..
    rm -rf openssh-${OPENSSH_VERSION}*
}

# 主函数
main() {
    if [[ $OS == "ubuntu" || $OS == "debian" ]]; then
        fix_dpkg
    fi
    install_dependencies
    sync_time
    check_openssh_version
    install_openssh
    restart_ssh
    set_path_priority
    verify_installation
    clean_up
}

main