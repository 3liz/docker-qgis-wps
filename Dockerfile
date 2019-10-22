# Need docker above v17-05.0-ce
ARG REGISTRY_PREFIX=''
ARG QGIS_VERSION=latest

FROM  ${REGISTRY_PREFIX}qgis-platform:${QGIS_VERSION}
MAINTAINER David Marteau <david.marteau@3liz.com>
LABEL Description="QGIS3 WPS service" Vendor="3liz.org" Version="1."

ARG wps_branch=master
ARG wps_repository=https://github.com/3liz/py-qgis-wps.git

ARG api_branch=master
ARG api_repository=https://github.com/dmarteau/lizmap-plugin.git

RUN apt-get update && apt-get install -y --no-install-recommends git make \
     && apt-get clean  && rm -rf /var/lib/apt/lists/* \
     && rm -rf /usr/share/man 

# Install lizmap api
RUN git clone --branch $api_branch --depth=1 $api_repository lizmap-plugin \
    && cd lizmap-plugin && pip3 install . && cd .. \
    && rm -rf lizmap-plugin \
    && rm -rf /root/.cache /root/.ccache

RUN pip3 install -U plotly \
    simplejson \
    geojson \
    scipy \
    pandas \
    Jinja2 \
    && rm -rf /root/.cache /root/.ccache

# Install pyqgiswps
RUN git clone --branch $wps_branch --depth=1 $wps_repository py-qgis-wps \
    && make -C py-qgis-wps dist \
    && pip3 install py-qgis-wps/build/dist/*.tar.gz \
    && cp py-qgis-wps/factory.manifest /build.manifest \
    && rm -rf py-qgis-wps \
    && rm -rf /root/.cache /root/.ccache

COPY /docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]


