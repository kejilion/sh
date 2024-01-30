# vps一键脚本工具
集成各种vps常用工具，去掉繁琐操作，加入常用节点搭建脚本合集，一键母鸡开nat小鸡，一建脚本搞定所有

### vps一键脚本工具 的支持列表：
>Debian
>Ubuntu
>CentOS
>Alpine
>Fedora
>Rocky-linux
>Amazom-linux
>Oracle-linux
***
### 一键脚本
```bash
curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh
```
或
```bash
wget -qO ssh_tool.sh https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh
```

* 若提示没有curl或wget，先安装即可
* Ubuntu/Debian：apt-get install -y curl wget
* Alpine：apk add curl wget
* Fedora：dnf install -y curl wget
* CentOS/Rocky/Almalinux/Oracle-linux/Amazon-linux：yum install -y curl wget

vps流量内存cpu控制一键脚本，配合cron定时任务使用，这是自用脚本，如要使用需先查询网卡信息，修改check_trafic.sh里的网卡名称，和阈值设置等
```bash
apt install -y net-tools bc && curl -sS -O https://raw.githubusercontent.com/eooce/ssh_tool/main/check_trafic.sh && chmod +x check_trafic.sh && bash check_trafic.sh
```

### 鸣谢
kejilion
