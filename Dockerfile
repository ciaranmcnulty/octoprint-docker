# syntax=docker/dockerfile:1.17

ARG PYTHON_VERSION=3.13

FROM python:${PYTHON_VERSION} AS octoprint-builder

WORKDIR /build

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt \
    apt update && apt install -y yq

ARG OCTOPRINT_VERSION=1.11.2
ADD --link "https://github.com/OctoPrint/OctoPrint/archive/${OCTOPRINT_VERSION}.tar.gz" Octoprint.tar.gz
RUN tar xz --strip-components=1 -f Octoprint.tar.gz
RUN --mount=type=cache,target=/root/.cache/pip,id=pip \
    pip install -r requirements.txt

ARG CONFIG_PLUGINS=config/plugins.yaml
COPY --link ${CONFIG_PLUGINS} plugins.yaml
RUN --mount=type=cache,target=/root/.cache/pip,id=pip \
  LIBRARY_PATH=/lib:/usr/lib yq '.plugins[] | .["x-plugin-url"]' plugins.yaml | xargs -n1 pip install


FROM python:${PYTHON_VERSION} AS octoprint

RUN --mount=type=cache,target=/var/lib/apt,sharing=locked,id=apt \
    apt update && apt install -y gettext

WORKDIR /root/.octoprint

ARG CONFIG_BASE=config/config.yaml
COPY --link ${CONFIG_BASE} config-templates/config.yaml

ARG CONFIG_USERS=config/users.yaml
COPY --link ${CONFIG_USERS} config-templates/users.yaml

ARG CONFIG_PLUGINS=config/plugins.yaml
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
