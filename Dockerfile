FROM ubuntu:16.04
LABEL maintainer="joe.jasinski@gmail.com"
RUN apt-get update && apt-get install -y build-essential git \
    libjpeg-dev libfreetype6 libfreetype6-dev zlib1g-dev \
    python3-dev python3-venv \
    libpq-dev postgresql-client && rm -rf /var/lib/apt/lists/*

RUN groupadd -r app && \
    useradd -r -g app -d /home/app -s /sbin/nologin -c "Docker image user" app


ENV SITE_DIR=/site/
ENV NUM_THREADS=2
ENV NUM_PROCS=2
ENV DJANGO_DATABASE_URL=postgres://postgres@db/postgres

RUN install -g app -o app -d $SITE_DIR

WORKDIR $SITE_DIR
RUN install -g app -o app -d proj/ var/log/ htdocs/
RUN find /site/ -type d -exec chmod g+s {} \;
RUN chmod -R g+w /site/
USER app
RUN python3 -m venv env/

RUN env/bin/pip install pip --upgrade
RUN env/bin/pip install uwsgi

COPY docker-utils/ssl/ ssl/
COPY requirements.txt requirements.txt
RUN env/bin/pip install -r requirements.txt
COPY docker-utils/ docker-utils/
COPY . proj/

RUN env/bin/python ./proj/manage.py collectstatic --noinput

EXPOSE 8000
CMD ["./docker-utils/app-start.sh"]
ENTRYPOINT ["./docker-utils/entrypoint.sh"]
