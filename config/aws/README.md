# AWS CLI

AWS Command Line Interface.

## Table of contents
- [AWS CLI](#aws-cli)
  - [Table of contents](#table-of-contents)
  - [Manual configuration](#manual-configuration)
    - [Scenario 1: AWS SSO profile (recommended)](#scenario-1-aws-sso-profile-recommended)
    - [Scenario 2: Source profile and MFA authentication](#scenario-2-source-profile-and-mfa-authentication)
    - [Scenario 3: IAM roles with a source profile and MFA authentication](#scenario-3-iam-roles-with-a-source-profile-and-mfa-authentication)
    - [Scenario 4: SAML authentication via Okta](#scenario-4-saml-authentication-via-okta)
  - [Usage](#usage)
    - [Get Session Token](#get-session-token)
    - [SSO (Single Sign-On)](#sso-single-sign-on)
    - [SAML (Okta)](#saml-okta)
    - [AWS CLI](#aws-cli-1)
  - [Refs](#refs)

## Manual configuration

You can set the `~/.aws/config` and `~/.aws/credentials` files manually.

### Scenario 1: AWS SSO profile (recommended)

Configuration in `~/.aws/config`:

<!-- TODO: update the example to match the current format -->
```
[profile my-sso-profile]
sso_start_url = https://yourcompany.awsapps.com/start
sso_region = sa-east-1
sso_account_id = 1234567890
sso_role_name = RoleName
region = sa-east-1
output = json
```

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

### Scenario 4: SAML authentication via Okta

AWS credentials obtained via SAML assertion from Okta. No manual `~/.aws/credentials` setup needed — `aws-saml-okta login` writes temporary credentials to a **base profile** (default `saml`). Other profiles in `~/.aws/config` that use `source_profile = saml` automatically resolve from it.

Prerequisites:
- An Okta AWS SAML app configured by your organization
- Your Okta username and MFA device (Okta Verify or TOTP authenticator)
- The SAML app URL (ask your admin — either full URL or short `home/amazon_aws/...` form)

Configuration in `config/aws/.env`:

```
AWS_SAML_IDP_URL=https://yourcompany.okta.com/app/amazon_aws/XXXXXXXXXX/sso/saml
AWS_SAML_OKTA_DOMAIN=yourcompany.okta.com
AWS_SAML_PROFILE=saml
AWS_SAML_DURATION=3600
AWS_SAML_REGION=eu-west-1
```

Optional: set MFA type in `~/.aws/config` to skip interactive selection:

```ini
[okta]
mfa_provider = OKTA
mfa_factor_type = push
aws_saml_url = home/amazon_aws/0oaXXXXXX/272
```

Example `~/.aws/config` using chained profiles (no re-auth needed for sub-accounts):

```ini
[default]
region = eu-west-1
output = json

[profile saml]
region = eu-west-1

[profile my-dev]
region = eu-west-1
role_arn = arn:aws:iam::111111111111:role/my-dev-role
source_profile = saml

[profile my-prd]
region = eu-west-1
role_arn = arn:aws:iam::222222222222:role/my-prd-role
source_profile = saml
```

> The AWS Role and IdP provider ARNs are automatically extracted from the SAML assertion. If multiple roles are available, you will be prompted to choose one.

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

### SAML (Okta)

1. Create the dotenv file: `cp .env.example .env`
2. Update the `AWS_SAML_*` env vars in `.env` (see Scenario 4 above)
3. Run `aws-saml-okta` and choose `1) configure` to set up interactively, or edit `.env` directly
4. Run `aws-saml-okta` and choose `2) login` to authenticate via Okta
5. Enter your Okta username, password, and MFA when prompted
6. Set AWS profile: `export AWS_PROFILE=saml` (or a chained profile like `my-dev`)

To log in and override the target profile without reconfiguring:
```bash
aws-saml-okta login --profile saml
```

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
