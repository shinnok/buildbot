# buildbot/buildbot-worker

# please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

# Provides a base Fedora image with latest buildbot worker installed

FROM        fedora:latest
MAINTAINER  Buildbot maintainers

COPY . /usr/src/buildbot-worker
COPY docker/buildbot.tac /buildbot/buildbot.tac

# Last build date - this can be updated whenever there are security updates so
# that everything is rebuilt
ENV         security_updates_as_of 2016-10-07

# Install security updates and required packages
RUN         dnf -y upgrade && \
            dnf -y install \
                @development-tools \
                git \
                ccahe \
                subversion \
                python-devel \
                libffi-devel \
                openssl-devel \
                python-pip \
                redhat-rpm-config \
                curl && \
## Test runs produce a great quantity of dead grandchild processes.  In a
## non-docker environment, these are automatically reaped by init (process 1),
## so we need to simulate that here.  See https://github.com/Yelp/dumb-init
            curl -Lo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.1.3/dumb-init_1.1.3_amd64 && \
            chmod +x /usr/local/bin/dumb-init && \
## ubuntu pip version has issues so we should upgrade it: https://github.com/pypa/pip/pull/3287
#            pip install -U pip virtualenv && \
## Install required python packages, and twisted
            pip --no-cache-dir install \
                'twisted[tls]' && \
            pip install /usr/src/buildbot-worker && \
            useradd -ms /bin/bash buildbot && chown -R buildbot /buildbot

RUN dnf -y upgrade
RUN dnf -y install dnf-plugins-core
RUN dnf -y builddep mariadb-server
# For RPM autobake
RUN dnf -y install rpm-build

USER buildbot
WORKDIR /buildbot
RUN ccache -M 10G
CMD ["/usr/local/bin/dumb-init", "twistd", "-ny", "buildbot.tac"]
