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
    - [Node](#node)
      - [Using other Node versions](#using-other-node-versions)
    - [Yarn](#yarn)
      - [Using Yarn with NPM token and custom ports](#using-yarn-with-npm-token-and-custom-ports)
      - [Using Yarn with other Node versions](#using-yarn-with-other-node-versions)
      - [Yarn Berry (v2+)](#yarn-berry-v2)
    - [Serverless Framework](#serverless-framework)
    - [Terraform](#terraform)
      - [`CONTEXT` variable](#context-variable)
      - [`DOTENV_FILE` variable](#dotenv_file-variable)
      - [`TF_RC_FILE` variable](#tf_rc_file-variable)
      - [`AWS_CREDENTIALS_FOLDER` variable](#aws_credentials_folder-variable)
      - [`GCLOUD_CREDENTIALS_FOLDER` and `GOOGLE_APPLICATION_CREDENTIALS` variables](#gcloud_credentials_folder-and-google_application_credentials-variables)
    - [Ookla Speedtest CLI](#ookla-speedtest-cli)
    - [Google Cloud CLI](#google-cloud-cli)
    - [Graph Viz for docker compose](#graph-viz-for-docker-compose)
  - [Author](#author)
  - [Contributors](#contributors)

## Prerequisites

- [Docker](https://www.docker.com/get-started).
- [Zshell + Oh My Zsh](https://ohmyz.sh/).

## Setup

It adds aliases to your `~/.zshrc` file and symbolic links to your `/usr/local/bin/` folder:

```shell
# Run this script and choose an option
./setup.sh
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

### Node

> It is using Node 20 (current LTS version).

```shell
# see node version
node -v

# run node interpreter
node

# run a node script
node somefile.js
```

#### Using other Node versions

```shell
# just add the node version as a suffix
node14 -v
node16 -v
node18 -v
```

### Yarn

> It is using Node 20 (current LTS version).

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

#### Using Yarn with NPM token and custom ports

Use `MEC_BIND_PORTS` env var if you want to bind ports between the host and container:

```shell
MEC_BIND_PORTS="8080:80 9090:80" yarn

# or
export MEC_BIND_PORTS="8080:80 9090:80"
yarn
```

In order to be able to install NPM packages from a private repository,
you might need to inform `NPM_TOKEN` env var.

```shell
NPM_TOKEN=your-token-here yarn

# or
export NPM_TOKEN=your-token-here
yarn
```

> **Hint**: you can put this on your default shell config file.\
> Example for zsh: `echo "export NPM_TOKEN=your-token-here" >> ~/.zshrc`

#### Using Yarn with other Node versions

> Some NPM packages aren't compatible with newer Node versions yet.

```shell
# just add the node version as a suffix
yarn14 -v
yarn16 -v
yarn18 -v
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

> [gcloud CLI overview](https://cloud.google.com/sdk/gcloud).

> [gcloud auth login](https://cloud.google.com/sdk/gcloud/reference/auth/login).

## Author

[David Cardoso](https://github.com/DavidCardoso)

## Contributors

Feel free to become a contributor! ;D
