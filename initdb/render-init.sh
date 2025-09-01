#!/bin/sh
set -e

TPL=/docker-entrypoint-initdb.d/00-create-dbs-and-users.sql.tpl
OUT=/docker-entrypoint-initdb.d/00-create-dbs-and-users.sql

# only render once
if [ -f "$OUT" ]; then
  echo "Init SQL already exists; skipping render."
  exit 0
fi

# fix CRLF if present (dos2unix may not be installed)
if command -v dos2unix >/dev/null 2>&1; then
  dos2unix "$TPL" || true
else
  # sed fallback: remove CR (\r) characters
  sed -i 's/\r$//' "$TPL" || true
fi

# If envsubst available, use it (safe for arbitrary content).
if command -v envsubst >/dev/null 2>&1; then
  envsubst < "$TPL" > "$OUT"
else
  # Fallback: escape values for sed replacements (handles / and &)
  escape_for_sed() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
  }

  sed \
    -e "s|${JOIN_DB}|$(escape_for_sed "${JOIN_DB:-}")|g" \
    -e "s|${JOIN_DB_USER}|$(escape_for_sed "${JOIN_DB_USER:-}")|g" \
    -e "s|${JOIN_DB_PASSWORD}|$(escape_for_sed "${JOIN_DB_PASSWORD:-}")|g" \
    -e "s|${CODERR_DB}|$(escape_for_sed "${CODERR_DB:-}")|g" \
    -e "s|${CODERR_DB_USER}|$(escape_for_sed "${CODERR_DB_USER:-}")|g" \
    -e "s|${CODERR_DB_PASSWORD}|$(escape_for_sed "${CODERR_DB_PASSWORD:-}")|g" \
    -e "s|${VIDEOFLIX_DB}|$(escape_for_sed "${VIDEOFLIX_DB:-}")|g" \
    -e "s|${VIDEOFLIX_DB_USER}|$(escape_for_sed "${VIDEOFLIX_DB_USER:-}")|g" \
    -e "s|${VIDEOFLIX_DB_PASSWORD}|$(escape_for_sed "${VIDEOFLIX_DB_PASSWORD:-}")|g" \
    "$TPL" > "$OUT"
fi

echo "Rendered init SQL:"
ls -l /docker-entrypoint-initdb.d || true
cat "$OUT" || true