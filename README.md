# vps一键脚本工具

### vps一键脚本工具 的支持列表：
>Debian
>Ubuntu
>CentOS
***
### 一键脚本
```bash
apt update -y  && apt install -y curl && curl -sS -O https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh && chmod +x ssh_tool.sh && bash ssh_tool.sh
```
vps流量内存cpu控制一键脚本，配合cron定时任务使用
```bash
apt install -y net-tools bc && curl -sS -O https://raw.githubusercontent.com/eooce/ssh_tool/main/check_trafic.sh && chmod +x check_trafic.sh && bash check_trafic.sh
```
*/10 * * * * /bin/bash /root/check_trafic.sh >> /root/check.log 2>&1    将此段命令加入cron任务，每10分钟运行检查一次
