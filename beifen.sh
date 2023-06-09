#!/bin/bash

# Create a tar archive of the web directory
cd /home/ && tar cvf web_$(date +"%Y%m%d%H%M%S").tar web

# Transfer the tar archive to another VPS
apt install -y sshpass
cd /home/ && ls -t /home/*.tar | head -1 | xargs -I {} sshpass -p 123456 scp -P 22 {} root@0.0.0.0:/home/

# Keep only 5 tar archives and delete the rest
cd /home/ && ls -t /home/*.tar | tail -n +4 | xargs -I {} rm {}
