# 
# Build docker image
#
#

NAME=qgis-wps

BUILDID=$(shell date +"%Y%m%d%H%M")
COMMITID=$(shell git rev-parse --short HEAD)

QYWPS_BRANCH=master

# keep that version number synchronized  with the qywps versions 
VERSION=1.0.4
VERSION_SHORT=1.0

VERSION_TAG=$(VERSION)

ifdef PYPISERVER
BUILD_ARGS=--build-arg pypi_server=$(PYPISERVER)
DOCKERFILE=-f Dockerfile.pypi
else
BUILD_ARGS=--build-arg wps_version=$(QYWPS_BRANCH)
endif

ifdef REGISTRY_URL
REGISTRY_PREFIX=$(REGISTRY_URL)/
BUILD_ARGS += --build-arg REGISTRY_PREFIX=$(REGISTRY_PREFIX)
endif

BUILDIMAGE=$(NAME):$(VERSION_TAG)-$(COMMITID)
ARCHIVENAME=$(shell echo $(NAME):$(VERSION_TAG)|tr '[:./]' '_')

MANIFEST=factory.manifest

all:
	@echo "Usage: make [build|archive|deliver|clean]"

manifest:
	echo name=$(NAME) > $(MANIFEST) && \
    echo version=$(VERSION)   >> $(MANIFEST) && \
    echo version_short=$(VERSION_SHORT) >> $(MANIFEST) && \
    echo buildid=$(BUILDID)   >> $(MANIFEST) && \
    echo commitid=$(COMMITID) >> $(MANIFEST) && \
    echo archive=$(ARCHIVENAME) >> $(MANIFEST)

build: manifest
	docker build --rm --force-rm --no-cache $(BUILD_ARGS) -t $(BUILDIMAGE) $(DOCKERFILE) .

archive:
	docker save $(BUILDIMAGE) | bzip2 > $(FACTORY_ARCHIVE_PATH)/$(ARCHIVENAME).bz2

tag:
	docker tag $(BUILDIMAGE) $(REGISTRY_PREFIX)$(NAME):latest
	docker tag $(BUILDIMAGE) $(REGISTRY_PREFIX)$(NAME):$(VERSION)
	docker tag $(BUILDIMAGE) $(REGISTRY_PREFIX)$(NAME):$(VERSION_SHORT)

deliver: tag
	docker push $(REGISTRY_URL)/$(NAME):latest
	docker push $(REGISTRY_URL)/$(NAME):$(VERSION)
	docker push $(REGISTRY_URL)/$(NAME):$(VERSION_SHORT)

clean:
	docker rmi -f $(shell docker images $(BUILDIMAGE) -q)


REDIS_HOST:=redis
DOCKER_OPTS:= --net mynet

run:
	docker run -it --rm -p 8080:8080 $(DOCKER_OPTS)   \
       -v $(shell pwd)/tests:/processing \
       -v $(shell pwd)/tests/data:/projects \
       -v $(shell pwd)/tests/__workdir__:/srv/data \
       -e QYWPS_SERVER_PARALLELPROCESSES=2 \
       -e QYWPS_SERVER_LOGSTORAGE=REDIS \
       -e QYWPS_REDIS_HOST=$(REDIS_HOST) \
       -e QYWPS_PROCESSSING_PROVIDERS=lzmtest \
       -e QYWPS_PROCESSSING_PROVIDERS_MODULE_PATH=/processing \
       -e QYWPS_CACHE_ROOTDIR=/projects \
       -e QYWPS_SERVER_WORKDIR=/srv/data \
       $(BUILDIMAGE)

# Client tests, run the service first
test:
	py.test -v tests/client/


