#!/bin/sh
set -ex # fail on any error & print commands as they're run
#/venv/bin/python clear-compressor-cache.py
#/venv/bin/python manage.py import_geojson *_simplified.json

startup_before_poetry () {

        if [ "x$MANAGEPY_COLLECTSTATIC" = "xon" ]; then
                 /venv/bin/python manage.py collectstatic --noinput --no-post-process
        fi
        if [ "x$CLEAR_COMPRESSOR_CACHE" = "xon" ]; then
                /venv/bin/python clear-compressor-cache.py
        fi
        if [ "x$MANAGEPY_COMPRESS" = "xon" ]; then
                /venv/bin/python manage.py compress --extension=".haml" --force -v0     
        fi
        if [ "x$MANAGEPY_INIT_DB" = "xon" ]; then
                set +x  # make sure the password isn't echoed to stdout
                echo "*:*:*:*:$(echo \"$DATABASE_URL\" | cut -d'@' -f1 | cut -d':' -f3)" > $HOME/.pgpass
                set -x
                chmod 0600 $HOME/.pgpass
                /venv/bin/python manage.py dbshell < init_db.sql
                rm $HOME/.pgpass
        fi
        if [ "x$MANAGEPY_MIGRATE" = "xon" ]; then
                /venv/bin/python manage.py migrate
        fi
        if [ "x$MANAGEPY_IMPORT_GEOJSON" = "xon" ]; then
                echo "Downloading geojson for relation_ids $OSM_RELATION_IDS"
                /venv/bin/python manage.py download_geojson $OSM_RELATION_IDS
                /venv/bin/python manage.py import_geojson ./geojson/*.json
                echo "Imported geojson for relation_ids $OSM_RELATION_IDS"
        fi
        
        if [ "x$IMPORT_GEOJSON" = "xon" ]; then
                echo "Downloading geojson"
                /venv/bin/python manage.py import_geojson *_simplified.json
                echo "Imported geojson"
        fi


        if [ "x$TYPE_CELERY_BASE" = "xon" ]; then
                $CELERY_BASE
        fi

        if [ "x$TYPE_CELERY_MSGS" = "xon" ]; then
                $CELERY_MSGS
        fi
        if [ "x$TYPE_RAPIDPRO" = "xon" ]; then
                /usr/bin/startcelery.sh &
	        $STARTUP_CMD
        fi

        #TYPE=${1:-rapidpro}
        #if [ "$TYPE" = "celery" ]; then
        #        $CELERY_CMD 
        #elif [ "$TYPE" = "rapidpro" ]; then
        #        $CELERY_CMD &
        #	$STARTUP_CMD &
        #fi
}

startup_poetry () {

        if [ "x$MANAGEPY_COLLECTSTATIC" = "xon" ]; then
                 $HOME/.poetry/bin/poetry run python manage.py collectstatic --noinput --no-post-process
        fi
        if [ "x$CLEAR_COMPRESSOR_CACHE" = "xon" ]; then
                $HOME/.poetry/bin/poetry  run python clear-compressor-cache.py
        fi
        if [ "x$MANAGEPY_COMPRESS" = "xon" ]; then
                $HOME/.poetry/bin/poetry  run python manage.py compress --extension=".haml" --force -v0     
        fi
        if [ "x$MANAGEPY_INIT_DB" = "xon" ]; then
                set +x  # make sure the password isn't echoed to stdout
                echo "*:*:*:*:$(echo \"$DATABASE_URL\" | cut -d'@' -f1 | cut -d':' -f3)" > $HOME/.pgpass
                set -x
                chmod 0600 $HOME/.pgpass
                $HOME/.poetry/bin/poetry  run python manage.py dbshell < init_db.sql
                rm $HOME/.pgpass
        fi
        if [ "x$MANAGEPY_MIGRATE" = "xon" ]; then
                $HOME/.poetry/bin/poetry  run python manage.py migrate
        fi
        if [ "x$MANAGEPY_IMPORT_GEOJSON" = "xon" ]; then
                echo "Downloading geojson for relation_ids $OSM_RELATION_IDS"
                $HOME/.poetry/bin/poetry  run python manage.py download_geojson $OSM_RELATION_IDS
                $HOME/.poetry/bin/poetry  run python manage.py import_geojson ./geojson/*.json
                echo "Imported geojson for relation_ids $OSM_RELATION_IDS"
        fi

        if [ "x$IMPORT_GEOJSON" = "xon" ]; then
                echo "Downloading geojson for relation_ids"
                $HOME/.poetry/bin/poetry  run python manage.py import_geojson *_simplified.json
                echo "Imported geojson"
        fi

        if [ "x$TYPE_CELERY_BASE" = "xon" ]; then
                $CELERY_BASE
        fi

        if [ "x$TYPE_CELERY_MSGS" = "xon" ]; then
                $CELERY_MSGS
        fi
        if [ "x$TYPE_RAPIDPRO" = "xon" ]; then
                /usr/bin/startcelery.sh &
                export UWSGI_VIRTUALENV=$($HOME/.poetry/bin/poetry show -v|grep "Using virtualenv"|cut -d : -f2 |xargs) 
                export UWSGI_WSGI_FILE=temba/wsgi.py 
                export UWSGI_HTTP=:8000 
                export UWSGI_MASTER=1 
                export UWSGI_WORKERS=8 
                export UWSGI_HARAKIRI=300 
                export UWSGI_BUFFER_SIZE=65535 
	        $STARTUP_CMD
        fi

        #TYPE=${1:-rapidpro}
        #if [ "$TYPE" = "celery" ]; then
        #        $CELERY_CMD 
        #elif [ "$TYPE" = "rapidpro" ]; then
        #        $CELERY_CMD &
        #	$STARTUP_CMD &
        #fi
}

if [ "x$POETRY" = "xon" ]; then
    startup_poetry
else
    startup_before_poetry
fi