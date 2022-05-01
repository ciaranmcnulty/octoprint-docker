# syntax=docker/dockerfile:1.4

ARG BASE_IMAGE

FROM ${BASE_IMAGE} AS base-builder

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked,id=apk \
  apk add --no-cache \
    build-base \
    linux-headers

FROM base-builder AS octoprint-builder

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked,id=apk \
 apk add --no-cache \
    yq \
    jpeg-dev \
    zlib-dev

WORKDIR /build

ARG OCTOPRINT_VERSION

RUN \
  wget -O - "https://github.com/OctoPrint/OctoPrint/archive/${OCTOPRINT_VERSION}.tar.gz" \
  | tar xz --strip-components=1

RUN --mount=type=cache,target=/root/.cache/pip,id=pip \
  pip install -r requirements.txt

ARG CONFIG_PLUGINS
RUN --mount=type=cache,target=/root/.cache/pip,id=pip \
    --mount=source=${CONFIG_PLUGINS},target=plugins.yaml \
  LIBRARY_PATH=/lib:/usr/lib yq e '.plugins[] | .["x-plugin-url"]' - < plugins.yaml | xargs -n1 pip install


FROM ${BASE_IMAGE} AS octoprint

WORKDIR /root/.octoprint

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked,id=apk \
  apk add --no-cache \
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


FROM base-builder as webcam-builder

ARG MJPEG_STREAMER_VERSION

RUN --mount=type=cache,target=/var/cache/apk,sharing=locked,id=apk \
 apk add --no-cache \
    cmake  \
    make  \
    libjpeg-turbo-dev

WORKDIR /build

RUN wget -O - https://github.com/jacksonliam/mjpg-streamer/archive/refs/tags/${MJPEG_STREAMER_VERSION}.tar.gz \
  | tar xz  --strip-components=2

RUN make
RUN make install


FROM ${BASE_IMAGE} as webcam

COPY --link --from=webcam-builder /usr/local/bin/mjpg_streamer /usr/local/bin/
COPY --link --from=webcam-builder /usr/local/lib/mjpg_streamer /usr/local/lib/
COPY --link --from=webcam-builder /usr/local/share/mjpg_streamer /usr/local/share/

ENV CAMERA_RESOLUTION=960x720
ENV CAMERA_H_FLIP=true
ENV CAMERA_V_FLIP=true

EXPOSE 80

ENTRYPOINT exec mjpg_streamer \
  -i "/usr/local/lib/mjpg-streamer/input_uvc.so -r $CAMERA_RESOLUTION -hf $CAMERA_H_FLIP -vf $CAMERA_V_FLIP -d /dev/video0" \
  -o "/usr/local/lib/mjpg-streamer/output_http.so -w /usr/local/share/mjpg-streamer/www -p 80"
