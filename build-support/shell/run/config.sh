# Tool to use for building and running the build container
CONTAINER_RUNTIME="docker"

# Default command to run
DEFAULT_COMMAND="build"

# Default Python version to install in build container
DEFAULT_PYTHON_VERSION="3.8.13"

# Editor virtual environment path
# Useful for editors like Vim/Neovim with plugins that
# use the virtual environment for code completion, etc.
EDITOR_VENV_PATH="build-support/python/virtualenvs/editor-venv"

# Default runtime context for commands
# container: run commands in build container
# local: run commands on host system
# This option should not be changed from "container" without good reason
# Can be overriden at runtime with CLI parameter
RUNTIME_CONTEXT="container"

# Default container registry to push build container image to
BUILD_IMAGE_REGISTRY="ghcr.io"
# URL of the build container image, including the registry hostname and image path
BUILD_IMAGE_URL="${BUILD_IMAGE_REGISTRY}/libcommon/$(basename $(pwd))"
# Tag of the build container image
BUILD_IMAGE_TAG="build"
# Target stage of the build container image
BUILD_TARGET_STAGE="build"

# Username and UID of executing user
USERID="$(id -u)"
USERNAME="$(id -un)"
