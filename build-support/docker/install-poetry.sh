#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${POETRY_VERSION}" ]
then
    error "Must set POETRY_VERSION environment variable"
    exit 1
fi

if [ -z "${USERNAME}" ]
then
    error "Must set USERNAME environment variable"
    exit 1
fi

info "Installing asdf Poetry plugin and specified Poetry version"
sudo -u $USERNAME bash -c ". \${HOME}/.bashrc && asdf plugin add poetry"
sudo -u $USERNAME bash -c ". \${HOME}/.bashrc && asdf install poetry ${POETRY_VERSION}" 2>/dev/null
sudo -u $USERNAME bash -c ". \${HOME}/.bashrc && asdf global poetry ${POETRY_VERSION}"
sudo -u $USERNAME bash -c ". \${HOME}/.bashrc && asdf reshim poetry ${POETRY_VERSION}"
