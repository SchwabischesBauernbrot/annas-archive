#!/bin/bash

set -Eeuxo pipefail

mariadb -h ${MARIADB_HOST:-aa-data-import--mariadb} -u root -ppassword allthethings --show-warnings -vv < /scripts/helpers/check_after_imports.sql
