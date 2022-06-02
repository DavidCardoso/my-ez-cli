# AWS CLI

AWS Command Line Interface.

## Table of contents
- [AWS CLI](#aws-cli)
  - [Table of contents](#table-of-contents)
  - [Manual configuration](#manual-configuration)
    - [Scenario 1: AWS SSO profile (recommended)](#scenario-1-aws-sso-profile-recommended)
    - [Scenario 2: Source profile and MFA authentication](#scenario-2-source-profile-and-mfa-authentication)
    - [Scenario 3: IAM roles with a source profile and MFA authentication](#scenario-3-iam-roles-with-a-source-profile-and-mfa-authentication)
  - [Usage](#usage)
    - [Get Session Token](#get-session-token)
    - [SSO (Single Sign-On)](#sso-single-sign-on)
    - [AWS CLI](#aws-cli-1)
  - [Refs](#refs)

## Manual configuration

You can set the `~/.aws/config` and `~/.aws/credentials` files manually.

### Scenario 1: AWS SSO profile (recommended)

Configuration in `~/.aws/config`:

```
[profile my-sso-profile]
sso_start_url = https://yourcompany.awsapps.com/start
sso_region = us-east-1
sso_account_id = 1234567890
sso_role_name = RoleName
region = sa-east-1
output = json
```

> AWS SSO is a global service. So, use `sso_region = us-east-1` (N. Virginia).

> AWS SSO do not need `~/.aws/credentials` file.

### Scenario 2: Source profile and MFA authentication

Source profile credentials in `~/.aws/credentials`:

```
[my-profile-with-mfa]
aws_access_key_id = ...
aws_secret_access_key = ...

[my-working-profile]
aws_access_key_id =
aws_secret_access_key =
```

Configuration in `~/.aws/config`:

```
[profile my-profile-with-mfa]
mfa_serial = arn:aws:iam::111111111111:mfa/myuser
region = sa-east-1
output = json

[profile my-working-profile]
mfa_serial = arn:aws:iam::111111111111:mfa/myuser
source_profile = my-profile-with-mfa
region = sa-east-1
output = json
```

### Scenario 3: IAM roles with a source profile and MFA authentication

Source profile credentials in `~/.aws/credentials`:

```
[my-profile-with-mfa]
aws_access_key_id = ...
aws_secret_access_key = ...
```

Configuration in `~/.aws/config`:

```
[profile my-profile-with-mfa]
mfa_serial = arn:aws:iam::111111111111:mfa/myuser
region = sa-east-1
output = json

[profile my-working-profile]
mfa_serial = arn:aws:iam::111111111111:mfa/myuser
role_arn = arn:aws:iam::9999999999999:role/myrole
source_profile = my-profile-with-mfa
region = sa-east-1
output = json
```

## Usage

### Get Session Token

> Only when MFA is activated.

1. Create the dotenv file: `cp .env.example .env`
1. Update the `.env` file based on your `~/.aws/` files
2. Set AWS profile to your MFA profile: `export AWS_PROFILE=my-profile-with-mfa`
3. Get the session credentials: `aws-get-session-token <MFA_DIGITS>`
4. Update the credentials of your working profile based on the response
5. Set AWS profile to your working profile: `export AWS_PROFILE=my-working-profile`

### SSO (Single Sign-On)

1. Create the dotenv file: `cp .env.example .env`
2. Update `AWS_SSO_DEFAULT_PROFILE=your-default-sso-profile` env var in `.env` file
3. Run `aws-sso` and choose `1) configure` to setup a new AWS profile (account + role)
4. Run `aws_sso` and choose `2) login` to login into an existent profile

### AWS CLI

After the log in, just execute the AWS CLI commands normally.

Example:
```shell
aws help
aws s3 ls --profile my-profile
```

> Hint: set the env var `AWS_PROFILE` in your ZShell config file.
> ```
> echo "" >> ~/.zshrc
> echo "export AWS_PROFILE=my-working-profile" >> ~/.zshrc
> ```

## Refs

- [AWS CLI configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- [AWS CLI Config and credential file settings](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS CLI SSO configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
