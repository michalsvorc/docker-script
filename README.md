# Dockerfile templates

Features:
- Rootless containers.
- Mount volume `$HOME` directory for non-root user.

## Requirements

Project root directory must contain `.git` repository for Docker shell script to work correctly.

## Dockerfiles

Dockerfile templates are located in `./dockerfiles` directory. Dockerfiles have their base image as filename postfix.

Copy selected Dockerfile into project root directory and rename it to `Dockerfile.local`.

You can create separate Dockerfiles for different environments, based on variables defined in Docker shell script.

Examples: `Dockerfile.dev`, `Dockerfile.prod`

## Docker shell script

Shell script to automate Docker tasks.

### Usage

```console
$ ./bin/docker.sh --help
```

### Variables

Edit "Variables" section to customize shell script defaults.

