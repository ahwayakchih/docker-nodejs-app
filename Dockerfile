FROM alpine:latest

ARG NODE_UID
ARG NODE_GID

ENV NODE_UID ${NODE_UID:-1000}
ENV NODE_GID ${NODE_GID:-1000}
ENV NODE_VERSION ${NODE_VERSION:-11.10.0}

COPY ./alpine-setup-node.sh /tmp/setup.sh
RUN chmod +x /tmp/setup.sh \
	&& /tmp/setup.sh \
	&& rm /tmp/setup.sh

RUN mkdir /app \
    && chmod 755 /app \
    && chown node:node /app

USER node:node

RUN mkdir /app/node_modules
VOLUME /app/node_modules

RUN npm config set package-lock false

WORKDIR /app
CMD ["/bin/sh"]
