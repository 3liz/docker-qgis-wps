# Need docker above v17-05.0-ce
ARG REGISTRY_PREFIX=''

FROM  ${REGISTRY_PREFIX}qgis3-server:latest
MAINTAINER David Marteau <david.marteau@3liz.com>
LABEL Description="QGIS3 WPS service" Vendor="3liz.org" Version="1."

ARG wps_version=master
ARG wps_archive=https://github.com/3liz/py-qgis-wps/archive/${wps_version}.zip

ARG api_version=lizmap_api
ARG api_archive=https://github.com/dmarteau/lizmap-plugin/archive/${api_version}.zip

RUN apt update && apt install -y --no-install-recommends curl unzip gosu \
     python3-shapely  \
     && rm -rf /var/lib/apt/lists/*

# Install lizmap api
RUN echo $api_archive \
    && curl -Ls -X GET  $api_archive --output lizmap-api.zip \
    && unzip -q lizmap-api.zip \
    && cd lizmap-plugin-${api_version} && pip3 install . && cd .. \
    && rm -rf lizmap-plugin-${api_version} lizmap-api.zip

RUN pip3 install -U --no-cache-dir plotly \
    simplejson \
    geojson    \
    scipy \
    pandas \
    Jinja2 \
    && rm -rf /root/.cache /root/.ccache

# Install qywps
RUN echo $wps_archive \
    && curl -Ls -X GET  $wps_archive --output python-wps.zip \
    && unzip -q python-wps.zip \
    && rm python-wps.zip \
    && make -C py-qgis-wps-${wps_version} dist \
    && pip3 install --no-cache py-qgis-wps-${wps_version}/build/dist/*.tar.gz \
    && rm -rf py-qgis-wps-${wps_version} \
    && rm -rf /root/.cache /root/.ccache

COPY factory.manifest /build.manifest

COPY /docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]


