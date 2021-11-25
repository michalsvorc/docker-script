#!/usr/bin/env bash
#
# Author: Michal Svorc (https://michalsvorc.com)
# License: MIT license (https://opensource.org/licenses/MIT)
# Dependencies: docker, git

#===============================================================================
# Abort the script on errors and unbound variables
#===============================================================================

set -o errexit      # Abort on nonzero exit status.
set -o nounset      # Abort on unbound variable.
set -o pipefail     # Don't hide errors within pipes.
# set -o xtrace       # Set debugging.

#===============================================================================
# Variables
#===============================================================================

version='1.4.0'
argv0=${0##*/}

image_name='templates/docker'
image_tag_default='latest'

# Environments
environment_local='local'
environment_dev='dev'
environment_prod='prod'

environment_default="$environment_local"

# Registry
registry_host_default='example-registry.com'

# Network
network='bridge'

#===============================================================================
# Functions
#===============================================================================

usage() {
  cat <<EOF
Shell script to automate Docker tasks.

Usage:
  ${argv0} [options] build [arguments]
  ${argv0} [options] run [arguments]
  ${argv0} [options] push [registry_host]

Options:
  -h, --help            Show this screen.

  --version             Show version.

  -e, --environment <string>
                        Specify a value for target environment.
                        Affects Dockerfile filename and image tag postfix.
                        Available values: local | dev | prod
                        Default: ${environment_default}

  -t, --tag <string>    Specify an image tag. Environment value will be
                        appended to the tag as a postfix.
                        Default: ${image_tag_default}-${environment_default}

Commands:
  build                 Build an image.

  run                   Create a container and start interactive shell.

  push                  Tag an image and push it to the registry.
                        Default: ${registry_host_default}

Arguments:
  Docker command specific arguments.
EOF
  exit ${1:-0}
}

die() {
  local message="$1"

  printf 'Error: %s\n\n' "$message" >&2

  usage 1 1>&2
}

version() {
  printf '%s version: %s\n' "$argv0" "$version"
}

get_project_root_dir() {
  printf '%s' "$(git rev-parse --show-toplevel)"
}

create_image_handle() {
  local image_name="$1"
  local image_tag="$2"
  local environment="$3"

  printf '%s:%s-%s' "$image_name" "$image_tag" "$environment"
}

docker_build() {
  local image_tag="$1"
  local environment="$2"
  local dockerfile="${3:-Dockerfile}"
  local rest_args="$4"

  local project_root_dir="$(get_project_root_dir)"
  local image_handle="$(
    create_image_handle "$image_name" "$image_tag" "$environment"
  )"

  printf 'Building image "%s" from Dockerfile "%s".\n' \
    "$image_handle" \
    "$dockerfile"

  DOCKER_BUILDKIT=1 \
    docker build \
    --file "${project_root_dir}/${dockerfile}" \
    --tag "$image_handle" \
    ${rest_args} \
    "$project_root_dir"
}

docker_push() {
  local image_tag="$1"
  local environment="$2"
  local registry_host="$3"

  local image_handle="$(
    create_image_handle "$image_name" "$image_tag" "$environment"
  )"

  local registry_uri="${registry_host}/${image_handle}"

  printf 'Pushing "%s".\n' "$registry_uri"

  docker image tag \
    "$image_handle" "$registry_uri" \
    && docker push "$registry_uri"
}

docker_run() {
  local image_tag="$1"
  local environment="$2"
  local rest_args="$3"

  local image_handle="$(
    create_image_handle "$image_name" "$image_tag" "$environment"
  )"
  local container_name="$(printf '%s' "${image_handle//[\/:]/-}")"

  docker network inspect "$network" &> /dev/null \
    || die "$(
      printf 'Network "%s" not found.\n' "$network" \
      && printf 'Run "docker network create %s" command.' "$network"
    )"

  printf 'Creating container "%s" from image "%s".\n' \
    "$container_name" \
    "$image_handle"

  docker run \
    -it \
    --name "$container_name" \
    --network "$network" \
    ${rest_args} \
    "$image_handle"
}

#===============================================================================
# Execution
#===============================================================================

test $# -eq 0 && die 'No arguments provided.'

while test $# -gt 0 ; do
  case "${1:-}" in
    -h | --help )
      usage 0
      ;;
    --version )
      version
      exit 0
      ;;
    -e | --environment )
      shift
      test $# -eq 0 && die 'Missing argument for option "--environment".'

      environment="$1"

      case "${environment:-}" in
        local | dev | prod )
          ;;
        * )
          die "$(
            printf 'Unrecognized value "%s" for option "--environment".' \
            "${environment#-}"
          )"
          ;;
      esac

      shift
      test $# -eq 0 && die 'Missing "command" argument.'
      ;;
    -t | --tag )
      shift
      test $# -eq 0 && die 'Missing argument for option "--tag".'
      image_tag="${1:-}"

      shift
      test $# -eq 0 && die 'Missing "command" argument.'
      ;;
    build)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"
      dockerfile="Dockerfile.${environment}"
      rest_args="${@:2}"

      docker_build \
        "$image_tag" \
        "$environment" \
        "$dockerfile" \
        "$rest_args"
      break
      ;;
    push)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"
      registry_host="${2:-$registry_host_default}"

      docker_push \
        "$image_tag" \
        "$environment" \
        "$registry_host"
      break
      ;;
    run)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"
      rest_args="${@:2}"

      docker_run \
        "$image_tag" \
        "$environment" \
        "$rest_args"
      break
      ;;
    * )
      die "$(printf 'Unrecognized argument "%s".' "${1#-}")"
      ;;
  esac
done

