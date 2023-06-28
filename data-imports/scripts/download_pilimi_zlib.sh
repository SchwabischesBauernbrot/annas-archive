#!/bin/bash

set -Eeuxo pipefail

# Run this script by running: docker exec -it aa-data-import--mariadb /scripts/download_pilimi_zlib.sh
# Download scripts are idempotent but will RESTART the download from scratch!

cd /temp-dir

rm -f pilimi-zlib2-index-2022-08-24-fixed.sql.gz

ctorrent -e 0 /scripts/torrents/pilimi-zlib2-index-2022-08-24-fixed.torrent
