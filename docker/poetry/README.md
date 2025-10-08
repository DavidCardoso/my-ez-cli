# Poetry via Docker

The docker image is based on Python official Docker image containing additional configs for Poetry.

## Building the image

1. Change the `PYENV_VERSION` and `POETRY_VERSION` environment variables in the `Dockerfile` file if necessary.
2. Run the `./build` script (defaults to `IMAGE_TAG=latest`).

> To build another image tag, try this: `IMAGE_TAG=1.2.3 ./build`
