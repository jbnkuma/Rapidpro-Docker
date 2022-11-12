# Alpine Linux  with GEOS, GDAL, and Proj installed
FROM alpine:latest
ARG RAPIDPRO_VERSION
ENV PIP_RETRIES=120 \
    PIP_TIMEOUT=400 \
    PIP_DEFAULT_TIMEOUT=400 \
    PIP_NO_CACHE_DIR=true \
    C_FORCE_ROOT=1 
# TODO determine if a more recent version of Node is needed
RUN apk --no-cache update
RUN \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && echo "ipv6" >> /etc/modules
#Install python from package for rapidpro 6.4.8 o later 
RUN apk add --no-cache  nodejs \ 
                        npm \
                        bash \ 
                        wget \ 
                        python3 \ 
                        python3-dev \
                        gdal \
                        libffi-dev \
                        linux-headers \
                        build-base \
                        postgresql-dev \
                        git \
                        tzdata \
                        xz \
                        gcc \ 
                        libffi-dev \
                        openssl-dev \
                        make \ 
                        zlib-dev \
                        libc-dev \
                        bash-doc \
                        bash-completion \
                        geos 
#Use in rapidpro v6.2.4 before used  poetry.

#WORKDIR /

#RUN wget -O Python-3.6.11.tar.xz http://www.python.org/ftp/python/3.6.11/Python-3.6.11.tar.xz && \
#    tar -xvf Python-3.6.11.tar.xz
#RUN rm Python-3.6.11.tar.xz  

#WORKDIR /Python-3.6.11
#RUN ./configure --prefix=/usr           
#RUN make -j8
#RUN make install
#RUN wget https://bootstrap.pypa.io/get-pip.py
#RUN python3 get-pip.py
#RUN pip install --upgrade pip
#RUN rm -rf /root/Python-3.6.11


RUN set -ex \
  && npm install -g coffee-script less bower 
#Use in rapidpro v6.2.4 before used  poetry.
#WORKDIR /
# Build Python virtualenv
#RUN pip install virtualenv
#RUN virtualenv /venv --python=/usr/bin/python3

WORKDIR /rapidpro

ARG RAPIDPRO_VERSION
ARG RAPIDPRO_REPO
ENV RAPIDPRO_VERSION=${RAPIDPRO_VERSION:-master}
ENV RAPIDPRO_REPO=${RAPIDPRO_REPO:-rapidpro/rapidpro}
RUN echo "Downloading RapidPro ${RAPIDPRO_VERSION} from https://github.com/$RAPIDPRO_REPO/archive/${RAPIDPRO_VERSION}.tar.gz" && \
    wget -O rapidpro.tar.gz "https://github.com/$RAPIDPRO_REPO/archive/${RAPIDPRO_VERSION}.tar.gz" && \
    tar -xf rapidpro.tar.gz --strip-components=1 && \
    rm rapidpro.tar.gz

#Use in rapidpro v6.2.4 before used  poetry.
#COPY pip-freeze.txt /app/requirements.txt
#RUN cp /rapidpro/pip-freeze.txt /app/requirements.txt
#RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/venv/bin/pip install setuptools getenv rapidpro-expressions whitenoise django-cache-url django-getenv uwsgi jsondiff urlparse2 antlr4-python3-runtime" \
#    && LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/venv/bin/pip install -r /app/requirements.txt" 
#RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/venv/bin/pip install raven setuptools getenv whitenoise django-cache-url django-getenv uwsgi jsondiff urlparse2" \
#    && LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/venv/bin/pip install -r /rapidpro/pip-freeze.txt"
#Use in rapidpro v6.4.8 or later
RUN wget -O get-poetry.py  https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py  
RUN python3 get-poetry.py -y --version 1.1.8
#RUN wget -O get-poetry.py  https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py  \
#        && LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/venv/bin/python get-poetry.py -y --version 1.1.8"
ENV PATH="$HOME/.poetry/bin:$PATH"
RUN cd /rapidpro 
RUN $HOME/.poetry/bin/poetry run python -m pip install --upgrade pip
RUN $HOME/.poetry/bin/poetry run pip install raven setuptools getenv whitenoise django-cache-url django-getenv uwsgi jsondiff urlparse2
RUN $HOME/.poetry/bin/poetry install
ENV PATH "$PATH:/usr/bin/"
RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "/usr/bin/git --version"
RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "ln -sf /usr/bin/git /usr/local/bin/git"
RUN cd /rapidpro && npm install npm@latest && npm install

