# Base, language-agnostic image with Bash shell and new user
FROM alpine:latest AS base

ARG UID
ARG USERNAME

# Update base packages
RUN apk update && \
    apk upgrade

# Add Bash
# Used as shell for new user.
RUN apk add --no-cache bash

# Copy Docker build scripts
COPY build-support/ /build-support/

# Create new user
# This user is used to run all user-specified commands
# in the container, and the UID/USERNAME should match
# the local (host) user to ensure file permissions of generated
# or touched files are correct.
RUN UID=$UID \
    USERNAME=$USERNAME \
    build-support/docker/adduser.sh

# Base image for using Python and Poetry
# Uses the asdf-vm project to manage Python and Poetry installation
FROM base AS python_base

# Python version installed by asdf
ARG PYTHON_VERSION=3.10.3
# Poetry version installed by asdf
ARG POETRY_VERSION=1.1.13
# Must match USERNAME in base image
ARG USERNAME

# Inspired by https://bmaingret.github.io/blog/2021-11-15-Docker-and-Poetry
# POETRY_NO_INTERACTION: Disable Poetry prompts before taking an action
# POETRY_VIRTUALENVS_IN_PROJECT: Create Poetry virtual environments in the project (repo) root
# PYTHONFAULTHANDLER: Ensure Python dumps stacktraces
# PYTHONUNBUFFERED: Send Python output directly to stdout/stderr
ENV \
    POETRY_NO_INTERACTION=1 \
    POETRY_VERSION=$POETRY_VERSION \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

# Install asdf
RUN USERNAME=$USERNAME \
    build-support/docker/install-asdf.sh

# Install specified Python version with asdf
RUN USERNAME=$USERNAME \
    build-support/docker/install-python.sh

# Install specified Poetry version with asdf
RUN USERNAME=$USERNAME \
    build-support/docker/install-poetry.sh


FROM python_base as build

ENTRYPOINT ["./run.sh"]

CMD ["build"]
