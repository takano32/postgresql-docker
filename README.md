# postgresql-docker

箱に1台の共有 PostgreSQL。PostgreSQL 18（2026-10-16 時点の安定版の最新メジャー、18.6）に
PGroonga 4.1.0（日本語の全文検索）と pgvector 0.8.7（ベクトル検索）を入れてある。
ベースは PGroonga 公式イメージ `groonga/pgroonga:4.1.0-debian-18`（arm64 あり）。

## 使い方

```sh
cd ~/opt/postgresql-docker
docker compose build
docker compose up -d
docker compose logs -f postgresql     # 初回は initdb と initdb.d/ のスクリプトが走る
docker compose down                   # 止める（-v を付けなければデータは残る）
```

- ホストからは `127.0.0.1:5432` だけ。`psql -h 127.0.0.1 -U postgres`（パスワードは `.env` の `POSTGRES_PASSWORD`）。
- 別の compose から使うときは、その compose に network を足す。ホスト名は `postgresql`、ポートは 5432。

  ```yaml
  services:
    app:
      networks: [postgresql]
  networks:
    postgresql:
      external: true
  ```

- データは名前付きボリューム `postgresql_pgdata`（`/var/lib/postgresql`）。

## データベースを足す

初回の initdb で `initdb.d/10-hindsight.sh` が Hindsight 用のロールとデータベースを作る。
あとから別のサービスのぶんを足すときは postgres で入って作る（拡張はデータベースごと）。

```sh
docker compose exec postgresql psql -U postgres -c "CREATE ROLE myapp LOGIN PASSWORD '...';" \
  -c "CREATE DATABASE myapp OWNER myapp;"
docker compose exec postgresql psql -U postgres -d myapp \
  -c "CREATE EXTENSION IF NOT EXISTS vector;" -c "CREATE EXTENSION IF NOT EXISTS pgroonga;"
```

`pgroonga` は trusted でないので postgres（スーパーユーザー）で作る。`vector` は DB の所有者でも作れる。

## 設定

- メモリは共有の1台として控えめ（`compose.yml` の `command`）：shared_buffers 256MB、
  effective_cache_size 1GB、work_mem 8MB、maintenance_work_mem 128MB、max_connections 100。
- `.env`（chmod 600）：`POSTGRES_PASSWORD`、`HINDSIGHT_DB_USER`／`HINDSIGHT_DB_NAME`／`HINDSIGHT_DB_PASSWORD`。
  `.env` を変えても既存のロールのパスワードは変わらない（initdb.d は初回だけ）。変えるなら `ALTER ROLE`。

## 版を上げる

`Dockerfile` の `FROM` のタグと pgvector の版を上げて `docker compose build`。
PostgreSQL のメジャーを上げるときはデータの移行（pg_upgrade か dump/restore）が別に要る。
