FROM ahwayakchih/nodeapp:latest

USER root

# Thanks to https://gist.github.com/vovimayhem/6437c2f03b654e392ccf3e9903eba6af#gistcomment-2961930
WORKDIR /tmp
RUN cd /tmp && curl -Ls https://github.com/dustinblackman/phantomized/releases/download/2.1.1/dockerized-phantomjs.tar.gz | tar xz &&\
    cp -R lib lib64 / &&\
    cp -R usr/lib/x86_64-linux-gnu /usr/lib &&\
    cp -R usr/share /usr/share &&\
    cp -R etc/fonts /etc &&\
    curl -k -Ls https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 | tar -jxf - &&\
    cp phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs &&\
    rm -rf /tmp/*

USER node:node
WORKDIR /app

CMD /bin/sh -l
