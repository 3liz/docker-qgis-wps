# Need docker above v17-05.0-ce
ARG REGISTRY_PREFIX=''

FROM  ${REGISTRY_PREFIX}qgis3-server:latest
MAINTAINER David Marteau <david.marteau@3liz.com>
LABEL Description="QGIS3 WPS service" Vendor="3liz.org" Version="1."

ARG wps_version=master
ARG wps_archive=https://github.com/3liz/py-qgis-wps/archive/${wps_version}.zip

RUN apt-get update && apt-get install -y --no-install-recommends curl unzip gosu && rm -rf /var/lib/apt/lists/*

# pip is broken on /ubuntu debian so that we using 
# a 'regular' version of pip installed from easy_install in base image
# using --no-cache-dir together with --extra-index-url does note work:
# see https://github.com/pypa/pip/issues/4580
RUN pip3 install --no-cache-dir sqlalchemy plotly \
    && rm -rf /root/.cache /root/.ccache

# Install qywps
RUN echo $wps_archive \
    && curl -Ls -X GET  $wps_archive --output python-wps.zip \
    && unzip -q python-wps.zip \
    && rm python-wps.zip \
    && make -C py-qgis-wps-${wps_version} dist \
    && pip3 install --no-cache py-qgis-wps-${wps_version}/build/dist/*.tar.gz \
    && rm -rf py-qgis-wps-${wps_version}

COPY factory.manifest /build.manifest

COPY /docker-entrypoint.sh /
RUN chmod 0755 /docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]


