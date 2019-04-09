ALPINE_URL?=https://cz.alpinelinux.org/alpine/latest-stable/releases/x86_64
NODE_URL?=https://nodejs.org/dist/latest

ALPINE_VERSION?=$(shell curl -s ${ALPINE_URL}/ | grep 'alpine-minirootfs' | tail -n 1 | sed -e 's/<[^>]*>//g' | cut -d " " -s -f 1 | cut -d "-" -f 3)
NODE_VERSION?=$(shell curl -s ${NODE_URL}/ | grep 'node-' | tail -n 1 | sed -e 's/<[^>]*>//g' | cut -d " " -s -f 1 | cut -d "-" -f 2 | cut -d "." -f 1,2,3 | cut -d "v" -f 2)

ALPINE_PKG=alpine-minirootfs-${ALPINE_VERSION}-x86_64.tar.gz
ALPINE_SUM=${ALPINE_PKG}.sha512

all:
	@echo 'Using Alpine Linux v'${ALPINE_VERSION}
	@echo 'Downloading '${ALPINE_PKG}
	@curl -s ${ALPINE_URL}/${ALPINE_PKG} -o ${ALPINE_PKG}
	@echo 'Downloading '${ALPINE_SUM}
	@curl -s ${ALPINE_URL}/${ALPINE_SUM} -o ${ALPINE_SUM}
	@echo 'Validating '${ALPINE_PKG}
	@sha512sum -c ${ALPINE_SUM}

	@echo 'Using Node.js v'${NODE_VERSION}
	@echo 'Building ahwayakchih/nodeapp...'
	@docker build -t ahwayakchih/nodeapp --build-arg ALPINE=${ALPINE_PKG} --build-arg NODE_UID=$(id -u) --build-arg NODE_GID=$(id -g) --build-arg NODE_VERSION=11.13.0 .

	@echo 'Cleaning up'
	@rm ${ALPINE_PKG}
	@rm ${ALPINE_SUM}

.PHONY: all