#ENV UWSGI_VIRTUALENV=/venv UWSGI_WSGI_FILE=temba/wsgi.py UWSGI_HTTP=:8000 UWSGI_MASTER=1 UWSGI_WORKERS=8 UWSGI_HARAKIRI=300 UWSGI_BUFFER_SIZE=65535  
# Enable HTTP 1.1 Keep Alive options for uWSGI (http-auto-chunked needed when ConditionalGetMiddleware not installed)
# These options don't appear to be configurable via environment variables, so pass them in here instead
#Use in rapidpro v6.2.4 before used  poetry.
#ENV STARTUP_CMD="/venv/bin/uwsgi --http-auto-chunked --http-keepalive --buffer-size=10000000000000"
#ENV CELERY_BASE="/venv/bin/celery --beat --app=temba worker --loglevel=INFO --queues=celery,flows,handler"
#ENV CELERY_MSGS="/venv/bin/celery --app=temba worker --loglevel=INFO --queues=msgs,handler"
# Enable HTTP 1.1 Keep Alive options for uWSGI (http-auto-chunked needed when ConditionalGetMiddleware not installed)
# These options don't appear to be configurable via environment variables, so pass them in here instead
#Use in rapidpro v6.2.4 before used  poetry.
#Use for rapidpro 6.4.8 o later 
ENV STARTUP_CMD="/root/.poetry/bin/poetry run uwsgi --http-auto-chunked --http-keepalive --buffer-size=10000000000000"
ENV CELERY_BASE="/root/.poetry/bin/poetry run celery --beat --app=temba worker --loglevel=INFO --queues=celery,flows,handler"
ENV CELERY_MSGS="/root/.poetry/bin/poetry run celery --app=temba worker --loglevel=INFO --queues=msgs,handler"
COPY settings.py /rapidpro/temba/
# 500.html needed to keep the missing template from causing an exception during error handling
COPY stack/500.html /rapidpro/templates/
COPY stack/init_db.sql /rapidpro/
COPY stack/clear-compressor-cache.py /rapidpro/
COPY stack/*.json /rapidpro/
COPY Procfile /rapidpro/
COPY Procfile /
EXPOSE 8000
COPY stack/startup.sh /
COPY stack/startcelery.sh /usr/bin/
RUN ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "mkdir -p /usr/local/lib/"
RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "ln -sf /usr/lib/libgdal.so.28 /usr/lib/libgdal.so.27"
RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "ln -sf /usr/lib/libgdal.so.27 /usr/local/lib/libgdal.so"
RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "ln -sf /usr/lib/libgeos_c.so.1 /usr/local/lib/libgeos_c.so"
#RUN LIBRARY_PATH=/lib:/usr/lib /bin/sh -c "ln -sf /usr/lib/musl/lib/libc.so /usr/lib/libc.musl-x86_64.so.1"

LABEL org.label-schema.name="RapidPro" \
      org.label-schema.description="RapidPro allows organizations to visually build scalable interactive messaging applications." \
      org.label-schema.url="https://www.rapidpro.io/" \
      org.label-schema.vcs-url="https://github.com/$RAPIDPRO_REPO" \
      org.label-schema.vendor="Nyaruka, UNICEF, and individual contributors." \
      org.label-schema.version=$RAPIDPRO_VERSION \
      org.label-schema.schema-version="1.0"

CMD ["/startup.sh"]
