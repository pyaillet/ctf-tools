# Using debian 10 as base image.
FROM debian:10

# Label base
LABEL r2docker latest

# Radare version
ARG R2_VERSION=master
# R2pipe python version
ARG R2_PIPE_PY_VERSION=0.8.9
# R2pipe node version
ARG R2_PIPE_NPM_VERSION=2.3.2

ENV R2_VERSION ${R2_VERSION}
ENV R2_PIPE_PY_VERSION ${R2_PIPE_PY_VERSION}
ENV R2_PIPE_NPM_VERSION ${R2_PIPE_NPM_VERSION}

RUN echo "Building versions:" && \
  echo "R2_VERSION=$R2_VERSION" && \
  echo "R2_PIPE_PY_VERSION=${R2_PIPE_PY_VERSION}" && \
  echo "R2_PIPE_NPM_VERSION=${R2_PIPE_NPM_VERSION}"

# Build radare2 in a volume to minimize space used by build
VOLUME ["/mnt"]

# Install all build dependencies
# Install bindings
# Build and install radare2 on master branch
# Remove all build dependencies
# Cleanup
# hadolint ignore=DL4006
RUN DEBIAN_FRONTEND=noninteractive dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  curl=7.64.0-4 \
  gcc=4:8.3.0-1 \
  g++=4:8.3.0-1 \
  git=1:2.20.1-2 \
  bison=2:3.3.2.dfsg-1 \
  pkg-config=0.29-6 \
  make=4.2.1-1.2 \
  gir1.2-glib-2.0=1.58.3-2 \
  gir1.2-spiceclientglib-2.0=0.35-2 \
  libqt5glib-2.0-0=1.2.0-5 \
  libspice-client-glib-2.0-8=0.35-2 \
  libspice-client-glib-2.0-dev=0.35-2 \
  libc6:i386=2.28-10 \
  libncurses5:i386=6.1+20181013-2+deb10u1 \
  libstdc++6:i386=8.3.0-6 \
  patch=2.7.6-3+deb10u1 \
  gnupg2=2.2.12-1+deb10u1 \
  sudo=1.8.27-1+deb10u1 \ 
  vim=2:8.1.0875-5 && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y --no-install-recommends \
  nodejs=10.15.2~dfsg-2 \
  npm=5.8.0+ds6-4 \
  python-pip=18.1-5 \
  python-setuptools=40.8.0-1 && \
  pip install r2pipe=="$R2_PIPE_PY_VERSION" && \
  npm install --unsafe-perm -g "r2pipe@$R2_PIPE_NPM_VERSION" && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /mnt

# use cd because we are in a volume
# hadolint ignore=DL3003
RUN git clone -b "$R2_VERSION" -q --depth 1 https://github.com/radareorg/radare2.git && \
  cd /mnt/radare2 && \
  ./sys/install.sh && \
  make install && \
  apt-get install -y xz-utils=5.2.4-1 --no-install-recommends && \
  apt-get autoremove --purge -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install pwntools==3.12.2

# Create non-root user
# hadolint ignore=DL4006
RUN useradd -m r2 && \
  adduser r2 sudo && \
  echo "r2:r2" | chpasswd

# Initilise base user
USER r2
WORKDIR /home/r2
ENV HOME /home/r2

# Setup r2pm
RUN r2pm init && \
  r2pm update && \
  chown -R r2:r2 /home/r2/.config

# Base command for container
CMD ["/bin/bash"]

