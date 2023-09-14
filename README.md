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
      - [Node 14](#node-14)
    - [Yarn](#yarn)
      - [Yarn with Node 14](#yarn-with-node-14)
    - [Serverless Framework](#serverless-framework)
    - [Terraform](#terraform)
    - [Ookla Speedtest CLI](#ookla-speedtest-cli)
    - [Google Cloud CLI](#google-cloud-cli)
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

> It is using Node 16 (current LTS version).

```shell
# see node version
node -v

# run node interpreter
node

# run a node script
node somefile.js
```

#### Node 14

```shell
# see node version
node14 -v
```

### Yarn

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

#### Yarn with Node 14

> Some Node packages aren't compatible with Node 16 yet.

```shell
# see yarn version
yarn14 -v
```

### Serverless Framework

[Building the docker image](docker/serverless).

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

## Author

[David Cardoso](https://github.com/DavidCardoso)

## Contributors

Feel free to become a contributor! ;D
