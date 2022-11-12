#!/bin/sh
set -ex # fail on any error & print commands as they're run

startup_before_poetry () {
    /venv/bin/celery worker --app=temba -l info -Q celery,handler,flows,msgs &
}

startup_poetry (){
    $HOME/.poetry/bin/poetry run celery worker --app=temba -l info -Q celery,handler,flows,msgs &
}

if [ "x$POETRY" = "xon" ]; then
    startup_poetry
else
    startup_before_poetry
fi