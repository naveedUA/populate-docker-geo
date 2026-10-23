# populate-docker-geo

The GIST 415 data loader image, published as `naveedua/populate-docker-geo`. It contains `shp2pgsql` and `psql` that work with the course's PostGIS (`postgis/postgis:18-3.6-alpine`), and a script that loads a Geofabrik OpenStreetMap extract into PostGIS.

Rebuilt from [ua-gist-open-source/docker-compose-populate](https://github.com/ua-gist-open-source/docker-compose-populate) (MIT), which was built on the abandoned `mdillon/postgis` image and did not pass the database password to `psql`.

## Use

PostGIS must be running as `postgis` on the `gist415` network.

**Unit 6 Assignment 3: Arizona OpenStreetMap data** (downloads about 600 MB; creates or reloads the `arizona` database):

```
docker run --rm --network gist415 -e STATE=arizona -e DATABASE=arizona naveedua/populate-docker-geo:1.0 populate-postgis.sh
```

**Unit 5 Assignment 3: one NYC workshop shapefile** (replace the folder before the colon with your `postgis-workshop/data` folder):

```
docker run --rm --network gist415 -v C:/gist415_data/nyc_data/postgis-workshop/data:/data naveedua/populate-docker-geo:1.0 sh -c "shp2pgsql -s 26918 -c -g geom /data/nyc_census_blocks.shp public.nyc_census_blocks | psql -q -h postgis -U postgres -d nyc"
```

## Settings

| Variable | Default | Meaning |
|---|---|---|
| `STATE` | `arizona` | Geofabrik extract name |
| `DATABASE` | `arizona` | Database to create or reuse |
| `REGION` | `north-america/us` | Geofabrik region path |
| `DB_HOST`, `DB_PORT` | `postgis`, `5432` | Where PostGIS runs |
| `DB_USER`, `DB_PASSWORD` / `PGPASSWORD` | `postgres`, `postgres` | Database login |

## Build and publish

```
docker build -t naveedua/populate-docker-geo:1.0 -t naveedua/populate-docker-geo:latest .
docker login
docker push naveedua/populate-docker-geo:1.0
docker push naveedua/populate-docker-geo:latest
```

Course pages use the `1.0` tag, so a later rebuild never changes what students run. Publish changes as `1.1` and update the pages.

The image is amd64 only, like the PostGIS Alpine image it is built on; Apple Silicon Macs run it under emulation.
