# Docker shell script

Docker shell script to automate common Docker tasks.

## Requirements

Project root directory must contain `.git/` repository for Docker shell script to work correctly.

## Usage

```console
$ ./bin/docker.sh --help
```

Edit the `Variables` section in `./bin/docker.sh` to customize default values.

Dockerfile templates are located in the `./dockerfiles/` directory.

## Start

1. Copy selected Dockerfile from `./dockerfiles/` into project root directory and rename it to `Dockerfile.local`.
2. Build Docker image with `./bin/docker.sh build`.
3. Run Docker container with `./bin/docker.sh run`.

## Environments

You can create separate Dockerfiles for different runtime environments.

Environments can be specified with the shell script `--environment` option.

Examples: `Dockerfile.local`, `Dockerfile.dev`, `Dockerfile.prod`
