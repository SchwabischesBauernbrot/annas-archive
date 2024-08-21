# syntax=docker/dockerfile:1.9

FROM node:16.15.1-bullseye-slim AS assets

WORKDIR /app/assets
ENV YARN_CACHE_FOLDER=/.yarn

ARG UID=1000
ARG GID=1000
RUN groupmod -g "${GID}" node && usermod -u "${UID}" -g "${GID}" node

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=tmpfs,target=/usr/share/doc \
  --mount=type=tmpfs,target=/usr/share/man \
  # allow docker to cache the packages outside of the image
  rm -f /etc/apt/apt.conf.d/docker-clean \
  # update the package list
  && apt-get update \
  # upgrade any installed packages
  && apt-get upgrade -y

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=tmpfs,target=/usr/share/doc \
  --mount=type=tmpfs,target=/usr/share/man \
  apt-get install -y --no-install-recommends build-essential

RUN --mount=type=cache,target=${YARN_CACHE_FOLDER} \
  mkdir -p /node_modules && chown node:node -R /node_modules /app "$YARN_CACHE_FOLDER"

USER node

COPY --chown=node:node assets/package.json assets/*yarn* ./

RUN --mount=type=cache,target=${YARN_CACHE_FOLDER} \
  yarn install

ARG NODE_ENV="production"
ENV NODE_ENV="${NODE_ENV}"
ENV PATH="${PATH}:/node_modules/.bin"
ENV USER="node"

COPY --chown=node:node . ..

RUN if [ "${NODE_ENV}" != "development" ]; then \
  ../run yarn:build:js && ../run yarn:build:css; else mkdir -p /app/public; fi

CMD ["bash"]

###############################################################################

FROM --platform=linux/amd64 python:3.10.5-slim-bullseye AS base

SHELL ["/bin/bash", "-o", "pipefail", "-eu", "-c"]
WORKDIR /app

RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=tmpfs,target=/usr/share/doc \
  --mount=type=tmpfs,target=/usr/share/man \
  # allow docker to cache the packages outside of the image
  rm -f /etc/apt/apt.conf.d/docker-clean \
  # update the list of sources
  && sed -i -e 's/ main/ main contrib non-free archive stretch /g' /etc/apt/sources.list \
  # update the package list
  && apt-get update \
  # upgrade any installed packages
  && apt-get upgrade -y

# install the packages we need
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=tmpfs,target=/usr/share/doc \
  --mount=type=tmpfs,target=/usr/share/man \
  apt-get install -y --no-install-recommends \
  aria2 \
  build-essential \
  ca-certificates \
  checkinstall \
  cmake \
  ctorrent \
  curl \
  default-libmysqlclient-dev \
  g++ \
  gcc \
  git \
  gnupg \
  libatomic1 \
  libglib2.0-0 \
  libpq-dev \
  make \
  mariadb-client \
  p7zip \
  p7zip-full \
  p7zip-rar \
  parallel \
  pigz \
  pv \
  rclone \
  sshpass \
  unrar \
  wget


FROM base AS zstd
ADD https://github.com/facebook/zstd.git#v1.5.6 /zstd
WORKDIR /zstd
# install zstd, because t2sz requires zstd to be installed to be built
RUN make
# checkinstall is like `make install`, but creates a .deb package too
RUN checkinstall --default --pkgname zstd && mv zstd_*.deb /zstd.deb


FROM zstd AS t2sz
ADD https://github.com/martinellimarco/t2sz.git#v1.1.2 /t2sz
WORKDIR /t2sz/build
RUN cmake .. -DCMAKE_BUILD_TYPE="Release"
RUN make
RUN checkinstall --install=no --default --pkgname t2sz && mv t2sz_*.deb /t2sz.deb


FROM base AS pydeps
COPY --link requirements*.txt ./
RUN --mount=type=cache,target=/root/.cache/pip \
  <<eot
  pip3 install --no-warn-script-location -r requirements.txt -t /py

  # If requirements.txt is newer than the lock file or the lock file does not exist.
  if [ requirements.txt -nt requirements-lock.txt ]; then
    pip3 freeze > requirements-lock.txt
  fi

  pip3 install --no-warn-script-location -r requirements.txt -c requirements-lock.txt -t /py --upgrade
eot


FROM base AS app

# https://github.com/nodesource/distributions
ENV NODE_MAJOR=20
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
  --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=tmpfs,target=/usr/share/doc \
  --mount=type=tmpfs,target=/usr/share/man \
  <<eot
  set -eux -o pipefail

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

  apt-get update
  apt-get install nodejs -y --no-install-recommends
eot

ENV WEBTORRENT_VERSION=5.1.2
RUN --mount=type=cache,target=/root/.npm \
  npm install -g "webtorrent-cli@${WEBTORRENT_VERSION}" && webtorrent --version

ENV ELASTICDUMP_VERSION=6.110.0
RUN --mount=type=cache,target=/root/.npm \
  npm install -g "elasticdump@${ELASTICDUMP_VERSION}"

# Install latest zstd, with support for threading for t2sz
COPY --from=zstd --link /zstd.deb /
RUN dpkg -i /zstd.deb && rm -f /zstd.deb

# Install t2sz
COPY --from=t2sz --link /t2sz.deb /
RUN dpkg -i /t2sz.deb && rm -f /t2sz.deb

# Env for t2sz finding latest libzstd
ENV LD_LIBRARY_PATH=/usr/local/lib

ENV MYDUMPER_VERSION=0.16.3-3
ADD --link https://github.com/mydumper/mydumper/releases/download/v${MYDUMPER_VERSION}/mydumper_${MYDUMPER_VERSION}.bullseye_amd64.deb ./mydumper.deb 
RUN dpkg -i mydumper.deb

# install the python dependencies
COPY --from=pydeps --link /py /usr/local/lib/python3.10/site-packages

# Download models
RUN python3 -c 'import fast_langdetect; fast_langdetect.detect("dummy")'
# RUN python3 -c 'import sentence_transformers; sentence_transformers.SentenceTransformer("intfloat/multilingual-e5-small")'

ARG FLASK_DEBUG="false"
ENV FLASK_DEBUG="${FLASK_DEBUG}"
ENV FLASK_APP="allthethings.app"
ENV FLASK_SKIP_DOTENV="true"
ENV PYTHONUNBUFFERED="true"
ENV PYTHONPATH="."
ENV PYTHONFAULTHANDLER=1

COPY --from=assets --link /app/public /public
COPY --link . .

# RUN if [ "${FLASK_DEBUG}" != "true" ]; then \
#   ln -s /public /app/public && flask digest compile && rm -rf /app/public; fi

ENTRYPOINT ["/app/bin/docker-entrypoint-web"]

EXPOSE 8000

CMD ["gunicorn", "-c", "python:config.gunicorn", "allthethings.app:create_app()"]
