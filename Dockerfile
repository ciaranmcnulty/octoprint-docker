FROM python:3.8-alpine3.10 as base

FROM base as octoprint-build

RUN apk --no-cache add build-base linux-headers
RUN wget -qO- https://github.com/OctoPrint/OctoPrint/archive/1.4.0.tar.gz | tar xz 
WORKDIR /OctoPrint-1.4.0
RUN pip install -r requirements.txt


FROM base as octoprint

RUN apk --no-cache add gettext libintl # for envsubst

COPY --from=octoprint-build /usr/local/bin /usr/local/bin
COPY --from=octoprint-build /usr/local/lib /usr/local/lib
COPY --from=octoprint-build /OctoPrint-* /opt/octoprint

RUN pip install "https://github.com/vookimedlo/OctoPrint-Prusa-Mini-ETA/archive/master.zip"
RUN pip install "https://github.com/jneilliii/OctoPrint-TPLinkSmartplug/archive/master.zip"

COPY octoprint-config.yaml /octoprint-config/config.yaml.template

ENTRYPOINT envsubst < /octoprint-config/config.yaml.template > /octoprint-config/config.yaml \
  && octoprint serve -c /octoprint-config/config.yaml --iknowwhatimdoing --host 0.0.0.0
