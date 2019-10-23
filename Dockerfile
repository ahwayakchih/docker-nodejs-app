FROM scratch

ARG ALPINE

ARG NODE_UID
ARG NODE_GID
ARG NODE_VERSION

ENV NODE_UID ${NODE_UID:-1000}
ENV NODE_GID ${NODE_GID:-1000}
ENV NODE_VERSION ${NODE_VERSION:-13.0.1}

# Changed temporarily to workaround bug in podman:
# https://github.com/containers/buildah/issues/1938
# ADD ${ALPINE} /
ADD *.tar.gz /

RUN env \
	&& apk update \
	&& apk upgrade --available

COPY ./patches /tmp/patches
COPY ./alpine-setup-node.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh \
	&& /tmp/setup.sh \
	&& rm /tmp/setup.sh

RUN mkdir -p /app/node_modules \
    && chmod -R 755 /app \
    && chown -R node:node /app

WORKDIR /app
USER node:node

RUN npm config set package-lock false

RUN mkdir ~/.npm-global\
	&& npm config set prefix '~/.npm-global'\
	&& echo "export PATH=~/.npm-global/bin:\$PATH" > ~/.profile

CMD ["/bin/sh", "-l"]
