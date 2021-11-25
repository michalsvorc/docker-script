# Docker shell script

Docker shell script to automate common Docker tasks.

## Usage

```console
$ ./bin/docker.sh --help
```

Edit the `Variables` section to customize default values.

## Requirements

Project root directory must contain `.git` repository for Docker shell script to work correctly.

## Dockerfiles

Features:

- rootless containers
- passing additional command arguments allowed

Dockerfile templates are located in the `./dockerfiles` directory.

Copy selected Dockerfile into project root directory under the name `Dockerfile.local`.

## Environments

You can create separate Dockerfiles for different runtime environments.

Examples: `Dockerfile.local`, `Dockerfile.dev`, `Dockerfile.prod`

Environments can be specified by the shell script.

