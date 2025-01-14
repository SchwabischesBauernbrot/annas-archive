#!/bin/bash

set -Eeuxo pipefail

# Run this script by running: docker exec -it aa-data-import--web /scripts/load_aac_duxiu_files.sh
# Feel free to comment out steps in order to retry failed parts of this script, when necessary.
# Load scripts are idempotent, and can be rerun without losing too much work.

cd /temp-dir/aac_duxiu_files

rm -f /file-data/annas_archive_meta__aacid__duxiu_files__*
mv annas_archive_meta__aacid__duxiu_files__*.jsonl.seekable.zst /file-data/
