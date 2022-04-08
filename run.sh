#!/usr/bin/env bash

set -eu

###################
##### Imports #####
###################

# Check if running in build container or locally
# to import from correct path
if [ -d /build-support ]
then
    . ~/.bashrc
    BUILD_SUPPORT_ROOT="/build-support"
else
    BUILD_SUPPORT_ROOT="./build-support"
fi
. "${BUILD_SUPPORT_ROOT}/shell/run/config.sh"
. "${BUILD_SUPPORT_ROOT}/shell/common/log.sh"


###############################
##### Container Utilities #####
###############################

run-build-base() {
    ${CONTAINER_RUNTIME} build \
        --target "${BUILD_TARGET_STAGE}" \
        -t "${BUILD_IMAGE_URL}:${BUILD_IMAGE_TAG}" \
        -f build-support/docker/Dockerfile \
        --build-arg PYTHON_VERSION="${DEFAULT_PYTHON_VERSION}" \
        --build-arg UID="${USERID}" \
        --build-arg USERNAME="${USERNAME}" \
        "${@}" \
        .
}

run-push-base() {
    ${CONTAINER_RUNTIME} push \
        "${@}" \
        "${BUILD_IMAGE_URL}:${BUILD_IMAGE_TAG}"
}

run-in-container() {
    # If input device is not a TTY don't run with `-it` flags
    local INTERACTIVE_FLAGS="$(test -t 0 && echo '-it' || echo '')"
    ${CONTAINER_RUNTIME} run \
		--rm \
         ${INTERACTIVE_FLAGS} \
		-u ${USERNAME} \
        -v /var/run/docker.sock:/var/run/docker.sock \
		-v $(pwd):/project \
		-w /project \
		${BUILD_IMAGE_URL}:${BUILD_IMAGE_TAG} \
        --local "${@}"
}


#############################
##### Command Utilities #####
#############################

run-preamble() {
    if ! [ -d .venv/ ]
    then
        info "Installing project and dependencies"
        poetry install
    fi
    poetry run pip install -U pip wheel >/dev/null
}

run-command() {
    local COMMAND="${1}"
    shift

    if [ ${RUNTIME_CONTEXT} = "container" ]
    then
        run-in-container "${COMMAND}" "${@}"
    elif [ ${RUNTIME_CONTEXT} = "local" ]
    then
        run-${COMMAND} "${@}"
    else
        error "Invalid value for RUNTIME_CONTEXT: ${RUNTIME_CONTEXT}"
        exit 1
    fi
}


####################
##### Commands #####
####################

run-build() {
    run-preamble

    run-fmt-check

    run-check

    run-lint

    run-test

    info "Creating distribution packages"
    poetry build
}

run-check() {
    run-preamble

    info "Checking types with MyPy"
    poetry run mypy src tests
}

