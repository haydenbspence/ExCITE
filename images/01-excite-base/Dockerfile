ARG BASE_IMAGE=exc/foundation:0.1
FROM --platform=$BUILDPLATFORM $BASE_IMAGE AS build

LABEL maintainer="NAME <EMAIL@EMAIL.com>"

USER root
COPY scripts/* "${HOME}/scripts/"

RUN user_permissions ${HOME} 

USER ${EXC_UID}
WORKDIR ${HOME}