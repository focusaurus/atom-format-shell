#!/usr/bin/env bash

# Please Use Google Shell Style: https://google.github.io/styleguide/shell.xml

# ---- Start unofficial bash strict mode boilerplate
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -o errexit  # always exit on error
set -o errtrace # trap errors in functions as well
set -o pipefail # don't ignore exit codes when piping output
set -o posix    # more strict failures in subshells
# set -x          # enable debugging

IFS="$(printf "\n\t")"
# ---- End unofficial bash strict mode boilerplate

##### Usage #####
# First run:
#
# $ ./bin/docker-run.sh
#
# This will build the docker image then run a shell.
# Once the image is built, it will be run directly without a rebuild.
# If at any time you want to force a rebuild
#
# $ ./bin/docker-run.sh --build

##### How this script works #####
# This script can be dropped into a project and provide docker tooling
# to build a custom docker image for development on that project
# and get you a shell in there to do development tasks.
# It is all-in one for docker build and docker run.
#
# It is designed to have the project source code mounted into the docker image
# so that the host and the container always share the identical source code and
# project scripts. Only the development tools themselves live in the docker image.
# There is no ADD/COPY during the docker build and no docker-only volumes used.
#
# It is designed such that the user/group IDs match between the container and
# the host so there are no filesystem permission denied errors.
#
# The image it builds will by default match the name of this script's
# grandparent directory, meaning it's designed to live at
# myproject/bin/docker-run.sh
# and will tag the image as "myproject"
#
# It includes sections of Dockerfile syntax as shell variables which it will
# concatenate into a full Dockerfile sent to docker build over stdin.
# Snippets are provided for debian and alpine base images.
#
# It also mounts SSH_AUTH_SOCK so you can use git with ssh inside the
# container if you like.
#
# Bits you are intended to customize for each particular project are tagged with
# "CUSTOMIZE THIS" below.

docker_build() {
  ##### CUSTOMIZE THIS! #####
  dockerfile=$(
    cat <<'EOF'
FROM node:11.5.0-slim

EXPOSE 9999
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/host/bin:/host/node_modules/.bin
WORKDIR /host
SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-u", "-c"]
CMD ["bash"]

ARG USER
ARG USER_ID=1000
ARG GROUP_ID=1000

# debian: userid match
RUN addgroup --gid "${GROUP_ID}" "${USER}" || true
RUN adduser --disabled-password --gid "${GROUP_ID}" --uid "${USER_ID}" --gecos "${USER}" "${USER}" || true

# debian: packages
RUN apt-get -qq -y update >/dev/null; apt-get -qq -y install git less wget

USER ${USER}
EOF
  )
  echo "${dockerfile}" | docker build \
    --tag "$1" \
    --build-arg "USER=${USER}" \
    --build-arg "USER_ID=$(id -u)" \
    --build-arg "GROUP_ID=$(id -g)" \
    -
}

docker_run() {
  exec docker run --rm --interactive --tty \
    --attach stdin --attach stdout --attach stderr \
    --volume "${PWD}:/host" \
    --volume $SSH_AUTH_SOCK:/ssh-agent \
    --volume $HOME/.gitconfig:/home/node/.gitconfig \
    --env SSH_AUTH_SOCK=/ssh-agent \
    --user "$(id -u)" \
    --publish 9999:9999 \
    "$1" "${2-bash}"
}

main() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.."
  image=$(basename "${PWD}")
  case "$1" in
  --build)
    docker_build "${image}"
    ;;
  *)
    if ! docker inspect "${image}" &>/dev/null; then
      docker_build "${image}"
    fi
    docker_run "${image}"
    ;;
  esac
}

main "$@"
