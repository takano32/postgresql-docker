# 箱に1台の共有 PostgreSQL。PGroonga（日本語の全文検索）と pgvector（ベクトル検索）を同梱する。
#
# ベースは PGroonga 公式イメージ（PostgreSQL 18 + PGroonga 4.1.0、Debian 13、amd64/arm64）。
# PGroonga 公式イメージには PGDG の apt リポジトリが入っているので、そこから pgvector を足す。
# Hindsight 本家の docker/docker-compose/pgroonga/Dockerfile と同じ作り（版だけ新しい）。
FROM groonga/pgroonga:4.1.0-debian-18

# pgvector。版を固定する（arm64 の候補は 2026-10-16 時点で 0.8.7-1.pgdg13+1）。
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-18-pgvector=0.8.7-1.pgdg13+1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
