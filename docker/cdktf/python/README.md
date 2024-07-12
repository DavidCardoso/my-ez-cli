# Cloud Development Kit for Terraform via Docker

The docker image is based on the `hashicorp/terraform` official image.

It contains Python, Pip, Pipenv, Pyenv, Node, NPM, and CDKTF CLI.

## Building the image

1. Change/pass the environment variables in the `./build` script if necessary.
   - Check the default values in the script.
2. Run `./build`

Example:
```shell
export IMAGE_TAG=latest
export TF_VERSION=1.9.1
export CDKTF_VERSION=latest
export NODE_VERSION=20.15.1-r0
export PYENV_VERSION=3.12.4

./build
```

> Alternatively, you can pass the env vars inline: `TF_VERSION=1.9.1 ./build`
