#!/usr/bin/env sh

# Based on Dockerfile from https://hub.docker.com/_/node/
# Ported to shell script by Marcin Konicki (https://ahwayakchih.neoni.net)
# to make it usable also inside custom VMs

NODE_VERSION=${NODE_VERSION:-"$1"}

if [ "$NODE_VERSION" = "" ] ; then
	NODE_VERSION="15.6.0"
fi

echo "Making sure node user and group exists ($NODE_UID:$NODE_GID)"

id -g node >/dev/null 2>&1 || addgroup -g ${NODE_GID:-1000} node
id -u node >/dev/null 2>&1 || adduser -u ${NODE_UID:-1000} -G node -s /bin/sh -D node

CURRENT_NODE_VERSION=$(node --version 2>/dev/null)
if [ "v$NODE_VERSION" = "$CURRENT_NODE_VERSION" ] && [ -z "$FORCE_BUILD" ] ; then
	echo "Node.js v$NODE_VERSION is already installed"
	exit
fi

echo "Building Node.js v$NODE_VERSION"

DEPS=".build-deps"

cleanexit() {
	apk del $DEPS
	rm -Rf "node-v$NODE_VERSION"
	rm SHASUMS256.txt.asc SHASUMS256.txt
	rm "node-v$NODE_VERSION.tar.xz"
	exit
}

apk add --no-cache \
    libstdc++ \
    curl \
    make \
    g++ \
    python2 \
    git

apk add --no-cache --virtual $DEPS \
    binutils-gold \
    gnupg \
    linux-headers

# Get signatures from https://github.com/nodejs/node#release-keys
for key in \
	4ED778F539E3634C779C87C6D7062848A1AB005C \
	94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
	74F12602B6F1C4E913FAA37AD3A89613643B6201 \
	71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
	8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
	C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
	C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
	DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
	A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
	108F52B48DB57BB0CC439B2997B01419BD92F80A \
	B9E2F5981AA6E0CD28160D9FF13993A75599653C \
; do
	gpg -k "$key" || \
		timeout 10 gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" || \
		timeout 10 gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
		timeout 10 gpg --keyserver pool.sks-keyservers.net --recv-keys "$key" || \
		timeout 10 gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key"
done

# Get sources if needed
if [ ! -f "node-v$NODE_VERSION.tar.xz" ] ; then
	curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz"
fi

# Always get hashes
curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc"

# Validate
gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc || cleanexit
grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - || cleanexit

# Unpack and prepare
tar -xf "node-v$NODE_VERSION.tar.xz"
cd "node-v$NODE_VERSION"
./configure

# Patch
echo "Checking for build patch at patches/v$NODE_VERSION.patch"
if [ -f "/tmp/patches/v$NODE_VERSION.patch" ] ; then
	echo "Applying build patch from patches/v$NODE_VERSION.patch"
	git apply "/tmp/patches/v$NODE_VERSION.patch" || cleanexit
else
	echo "No patches found"
fi

# Build!
make -j$(getconf _NPROCESSORS_ONLN)
make install
cd ..

cleanexit
