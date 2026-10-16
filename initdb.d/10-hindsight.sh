#!/bin/bash
# 初回の initdb（データボリュームが空のとき）だけ走る。
# Hindsight 用のロールとデータベースを作り、そのデータベースに vector と pgroonga を入れる。
# pgroonga は trusted でないので CREATE EXTENSION にスーパーユーザーが要る。ここで postgres が作っておく。
set -euo pipefail

: "${HINDSIGHT_DB_USER:?}" "${HINDSIGHT_DB_NAME:?}" "${HINDSIGHT_DB_PASSWORD:?}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v user="$HINDSIGHT_DB_USER" -v pass="$HINDSIGHT_DB_PASSWORD" -v db="$HINDSIGHT_DB_NAME" <<'EOSQL'
CREATE ROLE :"user" LOGIN PASSWORD :'pass';
CREATE DATABASE :"db" OWNER :"user";
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$HINDSIGHT_DB_NAME" <<'EOSQL'
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgroonga;
EOSQL

echo "initdb.d/10-hindsight.sh: role '${HINDSIGHT_DB_USER}' and database '${HINDSIGHT_DB_NAME}' created with vector + pgroonga"
