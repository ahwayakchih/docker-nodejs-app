ALPINE_URL?=http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64
NODE_URL?=https://nodejs.org/dist/latest

ALPINE_VERSION?=$(shell curl -s ${ALPINE_URL}/ | grep 'alpine-minirootfs' | grep -Eiv '_rc[0-9]+' | tail -n 1 | sed -e 's/<[^>]*>//g' | cut -d " " -s -f 1 | cut -d "-" -f 3)
NODE_VERSION?=$(shell curl -s ${NODE_URL}/ | grep 'node-' | tail -n 1 | sed -e 's/<[^>]*>//g' | cut -d " " -s -f 1 | cut -d "-" -f 2 | cut -d "." -f 1,2,3 | cut -d "v" -f 2)

ALPINE_PKG=alpine-minirootfs-${ALPINE_VERSION}-x86_64.tar.gz
ALPINE_SUM=${ALPINE_PKG}.sha512

ALPINE_MAJOR=$(shell echo ${ALPINE_VERSION} | cut -d "." -s -f 1)
ALPINE_MINOR=$(shell echo ${ALPINE_VERSION} | cut -d "." -s -f 2)
NODE_MAJOR=$(shell echo ${NODE_VERSION} | cut -d "." -s -f 1)
NODE_MINOR=$(shell echo ${NODE_VERSION} | cut -d "." -s -f 2)
NODEAPP_VERSION?=${ALPINE_MAJOR}$(shell printf %02d ${ALPINE_MINOR}).${NODE_MAJOR}$(shell printf %02d ${NODE_MINOR})

NODE_UID?=$(shell id -u)
NODE_GID?=$(shell id -g)

HAS_PODMAN=$(shell podman --version >/dev/null 2>&1 && echo -n "podman" || false)
HAS_DOCKER=$(shell docker --version >/dev/null 2>&1 && docker ps >/dev/null 2>&1 && echo -n "docker" || false)
ifeq (${HAS_PODMAN}${HAS_DOCKER},podmandocker)
	# Since dockerd seems to be running, we can assume that's what user wants at the moment
	CONTAINER_ENGINE?=docker
else ifeq (${HAS_PODMAN},podman)
	CONTAINER_ENGINE?=podman
else
	CONTAINER_ENGINE?=docker
endif

EXISTS:=$(shell ${CONTAINER_ENGINE} inspect ahwayakchih/nodeapp:${NODEAPP_VERSION} 2>/dev/null | jq -e '.[0].Created | select(. == null | not)')

ifeq (${EXISTS},)
all: build
else
all: ignore
endif

info:
	@echo 'Using "'${CONTAINER_ENGINE}'" container engine, set CONTAINER_ENGINE=your_engine_of_choice to override that'

ignore: info
	@echo 'ahwayakchih/nodeapp:'${NODEAPP_VERSION}' was built on ${EXISTS}'
	@echo 'skipping build'
	@echo 'to force (re)build, run: "make build" instead'

build: info
	@echo 'Using Alpine Linux v'${ALPINE_VERSION}
	@if [ ! -f ${ALPINE_PKG} ]; then\
		echo 'Downloading '${ALPINE_PKG};\
		curl -s ${ALPINE_URL}/${ALPINE_PKG} -o ${ALPINE_PKG};\
	fi
	@echo 'Downloading '${ALPINE_SUM}
	@curl -s ${ALPINE_URL}/${ALPINE_SUM} -o ${ALPINE_SUM}
	@echo 'Validating '${ALPINE_PKG}
	@sha512sum -c ${ALPINE_SUM}

	@echo 'Using Node.js v'${NODE_VERSION}
	@echo 'Building ahwayakchih/nodeapp:'${NODEAPP_VERSION}'...'
	@${CONTAINER_ENGINE} build -t ahwayakchih/nodeapp:build --build-arg ALPINE=${ALPINE_PKG} --build-arg NODE_UID=${NODE_UID} --build-arg NODE_GID=${NODE_GID} --build-arg NODE_VERSION=${NODE_VERSION} .
	@echo  'Tagging ahwayakchih/nodeapp:build as '${NODEAPP_VERSION}'...'
	@${CONTAINER_ENGINE} tag ahwayakchih/nodeapp:build ahwayakchih/nodeapp:${NODEAPP_VERSION}
	@echo  'Tagging ahwayakchih/nodeapp:build as latest...'
	@${CONTAINER_ENGINE} tag ahwayakchih/nodeapp:build ahwayakchih/nodeapp:latest
	@echo  'Removing build tag...'
	@${CONTAINER_ENGINE} rmi ahwayakchih/nodeapp:build

	@if [ -f ${ALPINE_PKG} ]; then\
		echo 'Cleaning up';\
		rm ${ALPINE_PKG};\
		rm ${ALPINE_SUM};\
	fi

puppeteer: all
	@echo 'Building ahwayakchih/nodeapp:puppeteer'
	@${CONTAINER_ENGINE} build -t ahwayakchih/nodeapp:puppeteer -f Puppeteer.dockerfile .

phantomjs: all
	@echo 'Building ahwayakchih/nodeapp:phantomjs'
	@${CONTAINER_ENGINE} build -t ahwayakchih/nodeapp:phantomjs -f PhantomJS.dockerfile .

.PHONY: all
