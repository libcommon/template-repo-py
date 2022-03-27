#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${PYTHON_VERSION}" ]
then
    error "Must set PYTHON_VERSION environment variable"
    exit 1
fi

if [ -z "${USERNAME}" ]
then
    error "Must set USERNAME environment variable"
    exit 1
fi

# See: https://github.com/pyenv/pyenv/wiki#suggested-build-environment
info "Installing asdf Python plugin and specified Python version"
apk add --no-cache \
    build-base \
    bzip2-dev \
    libffi-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    openssl-dev \
    readline-dev \
    sqlite-dev \
    zlib-dev
sudo -u $USERNAME "/home/${USERNAME}/.asdf/bin/asdf" plugin add python
sudo -u $USERNAME "/home/${USERNAME}/.asdf/bin/asdf" install python $PYTHON_VERSION 2>/dev/null
sudo -u $USERNAME "/home/${USERNAME}/.asdf/bin/asdf" global python $PYTHON_VERSION
sudo -u $USERNAME "/home/${USERNAME}/.asdf/bin/asdf" reshim python $PYTHON_VERSION
