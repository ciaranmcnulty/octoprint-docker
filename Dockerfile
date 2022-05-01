# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS octoprint-builder

RUN --mount=type=cache,target=/var/cache/apk \
  apk add \
    build-base \
    linux-headers

WORKDIR /build

ARG OCTOPRINT_VERSION

RUN \
  wget -O - "https://github.com/OctoPrint/OctoPrint/archive/${OCTOPRINT_VERSION}.tar.gz" \
  | tar xz --strip-components=1

RUN --mount=type=cache,target=/root/.cache/pip \
  pip install -r requirements.txt


FROM ${BASE_IMAGE} AS octoprint

WORKDIR /root/.octoprint

RUN --mount=type=cache,target=/var/cache/apk \
  apk add \
    ffmpeg \
    gettext \
    libintl

ARG CONFIG_BASE
COPY --link ${CONFIG_BASE} config.yaml.template

ARG CONFIG_USERS
COPY --link ${CONFIG_USERS} users.yaml.template

ARG CONFIG_PRINTER
COPY --link ${CONFIG_PRINTER} printerProfiles/_default.profile

COPY --link --from=octoprint-builder /usr/local/bin/octoprint /usr/local/bin/
COPY --link --from=octoprint-builder /usr/local/lib /usr/local/lib
COPY --link --from=octoprint-builder /build /opt/octoprint

EXPOSE 80

ENTRYPOINT envsubst < config.yaml.template > config.yaml \
	&& envsubst < users.yaml.template > users.yaml \
	&& octoprint serve --iknowwhatimdoing --host 0.0.0.0 --port 80
