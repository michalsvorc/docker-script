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

version='1.0.0'
argv0=${0##*/}

image_name='templates/docker'
image_tag='bullseye-slim'

base_image_handle="debian:${image_tag}"

arg_user_name='user'
arg_work_dir='work'

network='bridge'

# Environments
environment_local='local'
environment_dev='dev'
environment_prod='prod'

environment=$environment_local

# Registries
registry_uri='example-registry.com'

# Constructs
image_handle="${image_name}:${image_tag}"
container_name=$(handle=${image_name}_${image_tag} \
  && printf '%s' "${handle//[\/:]/-}")

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
                              Defaults to local when no value is provided.
                              Dockerfile.<environment> file is used for Docker builds.

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
  local environment="${1}"

  local project_root_dir=$(get_project_root_dir)
  local dockerfile="${project_root_dir}/Dockerfile.${environment}"
  local image_handle="${image_handle}-${environment}"

  docker build \
    --file $dockerfile \
    --build-arg base_image_handle=$base_image_handle \
    --build-arg user_name=$arg_user_name \
    --build-arg work_dir=$arg_work_dir \
    --tag $image_handle \
    $project_root_dir
  }

docker_push() {
  local environment="${1}"

  local registry_uri=$registry_uri
  local image_handle="${image_handle}-${environment}"

  docker image tag \
    $image_handle "${registry_uri}/${image_handle}" \
    && docker push $_
  }

docker_run() {
  local environment="${1}"

  local volume_name="${image_name//[\/:]/-}"
  local volume_target="/home/${arg_user_name}"

  local image_handle="${image_handle}-${environment}"
  local container_name="${container_name}-${environment}"

  docker network inspect $network &> /dev/null \
    || die "Network $network not found. Run '$ docker network create $network'."

  docker run \
    -it \
    --rm \
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

    build)
      docker_build ${environment}
      break
      ;;
    push)
      docker_push ${environment}
      break
      ;;
    run)
      docker_run ${environment}
      break
      ;;

    * )
      die "Unrecognized argument ${1#-}."
      ;;
  esac
done

