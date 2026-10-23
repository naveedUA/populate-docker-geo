# GIST 415 data loader: shp2pgsql and psql for loading shapefiles into PostGIS.
#
# Based on ua-gist-open-source/docker-compose-populate (MIT, 2020), rebuilt on the
# same PostGIS image the course runs, so the tools match the server.
#
# Build:  docker build -t naveedua/populate-docker-geo:1.0 .
# Use:    docker run --rm --network gist415 -e STATE=arizona -e DATABASE=arizona naveedua/populate-docker-geo:1.0 populate-postgis.sh

FROM postgis/postgis:18-3.6-alpine

# The official Alpine image ships shp2pgsql, pgsql2shp and raster2pgsql without libintl,
# so they fail with "Error loading shared library libintl.so.8". bash, curl and unzip
# are for populate-postgis.sh.
RUN apk add --no-cache libintl bash curl unzip

# Defaults for the course stack: PostGIS runs as "postgis" on the gist415 network.
# PGPASSWORD lets psql log in without a prompt (there is no terminal to type it in).
ENV STATE=arizona \
    DATABASE=arizona \
    REGION=north-america/us \
    DB_HOST=postgis \
    DB_PORT=5432 \
    DB_USER=postgres \
    DB_PASSWORD=postgres \
    PGPASSWORD=postgres

COPY scripts/ /app/
RUN chmod 755 /app/*.sh
ENV PATH=/app:$PATH
WORKDIR /data

CMD ["populate-postgis.sh"]
