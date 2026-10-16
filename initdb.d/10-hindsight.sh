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

# PostgreSQL は既定で PUBLIC（全ロール）にどのデータベースへも CONNECT と TEMPORARY を与える。
# 管理用の postgres と template1 からは取り上げ、hindsight データベースは持ち主（hindsight ロール）だけが繋げるようにする。
# 別のサービスのデータベースを足すときも同じく REVOKE ... FROM PUBLIC してから、そのロールにだけ GRANT する（README）。
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -v db="$HINDSIGHT_DB_NAME" <<'EOSQL'
REVOKE CONNECT, TEMPORARY ON DATABASE postgres FROM PUBLIC;
REVOKE CONNECT, TEMPORARY ON DATABASE template1 FROM PUBLIC;
REVOKE CONNECT, TEMPORARY ON DATABASE :"db" FROM PUBLIC;
EOSQL

echo "initdb.d/10-hindsight.sh: role '${HINDSIGHT_DB_USER}' and database '${HINDSIGHT_DB_NAME}' created with vector + pgroonga"
