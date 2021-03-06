SHELL:=bash
# 
# Build docker image
#
#

NAME=qgis-wps

BUILDID=$(shell date +"%Y%m%d%H%M")
COMMITID=$(shell git rev-parse --short HEAD)

FLAVOR:=ltr

BUILD_VERSION:=1.2.x
BUILD_ARGS=--build-arg wps_branch=$(BUILD_VERSION)

BUILD_ARGS += --build-arg QGIS_VERSION=$(FLAVOR)

ifdef REGISTRY_URL
REGISTRY_PREFIX=$(REGISTRY_URL)/
BUILD_ARGS += --build-arg REGISTRY_PREFIX=$(REGISTRY_PREFIX)
endif

export BUILDIMAGE=$(NAME):$(FLAVOR)-$(COMMITID)

MANIFEST=factory.manifest

all:
	@echo "Usage: make [build|deliver|clean]"

build: _build manifest

_build:
	docker build --rm --force-rm --no-cache $(BUILD_ARGS) -t $(BUILDIMAGE) $(DOCKERFILE) .

manifest:
	{ \
	set -e; \
	version=`docker run --rm $(BUILDIMAGE) version`; \
	version_short=`echo $$version | cut -d. -f1-2`; \
	echo name=$(NAME) > $(MANIFEST) && \
    echo version=$$version >> $(MANIFEST) && \
    echo version_short=$$version_short >> $(MANIFEST) && \
    echo release_tag=$(FLAVOR) >> $(MANIFEST) && \
    echo buildid=$(BUILDID)   >> $(MANIFEST) && \
    echo commitid=$(COMMITID) >> $(MANIFEST); }

deliver: tag push

tag:
	{ set -e; source factory.manifest; \
	docker tag $(BUILDIMAGE) $(REGISTRY_PREFIX)$(NAME):$$version; \
	docker tag $(BUILDIMAGE) $(REGISTRY_PREFIX)$(NAME):$$version_short; \
	docker tag $(BUILDIMAGE) $(REGISTRY_PREFIX)$(NAME):$$release_tag; \
	}

push:
	{ set -e; source factory.manifest; \
	docker push $(REGISTRY_URL)/$(NAME):$$version; \
	docker push $(REGISTRY_URL)/$(NAME):$$version_short; \
	docker push $(REGISTRY_URL)/$(NAME):$$release_tag; \
	}


clean-all:
	docker rmi -f $(shell docker images $(BUILDIMAGE) -q)

clean:
	docker rmi $(BUILDIMAGE)

export BECOME_USER=$(shell id -u):$(shell id -g)

run: stop
	docker-compose up

stop:
	docker-compose stop  || true
	docker-compose rm -f || true

# Client tests, run the service first
test:
	py.test -v tests/


