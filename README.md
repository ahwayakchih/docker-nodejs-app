Node.js app runner
==================

## Why?

To learn some docker stuff while making it easier to run node.js modules and apps inside docker.

Also to stop inflating `yarn` downloads, since i don't use it at all. I don't know why it's injected into official node.js docker images while something that probably will be needed, e.g., python and g++ for building some of the binary modules, is not.

## Preparation

If you do not want to use pre-built images (for security reasons? just because?), you can build one from Dockerfile.
Go to `docker-nodejs-app` directory and run:

```sh
docker build -t ahwayakchih/nodeapp --build-arg NODE_UID=$(id -u) --build-arg NODE_GID=$(id -g) .
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

While developing, it probably more useful to keep `node_modules` cached so each test run after the first one is much faster.
To do that, either keep its container ("session" mentioned above) between runs, or use:

```sh
docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm test"
```

That will install modules into local `node_modules` directory. Each next run will simply check if modules are installed and continue.
After work is done, or just to "clear cached modules", simply remove local `node_modules` directory.

### App/module benchmarking

If application (or module) provides some kind of `benchmarks` script, it is easy to use it.
Same as with [Testing](#Testing), only instead of `npm test` use `npm run benchmarks`:

```sh
docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm run benchmarks"
```

## Simplify

To not have to remember long command lines and simplify everything, add following aliases to your `~/.profile` (or counterpart on your system of choice):

```sh
alias nodeapp-sh='mkdir -p ./node_modules && docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh'
alias nodeapp-run='mkdir -p ./node_modules && docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp npm run'
alias nodeapp-test='mkdir -p ./node_modules && docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm test"'
alias nodeapp-benchmark='mkdir -p ./node_modules && docker run --rm -v $(pwd):/app -v $(pwd)/node_modules:/app/node_modules -it ahwayakchih/nodeapp /bin/sh -c "npm install && npm run benchmarks"'
```