# Docker shell script

Docker shell script to automate common Docker tasks.

Features:

- Rootless containers.
- [BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/) builds.

## Requirements

Project root directory must contain `.git/` repository for Docker shell script to work correctly.

## Usage

```console
$ ./bin/docker.sh --help
```

Edit the `Variables` section in `./bin/docker.sh` to customize default values.

Dockerfile templates are located in the `./dockerfiles/` directory.

## Environments

You can create separate Dockerfiles for different runtime environments and select them with the `--environment` option.

Dockerfiles must be located in project root directory.

Examples: `Dockerfile.local`, `Dockerfile.dev`, `Dockerfile.prod`

## Start

1. Copy selected Dockerfile template from `./dockerfiles/` into the project root directory as `Dockerfile.local`.
2. Build Docker image with `./bin/docker.sh build`.
3. Run Docker container with `./bin/docker.sh run`.

