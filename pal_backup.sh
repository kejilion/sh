#!/bin/bash
clear
mkdir -p /home/game
docker cp steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/ /home/game/palworld/
cd /home/game && tar czvf palworld_$(date +"%Y%m%d%H%M%S").tar.gz palworld
rm -rf /home/game/palworld/
echo -e "\033[0;32m游戏存档已导出存放在: /home/game/\033[0m"