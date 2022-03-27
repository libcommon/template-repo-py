#!/usr/bin/env bash

set -e

. /build-support/shell/common/log.sh


if [ -z "${USERNAME}" ]
then
    error "Must set USERNAME environment variable"
    exit 1
fi

info "Installing asdf dependencies"
apk add --no-cache curl git

info "Installing asdf"
sudo -u $USERNAME git clone https://github.com/asdf-vm/asdf.git /home/${USERNAME}/.asdf

info "Adding asdf to bash profile"
echo ". \$HOME/.asdf/asdf.sh" | sudo -u $USERNAME tee -a "/home/${USERNAME}/.bashrc" >/dev/null
echo ". \$HOME/.asdf/completions/asdf.bash" | sudo -u $USERNAME tee -a "/home/${USERNAME}/.bashrc" >/dev/null
