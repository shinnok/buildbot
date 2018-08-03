# buildbot/buildbot-worker

# please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

# Provides a base OpenSuSE image with latest buildbot worker installed

FROM        opensuse:leap
MAINTAINER  Buildbot maintainers


# Last build date - this can be updated whenever there are security updates so
# that everything is rebuilt
ENV         security_updates_as_of 2018-06-15

# Install security updates and required packages
RUN         zypper update -y && \
    zypper install -y -t pattern devel_basis && \
    zypper install -y \
    git \
    ccache \
    subversion \
    python-devel \
    libffi-devel \
    openssl-devel \
    python-pip \
    curl && \
    # install MariaDB dependencies
    #   zypper mr -er repo-source
    zypper -n si -d mariadb && \
    ## Test runs produce a great quantity of dead grandchild processes.  In a
    ## non-docker environment, these are automatically reaped by init (process 1),
    ## so we need to simulate that here.  See https://github.com/Yelp/dumb-init
    curl -Lo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64 && \
    chmod +x /usr/local/bin/dumb-init && \
    ## ubuntu pip version has issues so we should upgrade it: https://github.com/pypa/pip/pull/3287
    pip install -U pip virtualenv && \
    pip install --upgrade setuptools && \
    ## Install required python packages, and twisted
    pip --no-cache-dir install 'twisted[tls]' && \
    mkdir /buildbot &&\
    useradd -ms /bin/bash buildbot

COPY . /usr/src/buildbot-worker
COPY docker/buildbot.tac /buildbot/buildbot.tac

RUN pip install /usr/src/buildbot-worker && \
    chown -R buildbot /buildbot

USER buildbot
WORKDIR /buildbot

CMD ["/usr/local/bin/dumb-init", "twistd", "--pidfile=", "-ny", "buildbot.tac"]
