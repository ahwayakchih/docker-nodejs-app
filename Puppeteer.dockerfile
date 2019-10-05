FROM ahwayakchih/nodeapp:latest

USER root

RUN apk add udev xorg-server wait4ports ttf-freefont dbus dumb-init xvfb xvfb-run chromium\
	&& mkdir -p /etc/chromium/policies/managed\
	&& mkdir -p /etc/chromium/policies/recommended\
	&& chmod -R 777 /etc/chromium/policies

ENV CHROME_BIN /usr/bin/chromium-browser

USER node

ENTRYPOINT ["/usr/bin/dumb-init"]

CMD xvfb-run /bin/sh
