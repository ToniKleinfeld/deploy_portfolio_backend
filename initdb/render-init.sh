#!/bin/sh
set -e

TPL=/docker-entrypoint-initdb.d/00-create-dbs-and-users.sql.tpl
OUT=/docker-entrypoint-initdb.d/00-create-dbs-and-users.sql
OUT_TMP=/tmp/00-create-dbs-and-users.sql

echo "[initdb-render] running as uid=$(id -u) gid=$(id -g)"
echo "[initdb-render] TPL=$TPL OUT=$OUT"

# decide target: prefer OUT, fallback to /tmp if not writable
can_write_out() {
  # try to create temp file in same dir
  tmp="$(mktemp /docker-entrypoint-initdb.d/.write-check.XXXXXX 2>/dev/null || true)"
  if [ -n "$tmp" ]; then
    rm -f "$tmp" || true
    return 0
  fi
  return 1
}

TARGET="$OUT"
# only render once
if [ -f "$OUT" ]; then
  echo "[initdb-render] $OUT already exists; skipping render."
  exit 0
fi

# fix CRLF if present (dos2unix may not be installed)
if command -v dos2unix >/dev/null 2>&1; then
  dos2unix "$TPL" || true
else
  # sed fallback: remove CR (\r) characters
  sed -i 's/\r$//' "$TPL" || true
fi

if ! can_write_out; then
  echo "[initdb-render] cannot write to /docker-entrypoint-initdb.d, will render to $OUT_TMP"
  TARGET="$OUT_TMP"
fi

# render using envsubst if available, else sed fallback
if command -v envsubst >/dev/null 2>&1; then
  envsubst < "$TPL" > "$TARGET"
else
  # basic sed fallback (may need escaping for special chars)
  sed \
    -e "s|\${JOIN_DB}|${JOIN_DB:-}|g" \
    -e "s|\${JOIN_DB_USER}|${JOIN_DB_USER:-}|g" \
    -e "s|\${JOIN_DB_PASSWORD}|${JOIN_DB_PASSWORD:-}|g" \
    -e "s|\${CODERR_DB}|${CODERR_DB:-}|g" \
    -e "s|\${CODERR_DB_USER}|${CODERR_DB_USER:-}|g" \
    -e "s|\${CODERR_DB_PASSWORD}|${CODERR_DB_PASSWORD:-}|g" \
    -e "s|\${VIDEOFLIX_DB}|${VIDEOFLIX_DB:-}|g" \
    -e "s|\${VIDEOFLIX_DB_USER}|${VIDEOFLIX_DB_USER:-}|g" \
    -e "s|\${VIDEOFLIX_DB_PASSWORD}|${VIDEOFLIX_DB_PASSWORD:-}|g" \
    "$TPL" > "$TARGET"
fi

echo "Rendered to $TARGET:"
ls -l "$TARGET" || true
echo "---- start of rendered SQL ----"
sed -n '1,200p' "$TARGET" || true
echo "---- end of rendered SQL ----"

if [ "$TARGET" != "$OUT" ]; then
  echo "[initdb-render] WARNING: Could not write to container init dir. File is at $TARGET."
  echo "[initdb-render] If you want postgres to auto-run this file on init, ensure /docker-entrypoint-initdb.d is writable by the container user (eg. chown -R 999:999 ./initdb) or run the SQL manually:"
  echo "  docker exec -i <postgres-container> psql -U \"\$POSTGRES_USER\" -f $OUT_TMP"
fi