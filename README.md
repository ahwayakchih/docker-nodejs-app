Node.js app runner
==================

## Why?

To learn some docker stuff while making it easier to run node.js modules and apps inside docker.

Also to stop inflating `yarn` downloads, since i don't use it at all. I don't know why it's injected into official node.js docker images while something that probably will be needed, e.g., python and g++ for building some of the binary modules, is not.

## Preparation

If you do not want to use pre-built images (for security reasons? just because?), you can build one from Dockerfile.
Go to `docker-nodejs-app` directory and run:

```sh
make
```

It will download and use latest stable Alpine Linux and build latest "current" Node.js version.
You can use specific version of Node.js by passing it through environmental veriable. For example:

```sh
NODE_VERSION=12.0.0 make
```

To use different Alpine Linux version, you can specify two variables:

```sh
ALPINE_URL=http://dl-cdn.alpinelinux.org/alpine/v3.9/releases/x86_64 ALPINE_VERSION=3.9.3 make
```

It will take a while to finish, because it needs to build node.js from sources.
After that, all commands will reuse this pre-build image, and you can find it and remove it later with regular `docker` commands.

## Usage

Next try single-run "session". Go to your node.js application directory and run:

```sh
docker run --rm -v $(pwd):/app -it ahwayakchih/nodeapp
```

It will remove the container as soon as you finish (exit the shell).

To keep a "session" for multiple runs, use following command:

```sh
docker run --name my-node-app -v $(pwd):/app -it ahwayakchih/nodeapp
```

And then, to continue last "session" (and keep docker running):

```sh
docker start my-node-app && docker exec -it ahwayakchih/nodeapp /bin/sh
```

Or, to stop container after exiting:

```sh
docker start my-node-app && docker attach my-node-app
```

To remove session, run following command:

```sh
docker stop my-node-app && docker rm my-node-app --volumes
```

### App/module testing

Simple, one-time test run can be done with:

```sh
docker run --rm -v $(pwd):/app -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm test"
```

While developing, it probably is more useful to keep `node_modules` cached so each test run after the first one is much faster.
To do that, either keep its container ("session" mentioned above) between runs, or use:

```sh
docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm test"
```

That will install modules into local `node_modules` directory. Each next run will simply check if modules are installed and continue.
After work is done, or just to "clear cached modules", simply remove local `node_modules` directory.

### App/module running

If application (or module) provides additional "commands" in the form of `scripts` included in `package.json`, you can easly run them too.
It's similar to [Testing](#appmodule-testing), only instead of `npm test` use `npm run COMMAND`. For example, if there is a `benchmarks` command:

```sh
docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm run benchmarks"
```

## Simplify

Instead of having to remember long command lines, you can simplify everything by adding following aliases to your `~/.profile` (or counterpart on your system of choice):

```sh
alias _nodeapp='mkdir -p ./node_modules && docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp'
alias nodeapp-sh='_nodeapp /bin/sh'
alias nodeapp-run='_nodeapp npm run'
alias nodeapp-test='_nodeapp /bin/sh -c "npm install && npm test"'
alias nodeapp-benchmark='_nodeapp /bin/sh -c "npm install && npm run benchmarks"'
```