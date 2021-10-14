#!/usr/bin/env sh
#
# Author: Michal Svorc <dev@michalsvorc.com>
# License: MIT license (https://opensource.org/licenses/MIT)
# Dependencies: docker, git

#===============================================================================
# Abort the script on errors and undbound variables
#===============================================================================

set -o errexit      # Abort on nonzero exit status.
set -o nounset      # Abort on unbound variable.
set -o pipefail     # Don't hide errors within pipes.
# set -o xtrace       # Set debugging.

#===============================================================================
# Variables
#===============================================================================

version='1.3.0'
argv0=${0##*/}

image_name='templates/docker'
image_tag_default='latest'

user_name='user'
work_dir='work'

# Environments
environment_local='local'
environment_dev='dev'
environment_prod='prod'

environment_default="$environment_local"

# Network
network='bridge'

# Registries
registry_uri_default='example-registry.com'

#===============================================================================
# Usage
#===============================================================================

usage() {
  cat <<EOF
Usage: ${argv0} [options] command

Shell script to automate Docker tasks.

Options:
    -h, --help            Show help screen and exit.

    -v, --version         Show program version and exit.

    -e, --environment <string>
                          Specify a value for target environment. Affects
                          which Dockerfile will be used for the build process.
                          Available values: local | dev | prod
                          Defaults to "${environment_default}" when option is not set.

    -t, --tag <string>    Specify an image tag. Environment value will be
                          appended to the tag as a postfix.
                          Defaults to "${image_tag_default}-${environment_default}" when option is not set.

Commands:
    build                 Build an image.

    push [registry_uri]   Push an image to a registry.
                          Defaults to "${registry_uri_default}"
                          when no registry URI is provided.

    run                   Create a container and start interactive shell.
EOF
  exit ${1:-0}
}

#===============================================================================
# Functions
#===============================================================================

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

  local project_root_dir="$(get_project_root_dir)"
  local image_handle="$(
    create_image_handle "$image_name" "$image_tag" "$environment"
  )"

  printf 'Building image "%s" from Dockerfile "%s".\n' \
    "$image_handle" \
    "$dockerfile"

  docker build \
    --file "${project_root_dir}/${dockerfile}" \
    --build-arg user_name="$user_name" \
    --build-arg work_dir="$work_dir" \
    --tag "$image_handle" \
    "$project_root_dir"
}

docker_push() {
  local image_tag="$1"
  local environment="$2"
  local registry_uri="$3"

  local image_handle="$(
    create_image_handle "$image_name" "$image_tag" "$environment"
  )"

  printf 'Pushing image "%s" to registry "%s".\n' \
    "$image_handle" \
    "$registry_uri"

  docker image tag \
    "$image_handle" "${registry_uri}/${image_handle}" \
    && docker push $_
}

docker_run() {
  local image_tag="$1"
  local environment="$2"

  local volume_name="${image_name//[\/:]/-}"
  local volume_target="/home/${user_name}/${work_dir}"

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
    --mount "type=volume,source=${volume_name},destination=${volume_target}" \
    --name "$container_name" \
    --network "$network" \
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
    -v | --version )
      version
      exit 0
      ;;
    -e | --environment )
      shift
      test $# -eq 0 && die 'Missing argument for option "--environment".'

      case "${1:-}" in
        local | dev | prod )
          environment="$1"
          ;;
        * )
          die "$(
            printf 'Unrecognized value "%s" for option "--environment".' \
            "${1#-}"
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

      docker_build \
        "$image_tag" \
        "$environment" \
        "$dockerfile"
      break
      ;;
    push)
      shift
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"
      registry_uri="${1:-$registry_uri_default}"

      docker_push \
        "$image_tag" \
        "$environment" \
        "$registry_uri"
      break
      ;;
    run)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"

      docker_run \
        "$image_tag" \
        "$environment"
      break
      ;;
    * )
      die "$(printf 'Unrecognized argument "%s".' "${1#-}")"
      ;;
  esac
done

