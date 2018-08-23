#
# Builbot worker for building MariaDB
#
FROM ubuntu:14.04
MAINTAINER MariaDB Buildbot maintainers

USER root

# COPY docker/buildbot.tac /buildbot/buildbot.tac

# This will make apt-get install without question
ARG DEBIAN_FRONTEND=noninteractive	

# Enable apt sources
RUN sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list

# Install updates and required packages
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y build-dep -q mariadb-server && \
    apt-get -y install -q \
        apt-utils build-essential python-dev sudo git \
        devscripts equivs libcurl4-openssl-dev hardening-wrapper \
        ccache curl \
        libevent-dev dpatch gawk gdb libboost-dev libcrack2-dev \
        libjudy-dev libnuma-dev libsnappy-dev libxml2-dev \
        unixodbc-dev uuid-dev fakeroot iputils-ping \
        python-pip libffi-dev

# Create buildbot user
RUN useradd -ms /bin/bash buildbot && mkdir /buildbot && chown -R buildbot /buildbot

# autobake-deb will need sudo rights
RUN usermod -a -G sudo buildbot
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# give rights to put temp files in /run/shm
RUN chgrp buildbot /run/shm && chmod g+w /run/shm

RUN apt-get -y install libffi-dev
# Upgrade pip and install packages
RUN pip install setuptools --upgrade
RUN pip install 'twisted[tls]'
RUN pip install buildbot-worker

# Test runs produce a great quantity of dead grandchild processes.  In a
# non-docker environment, these are automatically reaped by init (process 1),
# so we need to simulate that here.  See https://github.com/Yelp/dumb-init
RUN curl https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb -Lo /tmp/init.deb && dpkg -i /tmp/init.deb

USER buildbot
COPY docker/buildbot.tac /buildbot/buildbot.tac
WORKDIR /buildbot
CMD ["/usr/bin/dumb-init", "twistd", "--pidfile=", "-ny", "buildbot.tac"]
