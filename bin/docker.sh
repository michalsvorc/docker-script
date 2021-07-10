#!/usr/bin/env sh
#
# Author: Michal Svorc <dev@michalsvorc.com>
# Dependencies: docker, git
# Refer to the usage() function below for usage.
# This program is under MIT license (https://opensource.org/licenses/MIT).

#===============================================================================
# Abort the script on errors and undbound variables
#===============================================================================

set -o errexit      # abort on nonzero exit status
set -o nounset      # abort on unbound variable
set -o pipefail     # don't hide errors within pipes
# set -o xtrace       # debugging

#===============================================================================
# Variables
#===============================================================================

version='1.1.0'
argv0=${0##*/}

image_name='templates/docker'
image_tag_default='latest'

arg_user_name='user'
arg_work_dir='work'

network='bridge'

# Environments
environment_local='local'
environment_dev='dev'
environment_prod='prod'

environment_default=$environment_local

# Registries
registry_uri='example-registry.com'

#===============================================================================
# Usage
#===============================================================================

usage() {
  cat <<EOF

  Usage:  ${argv0} [options] command

  Shell script to automate Docker tasks.

  Options:
    -h, --help                Show this screen and exit.
    -v, --version             Show program version and exit.
    -e, --environment string  Specify value for Docker image development environment.
                              Available values: local | dev | prod.
                              Defaults to 'local' when no value is provided.
                              Dockerfile.<environment> file is used for Docker builds.
    -t, --tag string          Specify image tag for Docker commands.
                              Defaults to 'latest' when value not provided.

  Commands:
    build   Build Docker image.
    push    Push Docker image to registry.
    run     Run Docker image.

EOF
exit ${1:-0}
}

#===============================================================================
# Functions
#===============================================================================

die() {
  local message="${1}"

  printf 'Error: %s\n' "${message}" >&2

  usage 1 1>&2
}

version() {
  printf '%s\n' "${version}"
}

get_project_root_dir() {
  printf '%s' $(git rev-parse --show-toplevel)
}

docker_build() {
  local image_tag="${1}"
  local environment="${2}"
  local dockerfile="${3:-'Dockerfile'}"

  local project_root_dir=$(get_project_root_dir)
  local image_handle="${image_name}:${image_tag}-${environment}"

  docker build \
    --file "${project_root_dir}/${dockerfile}" \
    --build-arg user_name=$arg_user_name \
    --build-arg work_dir=$arg_work_dir \
    --tag $image_handle \
    $project_root_dir
  }

docker_push() {
  local image_tag="${1}"
  local environment="${2}"

  local registry_uri=$registry_uri
  local image_handle="${image_name}:${image_tag}-${environment}"

  docker image tag \
    $image_handle "${registry_uri}/${image_handle}" \
    && docker push $_
  }

docker_run() {
  local image_tag="${1}"
  local environment="${2}"

  local volume_name="${image_name//[\/:]/-}"
  local volume_target="/home/${arg_user_name}"

  local image_handle="${image_name}:${image_tag}-${environment}"
  container_name=$(handle=${image_name}_${image_tag}-${environment} \
    && printf '%s' "${handle//[\/:]/-}")

  docker network inspect $network &> /dev/null \
    || die "Network \"$network\" not found. Run \"docker network create $network\""

  docker run \
    -it \
    --mount "type=volume,source=${volume_name},destination=${volume_target}" \
    --name $container_name \
    --network $network \
    $image_handle
  }

#===============================================================================
# Execution
#===============================================================================

if test $# -eq 0; then
  die 'No arguments provided.'
fi

while test $# -gt 0 ; do
  case "${1:-}" in
    -h | --help )
      usage 0
      ;;
    -v | --version )
      printf '%s version: %s\n' "${argv0}" $(version)
      exit 0
      ;;
    -e | --environment )
      shift
      test $# -eq 0 && die "Missing the environment option value."
      case "${1:-}" in
        local | dev | prod )
          environment="${1}"
          ;;
        * )
          die "Unrecognized environment option ${1#-}."
          ;;
      esac
      shift
      test $# -eq 0 && die "Missing the command argument."
      ;;
    -t | --tag )
      shift
      test $# -eq 0 && die "Missing the tag option value."
      image_tag="${1:-}"
      shift
      ;;

    build)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"
      dockerfile="Dockerfile.${environment}"

      docker_build \
        $image_tag \
        $environment \
        $dockerfile
      break
      ;;
    push)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"

      docker_push \
        $image_tag \
        $environment
      break
      ;;
    run)
      image_tag="${image_tag:-$image_tag_default}"
      environment="${environment:-$environment_default}"

      docker_run \
        $image_tag \
        $environment
      break
      ;;

    * )
      die "Unrecognized argument ${1#-}."
      ;;
  esac
done

