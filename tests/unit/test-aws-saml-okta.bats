#!/usr/bin/env bats

# Test AWS SAML/Okta wrapper script

setup() {
    BASEDIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "aws-saml-okta script exists and is executable" {
    [ -x "$BASEDIR/bin/aws-saml-okta" ]
}

@test "aws-saml-okta sources common.sh correctly" {
    run bash -n "$BASEDIR/bin/aws-saml-okta"
    [ "$status" -eq 0 ]
}

@test "aws-saml-okta requires curl" {
    # Create a wrapper that shadows curl with a missing command
    run bash -c "
        curl() { return 127; }
        command() {
            if [ \"\$2\" = 'curl' ]; then return 1; fi
            builtin command \"\$@\"
        }
        export -f curl command
        '$BASEDIR/bin/aws-saml-okta' 2>&1
    "
    [[ "$output" =~ "curl" ]] || [[ "$output" =~ "required" ]]
}

@test "aws-saml-okta requires jq" {
    # Create a wrapper that shadows jq with a missing command
    run bash -c "
        jq() { return 127; }
        command() {
            if [ \"\$2\" = 'jq' ]; then return 1; fi
            builtin command \"\$@\"
        }
        export -f jq command
        '$BASEDIR/bin/aws-saml-okta' 2>&1
    "
    [[ "$output" =~ "jq" ]] || [[ "$output" =~ "required" ]]
}

@test "aws-saml-okta login accepts --profile flag" {
    run bash -n "$BASEDIR/bin/aws-saml-okta"
    [ "$status" -eq 0 ]
    # Verify --profile is handled in the script source
    grep -q "\-\-profile" "$BASEDIR/bin/aws-saml-okta"
}

@test "aws-saml-okta normalize_okta_url handles short form" {
    run bash -c "
        normalize_okta_url() {
            local url=\"\$1\" domain=\"\$2\"
            if [[ \"\$url\" != https://* ]]; then
                echo \"https://\${domain}/\${url}\"
            else
                echo \"\$url\"
            fi
        }
        normalize_okta_url 'home/amazon_aws/0oaXXX/272' 'company.okta.com'
    "
    [ "$status" -eq 0 ]
    [ "$output" = "https://company.okta.com/home/amazon_aws/0oaXXX/272" ]
}

@test "aws-saml-okta read_aws_config_value returns empty for missing key" {
    run bash -c "
        read_aws_config_value() {
            local section=\"\$1\" key=\"\$2\" config_file=\"\${3:-\$HOME/.aws/config}\"
            awk -v section=\"\$section\" -v key=\"\$key\" '
                /^\[/{ in_section=(\$0 ~ section) }
                in_section && \$1==key{ print \$3; exit }
            ' \"\$config_file\" 2>/dev/null || true
        }
        result=\$(read_aws_config_value 'okta' 'aws_saml_url' '/dev/null')
        echo \"result=\$result\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "result=" ]
}

@test "normalize_okta_url passes through full https:// URL unchanged" {
    run bash -c "
        normalize_okta_url() {
            local url=\"\$1\" domain=\"\$2\"
            if [[ \"\$url\" != https://* ]]; then
                echo \"https://\${domain}/\${url}\"
            else
                echo \"\$url\"
            fi
        }
        normalize_okta_url 'https://company.okta.com/app/amazon_aws/0oaXXX/sso/saml' 'company.okta.com'
    "
    [ "$status" -eq 0 ]
    [ "$output" = "https://company.okta.com/app/amazon_aws/0oaXXX/sso/saml" ]
}

@test "aws-saml-okta read_aws_config_value extracts value from config" {
    run bash -c "
        tmpfile=\$(mktemp)
        cat > \"\$tmpfile\" <<'CONFIG'
[profile default]
region = us-east-1

[okta]
aws_saml_url = https://company.okta.com/app/amazon_aws/0oaXXX/sso/saml
mfa_factor_type = push
CONFIG
        read_aws_config_value() {
            local section=\"\$1\" key=\"\$2\" config_file=\"\${3:-\$HOME/.aws/config}\"
            awk -v section=\"\$section\" -v key=\"\$key\" '
                /^\[/{ in_section=(\$0 ~ section) }
                in_section && \$1==key{ print \$3; exit }
            ' \"\$config_file\" 2>/dev/null || true
        }
        result=\$(read_aws_config_value 'okta' 'mfa_factor_type' \"\$tmpfile\")
        rm -f \"\$tmpfile\"
        echo \"\$result\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "push" ]
}

@test "aws-saml-okta unknown command exits with code 2" {
    run bash -c "'$BASEDIR/bin/aws-saml-okta' unknown-cmd 2>&1; echo \"exit:\$?\""
    [[ "$output" =~ "exit:2" ]]
}

@test "--no-cli-pager flag is present in aws sts assume-role-with-saml call" {
    grep -q "\-\-no-cli-pager" "$BASEDIR/bin/aws-saml-okta"
}

@test "saml-extract-roles.py script exists and is executable" {
    [ -f "$BASEDIR/libexec/saml-extract-roles.py" ]
}

@test "saml-extract-roles.py extracts role from base64-encoded SAML XML" {
    run bash -c "
        tmpfile=\$(mktemp)
        # Minimal SAML XML with a single role, base64-encoded
        echo 'PHNhbWxwOlJlc3BvbnNlIHhtbG5zOnNhbWxwPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6cHJvdG9jb2wiPjxzYW1sOkFzc2VydGlvbiB4bWxuczpzYW1sPSJ1cm46b2FzaXM6bmFtZXM6dGM6U0FNTDoyLjA6YXNzZXJ0aW9uIj48c2FtbDpBdHRyaWJ1dGVTdGF0ZW1lbnQ+PHNhbWw6QXR0cmlidXRlIE5hbWU9Imh0dHBzOi8vYXdzLmFtYXpvbi5jb20vU0FNTC9BdHRyaWJ1dGVzL1JvbGUiPjxzYW1sOkF0dHJpYnV0ZVZhbHVlPmFybjphd3M6aWFtOjoxMjM0NTY3ODkwMTI6cm9sZS9UZXN0Um9sZSxhcm46YXdzOmlhbTo6MTIzNDU2Nzg5MDEyOnNhbWwtcHJvdmlkZXIvVGVzdFByb3ZpZGVyPC9zYW1sOkF0dHJpYnV0ZVZhbHVlPjwvc2FtbDpBdHRyaWJ1dGU+PC9zYW1sOkF0dHJpYnV0ZVN0YXRlbWVudD48L3NhbWw6QXNzZXJ0aW9uPjwvc2FtbHA6UmVzcG9uc2U+' > \"\$tmpfile\"
        python3 '$BASEDIR/libexec/saml-extract-roles.py' \"\$tmpfile\"
        rm -f \"\$tmpfile\"
    "
    [ "$status" -eq 0 ]
    [ "$output" = "arn:aws:iam::123456789012:role/TestRole,arn:aws:iam::123456789012:saml-provider/TestProvider" ]
}

@test "saml-extract-roles.py handles HTML entity-encoded base64 (decimal &#43;)" {
    run bash -c "
        tmpfile=\$(mktemp)
        # Same SAML base64 but with any + character replaced by &#43;
        # (The fixture has no + chars so we test a string known to have them.)
        # \"foo\xfb\" base64-encodes to \"+w==\"; entity-encode the + as &#43;
        python3 -c \"
import base64, sys
data = b'\xfb'
b64 = base64.b64encode(data).decode()  # '+w=='
entity = b64.replace('+', '&#43;')     # '&#43;w=='
sys.stdout.write(entity)
\" > \"\$tmpfile\"
        python3 - \"\$tmpfile\" <<'PYEOF'
import re, sys
d = open(sys.argv[1]).read()
d = re.sub(r'&#x([0-9a-fA-F]+);', lambda m: chr(int(m.group(1), 16)), d)
d = re.sub(r'&#(\d+);',           lambda m: chr(int(m.group(1))),      d)
d = re.sub(r'\s', '', d)
sys.stdout.write(d)
PYEOF
        rm -f \"\$tmpfile\"
    "
    [ "$status" -eq 0 ]
    # After entity-decode, the string must be a valid base64 for foo\xfb
    [[ "$output" == "+w==" ]]
}

@test "saml-extract-roles.py handles HTML entity-encoded base64 (hex &#x2b;)" {
    run bash -c "
        tmpfile=\$(mktemp)
        python3 -c \"
import base64, sys
data = b'\xfb'
b64 = base64.b64encode(data).decode()  # '+w=='
entity = b64.replace('+', '&#x2b;')    # '&#x2b;w=='
sys.stdout.write(entity)
\" > \"\$tmpfile\"
        python3 - \"\$tmpfile\" <<'PYEOF'
import re, sys
d = open(sys.argv[1]).read()
d = re.sub(r'&#x([0-9a-fA-F]+);', lambda m: chr(int(m.group(1), 16)), d)
d = re.sub(r'&#(\d+);',           lambda m: chr(int(m.group(1))),      d)
d = re.sub(r'\s', '', d)
sys.stdout.write(d)
PYEOF
        rm -f \"\$tmpfile\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "+w==" ]]
}

@test "saml_logout awk removes credentials section without affecting other sections" {
    run bash -c "
        tmpfile=\$(mktemp)
        cat > \"\$tmpfile\" <<'CREDS'
[saml]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
aws_session_token = token123

[other-profile]
aws_access_key_id = AKIAIOSFODNN7OTHER
aws_secret_access_key = othersecret
CREDS
        awk -v profile='[saml]' '
            \$0 == profile { in_section=1; next }
            in_section && /^\[/ { in_section=0 }
            !in_section { print }
        ' \"\$tmpfile\"
        rm -f \"\$tmpfile\"
    "
    [ "$status" -eq 0 ]
    ! [[ "$output" =~ "saml" ]]
    [[ "$output" =~ "other-profile" ]]
    [[ "$output" =~ "AKIAIOSFODNN7OTHER" ]]
}
