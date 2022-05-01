# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS octoprint-builder

RUN --mount=type=cache,target=/var/cache/apk \
  apk add \
    build-base \
    linux-headers \
    yq \
    jpeg-dev \
    zlib-dev

WORKDIR /build

ARG OCTOPRINT_VERSION

RUN \
  wget -O - "https://github.com/OctoPrint/OctoPrint/archive/${OCTOPRINT_VERSION}.tar.gz" \
  | tar xz --strip-components=1

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r requirements.txt

ARG CONFIG_PLUGINS
RUN --mount=source=${CONFIG_PLUGINS},target=plugins.yaml \
  LIBRARY_PATH=/lib:/usr/lib yq e '.plugins[] | .["x-plugin-url"]' - < plugins.yaml | xargs -n1 pip install


FROM ${BASE_IMAGE} AS octoprint

WORKDIR /root/.octoprint

RUN --mount=type=cache,target=/var/cache/apk \
  apk add \
    ffmpeg \
    gettext \
    libintl \
    jpeg-dev \
    zlib-dev

ARG CONFIG_BASE
COPY --link ${CONFIG_BASE} config-templates/config.yaml

ARG CONFIG_USERS
COPY --link ${CONFIG_USERS} config-templates/users.yaml

ARG CONFIG_PLUGINS
COPY --link ${CONFIG_PLUGINS} config-templates/plugins.yaml

ARG CONFIG_PRINTER
COPY --link ${CONFIG_PRINTER} printerProfiles/_default.profile

COPY --link --from=octoprint-builder /usr/local/bin/octoprint /usr/local/bin/
COPY --link --from=octoprint-builder /usr/local/lib /usr/local/lib
COPY --link --from=octoprint-builder /build /opt/octoprint

EXPOSE 80

ENTRYPOINT envsubst < config-templates/config.yaml > config.yaml \
    && envsubst < config-templates/plugins.yaml >> config.yaml \
	&& envsubst < config-templates/users.yaml > users.yaml \
	&& octoprint serve --iknowwhatimdoing --host 0.0.0.0 --port 80
