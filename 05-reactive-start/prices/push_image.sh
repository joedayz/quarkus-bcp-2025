#!/usr/bin/env bash

REGISTRY="docker.io"
USER="joedayz"
# hub.docker.com/repositories/joedayz
IMAGE="${REGISTRY}/${USER}/do378-reactive-architecture-prices"

podman login ${REGISTRY} -u ${USER}

podman build -f Containerfile -t ${IMAGE} .
podman push ${IMAGE}
