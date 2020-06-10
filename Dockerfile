FROM python:3.8-alpine3.10 as base


FROM base as build-base
RUN apk --no-cache add build-base linux-headers


FROM build-base as octoprint-build

RUN wget -qO- https://github.com/OctoPrint/OctoPrint/archive/1.4.0.tar.gz | tar xz 
WORKDIR /OctoPrint-1.4.0
RUN pip install -r requirements.txt


FROM base as octoprint

WORKDIR /root/.octoprint

RUN apk --no-cache add ffmpeg gettext libintl

COPY --from=octoprint-build /usr/local/bin /usr/local/bin
COPY --from=octoprint-build /usr/local/lib /usr/local/lib
COPY --from=octoprint-build /OctoPrint-* /opt/octoprint

RUN pip install "https://github.com/vookimedlo/OctoPrint-Prusa-Mini-ETA/archive/master.zip" 
RUN pip install "https://github.com/jneilliii/OctoPrint-TPLinkSmartplug/archive/master.zip"

VOLUME uploads timelapse

COPY octoprint-config.yaml config.yaml.template
COPY printer.profile printerProfiles/_default.profile

EXPOSE 80

ENTRYPOINT envsubst < config.yaml.template > config.yaml \
  && octoprint serve -c config.yaml --iknowwhatimdoing --host 0.0.0.0


FROM build-base as webcam

RUN apk --no-cache add cmake libjpeg-turbo-dev
RUN wget -qO- https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz | tar xz

WORKDIR /mjpg-streamer-master/mjpg-streamer-experimental
RUN make
RUN make install

ENV CAMERA_DEVICE=/dev/video0
ENV CAMERA_RESOLUTION=960x720
ENV CAMERA_H_FLIP=true
ENV CAMERA_V_FLIP=true

EXPOSE 80

ENTRYPOINT exec mjpg_streamer \
  -i "/usr/local/lib/mjpg-streamer/input_uvc.so -r $CAMERA_RESOLUTION -hf $CAMERA_H_FLIP -vf $CAMERA_V_FLIP -d $CAMERA_DEVICE" \
  -o "/usr/local/lib/mjpg-streamer/output_http.so -w /usr/local/share/mjpg-streamer/www -p 80"
