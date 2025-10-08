# See ./build script
ARG TF_VERSION=1.13.0

FROM hashicorp/terraform:${TF_VERSION}

LABEL Author="David Cardoso <dev+github@davidcardoso.me>"

ARG CDKTF_VERSION=latest
ARG NODE_VERSION=22.16.0-r2
ARG PYENV_VERSION=3.12.4

# Environment variables
ENV PYENV_VERSION=${PYENV_VERSION}
ENV PYENV_ROOT=/root/.pyenv
ENV PIPENV_FOLDER=/root/.local/bin
ENV LANG=en_US.UTF-8

# Update the PATH env var
ENV PATH=${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PIPENV_FOLDER}:${PATH}

# Add Python
RUN apk add --update --no-cache bash curl &&\
    # Add pyenv and python compilation deps (temporarily)
    apk add --no-cache --virtual temp_dep \
    libffi-dev \
    openssl-dev \
    bzip2-dev \
    zlib-dev \
    readline-dev \
    sqlite-dev \
    build-base \
    xz-dev &&\
    # Install pyenv, and add python & pip (as venv)
    curl -sL https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash &&\
    pyenv install ${PYENV_VERSION} &&\
    pyenv global ${PYENV_VERSION} &&\
    pyenv rehash &&\
    # Clear virtual temporary deps
    apk del temp_dep

# Add pipenv (required by cdktf to initialize python templates)
ENV PIP_ROOT_USER_ACTION=ignore
RUN pip install --upgrade pip &&\
    pip install pipenv --user

# Add CDKTF
RUN apk add --no-cache npm nodejs=${NODE_VERSION} &&\
    npm --global install -y cdktf-cli@${CDKTF_VERSION}

ENTRYPOINT [ "cdktf" ]
