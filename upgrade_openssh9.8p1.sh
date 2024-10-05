#!/bin/bash

# 设置OpenSSH的版本号
OPENSSH_VERSION="9.9p1"


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
    case $OS in
        ubuntu|debian)
            wait_for_lock
            fix_dpkg
            DEBIAN_FRONTEND=noninteractive apt update
            DEBIAN_FRONTEND=noninteractive apt install -y build-essential zlib1g-dev libssl-dev libpam0g-dev wget ntpdate -o Dpkg::Options::="--force-confnew"
            ;;
        centos|rhel|almalinux|rocky|fedora)
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
clean_up() {
    cd ..
    rm -rf openssh-${OPENSSH_VERSION}*
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
    max_version=9.7

    if awk -v ver="$current_version" -v min="$min_version" -v max="$max_version" 'BEGIN{if(ver>=min && ver<=max) exit 0; else exit 1}'; then
      check_openssh_test
      echo "SSH版本: $current_version  在8.5到9.7之间，需要修复。"
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
      echo "SSH版本: $current_version  不在8.5到9.7之间，无需修复。"
      exit 1
    fi

}


check_openssh_version
