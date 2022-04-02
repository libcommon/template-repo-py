# template-repo-py: Template Repo for Python projects

## Overview

## Installation

### Install from Pypi (preferred method)

```bash
pip install template_repo_py
```

### Install Directly with Pip and Git

```bash
pip install git+ssh://git@github.com/libcommon/template-repo-py.git#egg=template-repo-py&subdirectory=src
```

### Install from Cloned Repo

```bash
git clone ssh://git@github.com/libcommon/template-repo-py.git && \
    cd template-repo-py && \
    pip install .
```

## Dependencies

The `tool.poetry.*dependencies` sections in [pyproject.toml](pyproject.toml) contain the app and dev dependencies.
See [DEVELOPMENT.md](DEVELOPMENT.md) for local development and build dependencies.

## Getting Started

TODO

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for development instructions.

## Contributing/Suggestions

Contributions and suggestions are welcome! To make a feature request, report a bug, or otherwise comment on existing
functionality, please file an issue. For contributions please submit a PR, but make sure to lint, type-check, and test
your code before doing so. Thanks in advance!
