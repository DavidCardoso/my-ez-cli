# Serverless Framework via Docker

The docker image is based on Amazon Linux Machine and contains AWS CLI, Python, Node, Yarn, Java, and Serverless Framework.

## Building the image

1. Change the `NODE_VERSION` and `SERVERLESS_VERSION` environment variables in the `Dockerfile` file if necessary.
2. Run the `./build` script (defaults to `IMAGE_TAG=latest`).

> To build another image tag, try this: `IMAGE_TAG=1.2.3 ./build`
