FROM scratch

ARG ALPINE

ARG NODE_UID
ARG NODE_GID
ARG NODE_VERSION

ENV NODE_UID ${NODE_UID:-1000}
ENV NODE_GID ${NODE_GID:-1000}
ENV NODE_VERSION ${NODE_VERSION:-12.7.0}

ADD ${ALPINE} /

RUN apk update \
	&& apk upgrade --available

COPY ./alpine-setup-node.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh \
	&& /tmp/setup.sh \
	&& rm /tmp/setup.sh

RUN mkdir -p /app/node_modules \
    && chmod -R 755 /app \
    && chown -R node:node /app

VOLUME /app/node_modules

WORKDIR /app
USER node:node
RUN npm config set package-lock false

CMD ["/bin/sh"]
