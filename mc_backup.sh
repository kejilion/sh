#!/bin/bash
clear
mkdir -p /home/game
docker cp mcserver:/data /home/game/mc
cd /home/game/mc && tar czvf mc_$(date +"%Y%m%d%H%M%S").tar.gz mc
rm -rf /home/game/mc/
echo -e "\033[0;32m游戏存档已导出存放在: /home/game/mc/\033[0m"
