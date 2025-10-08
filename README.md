# My Ez CLI

Tools via **Unix Command Line Interface** with no installation and just using **Docker** + **Shell Script**.

- [My Ez CLI](#my-ez-cli)
  - [Prerequisites](#prerequisites)
  - [Setup](#setup)
  - [Usage examples](#usage-examples)
    - [AWS CLI](#aws-cli)
      - [AWS Get Session Token](#aws-get-session-token)
      - [AWS SSO](#aws-sso)
      - [AWS SSO Get Credentials](#aws-sso-get-credentials)
    - [Python](#python)
      - [Using other Python versions](#using-other-python-versions)
    - [NodeJS](#nodejs)
      - [Using other NodeJS versions](#using-other-nodejs-versions)
      - [Using NodeJS, NPM, and Yarn with custom ports](#using-nodejs-npm-and-yarn-with-custom-ports)
      - [Using NPM and Yarn with NPM token](#using-npm-and-yarn-with-npm-token)
    - [NPM](#npm)
      - [Using NPM with other NodeJS versions](#using-npm-with-other-nodejs-versions)
    - [Yarn](#yarn)
      - [Using Yarn with other NodeJS versions](#using-yarn-with-other-nodejs-versions)
      - [Yarn Berry (v2+)](#yarn-berry-v2)
    - [Serverless Framework](#serverless-framework)
    - [Terraform](#terraform)
      - [`CONTEXT` variable](#context-variable)
      - [`DOTENV_FILE` variable](#dotenv_file-variable)
      - [`TF_RC_FILE` variable](#tf_rc_file-variable)
      - [`AWS_CREDENTIALS_FOLDER` variable](#aws_credentials_folder-variable)
      - [`GCLOUD_CREDENTIALS_FOLDER` and `GOOGLE_APPLICATION_CREDENTIALS` variables](#gcloud_credentials_folder-and-google_application_credentials-variables)
    - [Cloud Development Kit for Terraform (CDKTF)](#cloud-development-kit-for-terraform-cdktf)
    - [Ookla Speedtest CLI](#ookla-speedtest-cli)
    - [Google Cloud CLI](#google-cloud-cli)
    - [Graph Viz for docker compose](#graph-viz-for-docker-compose)
    - [Playwright](#playwright)
  - [Author](#author)
  - [Contributors](#contributors)

## Prerequisites

- [Docker](https://www.docker.com/get-started).
- [Zshell + Oh My Zsh](https://ohmyz.sh/).

## Setup

It adds aliases to your `~/.zshrc` file and symbolic links to your `/usr/local/bin/` folder:

```shell
./setup.sh
# --------------------------------------------------------------------------------
#                   My Ez CLI • Setup
# --------------------------------------------------------------------------------
#   Hope you enjoy it! :D
# --------------------------------------------------------------------------------
#   Note: Aliases may be created in '~/.zshrc' file...
# --------------------------------------------------------------------------------
#   Note: Symbolic links may be created in '/usr/local/bin/' folder...
# --------------------------------------------------------------------------------
#   Warning: Root access may be needed.
# --------------------------------------------------------------------------------
#   GitHub: https://github.com/DavidCardoso/my-ez-cli
# --------------------------------------------------------------------------------

# 1) ALL                6) node             11) docker-compose-viz
# 2) aws                7) yarn             12) playwright
# 3) terraform          8) yarn-berry       13) python
# 4) cdktf              9) serverless       14) EXIT
# 5) gcloud             10) speedtest
# Choose an option:
```

## Usage examples

### AWS CLI

> See [more](config/aws).

```shell
# help
aws help

# list buckets
aws s3 ls --profile my-aws-profile

# download a file from a bucket
aws s3 cp s3://my-bucket/my-file /path/to/local/file --profile my-aws-profile
```

#### AWS Get Session Token

```shell
# authenticate using MFA
aws-get-session-token <MFA_DIGITS>
```

#### AWS SSO

```shell
# authenticate using SSO
aws-sso
#1) configure
#2) login
#3) logout
#Choose an option:
```

#### AWS SSO Get Credentials

> [Building the docker image](docker/aws-sso-cred/).

If you need to get/know the SSO credentials being used, run:

```shell
aws-sso-cred $AWS_PROFILE
# or specify a profile of your choice
aws-sso-cred my-working-profile
```

### Python

> It is using version `3.12.4` as default.

```shell
# see version
python --version

# run interpreter
python

# run a script
python main.py
```

#### Using other Python versions

This script is using the same env var used by [PyEnv](https://github.com/pyenv/pyenv?tab=readme-ov-file#understanding-python-version-selection).

So all you need to do is to declare the `PYENV_VERSION` before calling the `python` command.

```shell
# Export directly or add it to your profile configs (e.g.,`.zshrc`).
export PYENV_VERSION=3.9.19
python main.py

# or pass it inline
PYENV_VERSION=3.9.19 python main.py

# Note: the respective docker image will be downloaded if not found locally
# Unable to find image 'python:3.9.19' locally
# 3.9.19: Pulling from library/python
# 21988c13fd96: Download complete
# 42d758104bc9: Download complete
# 6d0099138f57: Download complete
# Digest: sha256:47d6f16aa0de11f2748c73e7af8d40eaf44146c6dc059b1d0aa1f917f8c5cc58
# Status: Downloaded newer image for python:3.9.19
```

### NodeJS

> It is using Node 22 (current LTS version) as default.

```shell
# see node version
node -v

# run node interpreter
node

# run a node script
node somefile.js
```

#### Using other NodeJS versions

```shell
# just add the node version as a suffix
node14 -v
node16 -v
node18 -v
node20 -v
node22 -v
node24 -v
```

#### Using NodeJS, NPM, and Yarn with custom ports

Use `MEC_BIND_PORTS` env var if you want to bind ports between the host and container:

```shell
MEC_BIND_PORTS="8080:80 9090:80" node
MEC_BIND_PORTS="8080:80 9090:80" npm
MEC_BIND_PORTS="8080:80 9090:80" yarn

# or
export MEC_BIND_PORTS="8080:80 9090:80"
node
npm
yarn
```

#### Using NPM and Yarn with NPM token

To be able to install NPM packages from a private repository,
you need to inform the respective `NPM_TOKEN`.

Method 1: Export the `NPM_TOKEN` on demand
```shell
NPM_TOKEN=your-token-here yarn
NPM_TOKEN=your-token-here npm

# or
export NPM_TOKEN=your-token-here
yarn
npm
```

Method 2: Setting it up in the `~/.npmrc` config file
```shell
# ~/.npmrc example

# Set the default registry
registry=https://private.npm.registry.com/

# Example for accessing private repos using NPM_TOKEN
//private.npm.registry.com/:_authToken=${NPM_TOKEN}
```

> **Hint**: you can set the token(s) on your default shell config file.\
> Example for zsh: `echo "export NPM_TOKEN=your-token-here" >> ~/.zshrc`

### NPM

> It is using NodeJS 22 as default.

```shell
# see npm version
npm -v

# start the package.json from a JS project
npm init

# install a package as dev dependency
npm install some-pkg --save-dev

# install a package globally
npm install -g another-pkg
```

#### Using NPM with other NodeJS versions

> Some NPM packages aren't compatible with older or newer NodeJS versions.

```shell
# just add the node version as a suffix
npm14 -v
npm16 -v
npm18 -v
npm20 -v
npm22 -v
```

### Yarn

> It is using Node 22.

```shell
# see yarn version
yarn -v

# start the package.json from a JS project
yarn init

# install a package as dev dependency
yarn add some-pkg --dev

# install a package globally
yarn global add another-pkg
```

#### Using Yarn with other NodeJS versions

> Some NPM packages aren't compatible with older or newer NodeJS versions.

```shell
# just add the node version as a suffix
yarn14 -v
yarn16 -v
yarn18 -v
yarn20 -v
yarn22 -v
```

#### Yarn Berry (v2+)

```shell
# if you have replaced yarn
yarn --version # it should show 3.6+

# otherwise
yarn-berry --version # it should show 3.6+
```

### Serverless Framework

It is ready to work with AWS.

> [See more about the docker image](docker/serverless).

```shell
# see versions
serverless -v

# help
serverless --help

# Starting from a template
# note: replace "template-name" below with the folder name of the example you want to use

# method 1
serverless create \
  -u https://github.com/serverless/examples/tree/master/template-name \
  -n my-project-folder

# method 2 [recommended]
serverless init \
  template-name \
  -n my-project-folder

# Hint: if you get build errors, try it
cd my-project-folder && yarn

# Serverless.com account login
# note: It is also possible to use an access key to authenticate via serverless CLI
serverless login

# Deploy your project
serverless deploy

# Invoke a Lambda Function
serverless invoke -f hello

# Invoke and display lambda logs
serverless invoke -f hello --log

# Fetch lambda logs
serverless logs -f hello
serverless logs -f hello --tail
```

> [Serverless Getting Started docs](https://www.serverless.com/framework/docs/getting-started).

> [Serverless templates](https://github.com/serverless/examples).

### Terraform

> **Important**: ensure you are using the right provider credentials/roles/permissions before executing any command.

> Take a look at Terraform AWS modules [public registry](https://registry.terraform.io/browse/modules?provider=aws) and [usage examples](https://github.com/terraform-aws-modules).

```shell
# help
terraform -help

# start the terraform in a project
mkdir my-terraform-project
cd my-terraform-project
terraform init

# set the right environment
# useful for multiple environments
# hint: avoid using default environment
terraform workspace list
terraform workspace new ${ENVIRONMENT}
terraform workspace select ${ENVIRONMENT}

# validate terraform files
terraform validate

# see  changes
terraform plan
# save changes to an output file (recommended)
terraform plan -out=tfplan

# apply changes to the providers (aws, gcp, azure, etc)
terraform apply
# apply changes using tfplan output file (recommended)
terraform apply tfplan

# destroy created resources on the providers
# warning: do not run it in production! ;D
terraform destroy
```

#### `CONTEXT` variable

By default, the parent directory is mounted on the container.
This allows files inside parent folder to be referenced in the Terraform files.

For instance, if you need to use a Terraform `module` that is located two levels up
in the filesystem, you can use `CONTEXT` variable before the `terraform` command
to define the absolute path to that module (or another folder).

```shell
# option 1
CONTEXT=$(cd "$PWD/../../" && pwd) terraform --version
CONTEXT=$(cd "$PWD/../../" && pwd) terraform init

# option 2
CONTEXT=$(cd "$PWD/../../" && pwd)
CONTEXT=$CONTEXT terraform --version
CONTEXT=$CONTEXT terraform init

# option 3
export CONTEXT=$(cd "$PWD/../../" && pwd)
terraform --version
terraform init
```

#### `DOTENV_FILE` variable

All variables in `DOTENV_FILE` file will be available inside the container.

By default, the terraform container will use `${PWD}/.env` file.

Inform a different value if you want to point to another one.

```shell
export DOTENV_FILE=local.env
terraform init
terraform plan

# or
DOTENV_FILE=local.env terraform init
DOTENV_FILE=local.env terraform plan
```

#### `TF_RC_FILE` variable

This is used for Terraform Cloud login.

By default, the terraform container will use `${HOME}/.terraformrc` file.

Inform a different value if you want to point to another one.

```shell
export TF_RC_FILE=/another/path/to/terraform-credentials/file
terraform init
# it should recognize the backend config pointing to your TF Cloud workspace(s)
```

#### `AWS_CREDENTIALS_FOLDER` variable

This is used for AWS CLI authentication.

By default, the terraform container will use `${HOME}/.aws` folder.

Inform a different value if you want to point to another one.

```shell
export AWS_PROFILE=your-aws-profile
export AWS_CREDENTIALS_FOLDER=/another/path/to/credentials/folder/
terraform init
terraform plan
terraform apply
# it should be able to deploy to your aws account based on the credentials used
```

> See [more about AWS auth configs](config/aws).

#### `GCLOUD_CREDENTIALS_FOLDER` and `GOOGLE_APPLICATION_CREDENTIALS` variables

This is used for GCP CLI authentication.

By default, the terraform container will use `${HOME}/.config/gcloud` folder,
and `/root/.config/gcloud/application_default_credentials.json` file, respectively.

> `GOOGLE_APPLICATION_CREDENTIALS` path starts with `/root/` because this is the default user inside the container. Therefore you should not change it to your local user.

Inform different values if you want to point to another one.

```shell
export GCLOUD_CREDENTIALS_FOLDER=/another/path/to/credentials/folder/
export GOOGLE_APPLICATION_CREDENTIALS=/root/another/path/to/credentials/file
terraform init
terraform plan
terraform apply
# it should be able to deploy to your cloud account based on the credentials used
```

### Cloud Development Kit for Terraform (CDKTF)

It is ready to work with Python.

> [Building the docker image for Python](docker/cdktf/python/).

```shell
mkdir /my/folder/learn-cdktf
cd /my/folder/learn-cdktf

cdktf --help

# starts a new project from a template
cdktf init --template="python" --providers="aws@~>4.0"
```

### Ookla Speedtest CLI

[Building the docker image](docker/speedtest/README.md).

```shell
# help
speedtest --help

# run a speed test
speedtest
```

### Google Cloud CLI

```shell
# If are not logged in, run the command below and follow the steps:
# 1. Copy/paste the provided URL in your browser
# 2. Authorize using your Google account
# 3. Copy/paste the generated auth code back in your terminal
gcloud-login

# If your current project is [None] or you wanna change it, set one.
gcloud config set project <PROJECT_ID>

# Test if it is working...
gcloud version
gcloud help
gcloud storage ls
```

> [gcloud CLI overview](https://cloud.google.com/sdk/gcloud).

> [gcloud auth login](https://cloud.google.com/sdk/gcloud/reference/auth/login).

### Graph Viz for docker compose

This will create a dependency graph in `display` only, `dot`, or `image` formats
based on a docker-compose YAML file (defaults to `./docker-compose.yml`).

> For more info, please check its [official documentation](https://github.com/pmsipilot/docker-compose-viz?tab=readme-ov-file#usage).

```shell
# navigate to the directory where the docker-compose YAML file is
cd /my/project/with/docker-compose-file/

# using just default options
docker-compose-viz render

# using a custom docker compose file
docker-compose-viz render ./my-custom-docker-compose.yml

# dot output format
docker-compose-viz render --output-format=dot

# image output format
docker-compose-viz render --output-format=image

# setting the path/name of the output file
docker-compose-viz render --output-format=image --output-file=graph.png
```

### Playwright

```shell
playwright # it will open the /bin/bash inside the container
# then you can run the other test related commands
npx playwright install chromium
npm run test
# etc...
```

> For more info, please check its [official documentation](https://playwright.dev/docs/docker).

## Author

[David Cardoso](https://github.com/DavidCardoso)

## Contributors

Feel free to become a contributor! ;D
