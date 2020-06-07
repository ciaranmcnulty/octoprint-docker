FROM python:3.8-alpine3.10 as base

FROM base as build

RUN apk --no-cache add build-base linux-headers
RUN wget -qO- https://github.com/OctoPrint/OctoPrint/archive/1.4.0.tar.gz | tar xz 
WORKDIR /OctoPrint-1.4.0
RUN pip install -r requirements.txt

FROM base as runtime

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /OctoPrint-* /opt/octoprint
COPY octoprint-config.yaml /octoprint-config/config.yaml

ENTRYPOINT octoprint serve -c /octoprint-config/config.yaml --iknowwhatimdoing --host 0.0.0.0
