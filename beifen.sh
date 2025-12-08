#!/bin/bash

# Create a tar archive of the web directory
cd /home/ && tar czvf web_$(date +"%Y%m%d%H%M%S").tar.gz web

# Transfer the tar archive to Rclone Remote
cd /home/ && ls -t /home/*.tar.gz | head -1 | xargs -I {} rclone copy {} rclone:backup

# Keep only 5 tar archives and delete the rest
cd /home/ && ls -t /home/*.tar.gz | tail -n +6 | xargs -I {} rm {}