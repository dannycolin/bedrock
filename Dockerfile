########
# assets builder and dev server
#
FROM node:8-slim AS assets

ENV PATH=/app/node_modules/.bin:$PATH
WORKDIR /app

# copy dependency definitions
COPY package.json yarn.lock ./

# install dependencies
RUN yarn install --pure-lockfile
RUN yarn global add gulp-cli@2.0.1

# copy supporting files and media
COPY .eslintrc.js .stylelintrc gulpfile.js ./
COPY ./media ./media


########
# Python dependencies builder
#
FROM python:2-stretch AS python-builder

WORKDIR /app
ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/venv/bin:$PATH"

COPY docker/bin/apt-install /usr/local/bin/
RUN apt-install gettext build-essential libxml2-dev libxslt1-dev libxslt1.1

RUN virtualenv /venv

COPY requirements/base.txt requirements/prod.txt ./requirements/

# Install Python deps
RUN pip install --no-cache-dir -r requirements/prod.txt


########
# django app container
#
FROM python:2-slim-stretch AS app-base

# Extra python env
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PATH="/venv/bin:$PATH"

# add non-priviledged user
RUN adduser --uid 1000 --disabled-password --gecos '' --no-create-home webdev

WORKDIR /app
EXPOSE 8000
CMD ["./bin/run.sh"]

COPY docker/bin/apt-install /usr/local/bin/
RUN apt-install gettext libxslt1.1 git

# copy in Python environment
COPY --from=python-builder /venv /venv

# changes infrequently
COPY ./bin ./bin
COPY ./etc ./etc
COPY ./lib ./lib
COPY ./root_files ./root_files
COPY ./scripts ./scripts
COPY ./wsgi ./wsgi
COPY manage.py LICENSE newrelic.ini contribute.json ./

# changes more frequently
COPY ./docker ./docker
COPY ./vendor-local ./vendor-local
COPY ./bedrock ./bedrock
COPY ./media ./media


########
# expanded webapp image for testing and dev
#
FROM app-base AS devapp

CMD ["./bin/run-tests.sh"]

COPY requirements/base.txt requirements/dev.txt ./requirements/
RUN pip install --no-cache-dir -r requirements/dev.txt
COPY ./setup.cfg ./
COPY ./tests ./tests

# get fresh database
RUN ./bin/run-db-download.py --force

# get fresh l10n files
RUN ./manage.py l10n_update

# generate the sitemaps
RUN ./manage.py update_sitemaps

RUN chown webdev.webdev -R .
USER webdev


########
# build production assets
#
FROM assets AS assets-release
RUN gulp build --production


########
# final image for deployment
#
FROM app-base AS release

COPY --from=assets-release /app/static_final /app/static_final
RUN honcho run --env docker/envfiles/prod.env docker/bin/build_staticfiles.sh

# build args
ARG GIT_SHA=latest
ARG BRANCH_NAME=master
ENV GIT_SHA=${GIT_SHA}
ENV BRANCH_NAME=${BRANCH_NAME}

# rely on build args
RUN bin/run-sync-all.sh

RUN echo "${GIT_SHA}" > ./static/revision.txt

# Change User
RUN chown webdev.webdev -R .
USER webdev