run-clean() {
    info "Removing virtual environment, build, and test files"
    rm -rf \
        .coverage \
        .mypy_cache/ \
        .pytest_cache/ \
        .venv/ \
        build-support/python/virtualenvs/* \
        dist/ \
        docs/{doctrees,html,source/api}/ \
        htmlcov/
}

run-editor-venv() {
    if ! [ -d "${EDITOR_VENV_PATH}"  ]
    then
        local PYTHON_BIN_PATH="${1:-$(which python3)}"

        info "Creating editor virtual environment using ${PYTHON_BIN_PATH}"
        ${PYTHON_BIN_PATH} -m venv "${EDITOR_VENV_PATH}"
        . "${EDITOR_VENV_PATH}/bin/activate"
        pip install -U pip wheel
        info "Installing project in editable (develop) mode"
        pip install -e .
        deactivate
    fi

    if [ -e "${EDITOR_VENV_PATH}/requirements.txt" ]
    then
        . "${EDITOR_VENV_PATH}/bin/activate"
        pip install -U pip wheel
        info "Installing project dependencies"
        pip install -r "${EDITOR_VENV_PATH}/requirements.txt"
        deactivate
    fi
}

run-exec() {
    run-preamble

    info "Running command in virtual environment: ${@}"
    poetry run "${@}"
}

run-fmt() {
    run-preamble

    info "Sorting imports with isort"
    poetry run isort src/ tests/

    info "Formatting code with Black"
    poetry run black src/ tests/
}

run-fmt-check() {
    run-preamble

    info "Checking imports with isort"
    poetry run isort --check src/ tests/

    info "Checking code format with Black"
    poetry run black --check src/ tests/
}

run-init() {
    if ( \
        ! [ -d src/template_repo_py ] \
        || ! [ -d tests/template_repo_py ] \
    )
    then
        error "Project already initialized, aborting"
        exit 1
    fi

    read -e -p "Do you want to include .gitconfig in this project's Git config [y/n]? " INCLUDE_GITCONFIG
    if [ "${INCLUDE_GITCONFIG,,}" = "y" ]
    then
        git config --local include.path ../.gitconfig
    fi

    local DEFAULT_PROJECT_NAME="$(basename $(pwd))"
    local DEFAULT_PROJECT_LICENSE="MIT"
    
    read -e -p "Project name [${DEFAULT_PROJECT_NAME}]: " PROJECT_NAME
    PROJECT_NAME="${PROJECT_NAME:-${DEFAULT_PROJECT_NAME}}"
    local DEFAULT_PROJECT_MODULE_NAME="${PROJECT_NAME//-/_}"
    read -e -p "Module name [${DEFAULT_PROJECT_MODULE_NAME}]: " PROJECT_MODULE_NAME
    PROJECT_MODULE_NAME="${PROJECT_MODULE_NAME:-${DEFAULT_PROJECT_MODULE_NAME}}"
    read -e -p "Description: " PROJECT_DESCRIPTION
    if [ -z "${PROJECT_DESCRIPTION}" ]
    then
        error "Must provide project description"
        exit 1
    fi
    read -e -p "Author Name: " PROJECT_AUTHOR_NAME
    if [ -z "${PROJECT_AUTHOR_NAME}" ]
    then
        error "Must provide author name"
        exit 1
    fi
    read -e -p "Author Email Address: " PROJECT_AUTHOR_EMAIL_ADDRESS
    if [ -z "${PROJECT_AUTHOR_EMAIL_ADDRESS}" ]
    then
        error "Must provide author (should be of the form 'username@domain.tld')"
        exit 1
    fi
    read -e -p "License [${DEFAULT_PROJECT_LICENSE}]: " PROJECT_LICENSE
    PROJECT_LICENSE="${PROJECT_LICENSE:-${DEFAULT_PROJECT_LICENSE}}"

    sed -i'' \
        -e "s/\(name = \)\"[^\"]\+\"/\1\"${PROJECT_NAME}\"/g" \
        -e "s/\(description = \)\"[^\"]\+\"/\1\"${PROJECT_DESCRIPTION}\"/g" \
        -e "s/\(authors = \)\[\"[^\"]\+\"\]/\1\[\"${PROJECT_AUTHOR_NAME} <${PROJECT_AUTHOR_EMAIL_ADDRESS}>\"\]/g" \
        -e "s/\(license = \)\"[^\"]\+\"/\1\"${PROJECT_LICENSE}\"/g" \
        -e "s/template_repo_py/${PROJECT_MODULE_NAME}/g" \
        pyproject.toml

    sed -i'' \
        -e "s/\(project = \)\"[^\"]\+\"/\1\"${PROJECT_NAME}\"/g" \
        -e "s/\(copyright = \"[0-9]\{4\}, \)[^\"]\+\"/\1${PROJECT_AUTHOR_NAME}\"/g" \
        -e "s/\(author = \)\"[^\"]\+\"/\1\"${PROJECT_AUTHOR_NAME}\"/g" \
        docs/_src/conf.py
    sed -i'' \
        -e "s/template-repo-py: [^\"]\+$/${PROJECT_NAME}: ${PROJECT_DESCRIPTION}/g" \
        README.md \
        docs/_src/index.md

    sed -i'' \
        -e "s/libcommon/${PROJECT_AUTHOR_NAME}/g" \
        -e "s/template-repo-py/${PROJECT_NAME}/g" \
        -e "s/template_repo_py/${PROJECT_MODULE_NAME}/g" \
        README.md \
        build-support/shell/run/config.sh \
        docs/_src/root.rst \
        pytest.ini \
        tests/template_repo_py/test_template_repo_py.py

    mv src/{template_repo_py,${PROJECT_MODULE_NAME}}
    mv tests/template_repo_py/{test_template_repo_py.py,test_${PROJECT_MODULE_NAME}.py}
    mv tests/{template_repo_py,${PROJECT_MODULE_NAME}}
}

run-lint() {
    run-preamble

    info "Linting code with Pylint"
    poetry run pylint src/ tests/
}

run-make-docs() {
    run-preamble

    ls src/ | head -n1 | tr -d '/' | while read MODULE_NAME
    do

        # -a: append module path to sys.path
        # -M: put module documentation before submodule documentation
        # -T: don't generate ToC for API, handled in main documentation
        # -e: generate separate pages for each module
        # -f: force overwrite of existing generated files
        # the final positional argument, EXCLUDE_PATTERN, ignores any scripts in bin directory
        # (self-documented with CLI parser)
        info "Generating API documentation with the Sphinx autodoc extension for module ${MODULE_NAME}"
        SPHINX_APIDOC_OPTIONS=members,show-inheritance poetry run sphinx-apidoc \
            -M \
            -T \
            -a \
            -e \
            -f \
            --implicit-namespaces \
            -o docs/_src/api \
            "src/${MODULE_NAME}" \
            "src/${MODULE_NAME}/bin/**"
    done

    info "Generating docs-compatible version of DEVELOPMENT.md"
    poetry run python build-support/python/run/gen_docs_development_md.py \
        "$(pwd)/DEVELOPMENT.md" "$(pwd)/docs/_src/DEVELOPMENT.md"

    info "Determining current version of package"
    CURRENT_VERSION=$(PYTHONPATH=docs/_src poetry run python -c "import conf; print(conf.release)")
    info "Current version is ${CURRENT_VERSION}, updating versions.json"
    poetry run python build-support/python/run/update_versions_file.py \
        docs/versions.json "v${CURRENT_VERSION}"

    info "Compiling documentation with Sphinx"
    poetry run sphinx-build \
        -M html \
        docs/_src/ \
        "docs/v${CURRENT_VERSION}/" \
        "${@}"
    mv docs/v${CURRENT_VERSION}/html/* "docs/v${CURRENT_VERSION}/"
}

run-publish() {
    run-build

    info "Creating and publishing distribution packages to PyPI"
    poetry publish
}

run-shell() {
    run-preamble

    info "Entering shell in virtual environment"
    poetry shell
}

run-test() {
    run-preamble

    info "Running tests with Pytest"
    poetry run pytest
}

run-update-deps() {
    run-preamble

    info "Updating dependencies with Poetry"
    poetry update

    if [ -d "${EDITOR_VENV_PATH}" ]
    then
        info "Updating editor virtual environment requirements"
        poetry export \
            --format requirements.txt \
            --output "${EDITOR_VENV_PATH}/requirements.txt" \
            --dev \
            --without-hashes
    fi
}

run-version() {
    local VERSION="${1:-}"

    run-preamble

    if [ -z "${VERSION}" ]
    then
        info "Checking package version"
        poetry version
    else
        info "Setting package version to ${VERSION}"
        poetry version ${VERSION}

        info "Updating version in Sphinx conf.py"
        sed -i'' \
            -e "s/\(version = \)\"[^\"]\+\"/\1\"${VERSION}\"/g" \
            docs/_src/conf.py
    fi
}


################
##### Main #####
################

print-usage() {
    echo "usage: $(basename ${0}) [-h] [SUBCOMMAND]"
    echo
    echo "subcommands:"
    echo "build             build distribution packages (default subcommand)"
    echo "build-base        build the build container image"
    echo "check             type check code with MyPy"
    echo "clean             remove virtual environment, build, and test files"
    echo "editor-venv       create or update local virtual environment for editor (i.e., Vim/Neovim)"
    echo "exec              execute arbitrary shell commands in virtual environment (using \`poetry run\`)"
    echo "fmt               format code with Black"
    echo "init              initialize repository (should only be run once)"
    echo "lint              lint code with Pylint"
    echo "make-docs         compile documentation with Sphinx"
    echo "publish           publish distribution packages to PyPI"
    echo "push-base         push build container image to registry"
    echo "shell             start Python shell in virtual environment"
    echo "test              run unit and documentation tests with Pytest"
    echo "update-deps       update dependencies with Poetry"
    echo "version           show or update package version"
    echo
    echo "optional arguments:"
    echo "-h, --help        show this help message and exit"
    echo "-l, --local       run command on host system instead of build container"
    echo "-c, --container   run command in build container"
    echo
}


while :
do
    case "${1:-}" in
        -c|--container)
            shift
            RUNTIME_CONTEXT="container"
        ;;
        -h|--help)
            print-usage
            exit 0
        ;;
        -l|--local)
            shift
            RUNTIME_CONTEXT="local"
        ;;
        *)
            break
        ;;
    esac
done

if [ -z "${1:-}" ]
then
    COMMAND="${DEFAULT_COMMAND}"
else
    COMMAND="${1}"
    shift
fi

# These commands should explicitly run locally
if ( \
    [ "${COMMAND}" = "build-base" ] \
    || [ "${COMMAND}" = "editor-venv" ] \
    || [ "${COMMAND}" = "push-base" ] \
)
then
    RUNTIME_CONTEXT="local"
fi

run-command "${COMMAND}" "${@}"
