# vps一键脚本工具
加入常用节点搭建脚本合集

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
