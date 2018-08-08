# buildbot/buildbot-worker

# please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

# Provides a base Debian image with latest buildbot worker installed

FROM        debian:9
MAINTAINER  Buildbot maintainers

# Last build date - this can be updated whenever there are security updates so
# that everything is rebuilt
ENV         security_updates_as_of 2018-06-15

# This will make apt-get install without question
ARG         DEBIAN_FRONTEND=noninteractive

# enable apt sources
#RUN sed -i '/^#\sdeb-src /s/^#//' "/etc/apt/sources.list"
RUN cat /etc/apt/sources.list | sed 's/^deb /deb-src /g' >> /etc/apt/sources.list

# Install security updates and required packages
RUN         apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install -q \
    build-essential \
    git \
    subversion \
    python-dev \
    libffi-dev \
    libssl-dev \
    python-setuptools \
    python-pip \
    curl \
    ccache \
    # Install required MariaDB autobake packages
    apt-utils \
    libcurl4-openssl-dev \
    fakeroot \
    devscripts \
    iputils-ping \
    equivs \
    dpatch \
    libnuma-dev \
    libsnappy-dev \
    uuid-dev \
    sudo && \
    # install MariaDB dependencies
    apt-get build-dep mariadb-server -y && \
    # Test runs produce a great quantity of dead grandchild processes.  In a
    # non-docker environment, these are automatically reaped by init (process 1),
    # so we need to simulate that here.  See https://github.com/Yelp/dumb-init
    curl https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64.deb -Lo /tmp/init.deb && dpkg -i /tmp/init.deb &&\
    # ubuntu pip version has issues so we should use the official upstream version it: https://github.com/pypa/pip/pull/3287
    # however, all of these fail to update pip on Ubuntu 18.04
    #easy_install pip && \
    #pip install -U pip virtualenv && \
    #pip install --upgrade setuptools && \
    # Install required python packages, and twisted
    pip --no-cache-dir install 'twisted[tls]' && \
    mkdir /buildbot &&\
    useradd -ms /bin/bash buildbot && \
    # Allow sudo for autobake-deb script
    usermod -a -G sudo buildbot && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY . /usr/src/buildbot-worker
COPY docker/buildbot.tac /buildbot/buildbot.tac

RUN pip install /usr/src/buildbot-worker && \
    chown -R buildbot /buildbot

USER buildbot
WORKDIR /buildbot

CMD ["/usr/bin/dumb-init", "twistd", "--pidfile=", "-ny", "buildbot.tac"]
