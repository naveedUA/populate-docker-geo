#!/bin/bash
# Download a Geofabrik OpenStreetMap shapefile extract and load every layer into PostGIS.
#
# Environment (defaults set in the Dockerfile):
#   STATE      Geofabrik extract name, e.g. arizona
#   DATABASE   database to create or reuse, e.g. arizona
#   REGION     Geofabrik region path, default north-america/us
#   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD   connection to PostGIS
#
# Running it again reloads every table.
set -euo pipefail

for v in STATE DATABASE REGION DB_HOST DB_PORT DB_USER; do
  if [[ -z "${!v:-}" ]]; then
    echo "$v is required" >&2
    exit 1
  fi
done
export PGPASSWORD="${PGPASSWORD:-${DB_PASSWORD:-}}"
# Show warnings and errors only, not notices such as "table ... does not exist, skipping".
export PGOPTIONS="-c client_min_messages=warning"

PSQL=(psql -q -v ON_ERROR_STOP=1 -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER")

echo "==> Checking the connection to $DB_HOST:$DB_PORT"
if ! "${PSQL[@]}" -d postgres -c "SELECT 1" >/dev/null; then
  echo "Cannot connect to PostGIS at $DB_HOST:$DB_PORT." >&2
  echo "Is the postgis container running on the gist415 network (docker ps)?" >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

URL="https://download.geofabrik.de/${REGION}/${STATE}-latest-free.shp.zip"
echo "==> Downloading $URL (several hundred MB)"
curl -fL --progress-bar -o extract.zip "$URL"
unzip -q extract.zip

echo "==> Preparing database $DATABASE"
if [[ -z "$("${PSQL[@]}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '$DATABASE'")" ]]; then
  "${PSQL[@]}" -d postgres -c "CREATE DATABASE \"$DATABASE\""
fi
"${PSQL[@]}" -d "$DATABASE" -c "CREATE EXTENSION IF NOT EXISTS postgis"

# gis_osm_roads_free_1.shp -> roads, gis_osm_buildings_a_free_1.shp -> buildings_a,
# natural -> nature (natural is an SQL keyword), as in the original loader.
for f in gis_osm_*_free_1.shp; do
  t=${f#gis_osm_}
  t=${t%_free_1.shp}
  t=${t//natural/nature}
  echo "==> Loading $t"
  "${PSQL[@]}" -d "$DATABASE" -c "DROP TABLE IF EXISTS public.\"$t\""
  shp2pgsql -s 4326 -c -I -g geom -W UTF-8 "$f" "public.$t" 2>/dev/null | "${PSQL[@]}" -d "$DATABASE" >/dev/null
done

echo "==> Done. Tables in $DATABASE:"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DATABASE" -c "\dt"
