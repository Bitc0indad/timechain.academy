ARG UBUNTU_VERSION=${UBUNTU_VERSION}
FROM ubuntu:${UBUNTU_VERSION} as base
RUN set -xe; \
apt install -y apt
RUN apt-get -y upgrade
RUN apt-get -y update
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
	debconf --reinstall \
	bsdmainutils socat \
	apt-utils sudo adduser bash-completion \
	openssh-client openssh-server \
	git make vim python3 python3-pip curl

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get install -y \
debconf --reinstall \
locales apt-utils bsdmainutils \
sudo adduser bash-completion \
openssh-client openssh-server \
git make vim python3 python3-pip mkdocs

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
locale-gen

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV DEBIAN_FRONTEND noninteractive

ARG PASSWORD=${PASSWORD}
ENV GIT_DISABLE_UNTRACKED_CACHE=true
ARG HOST_UID=${HOST_UID:-4000}
ARG HOST_USER=${HOST_USER:-nodummy}

ENV SSH_DIR=/home/${HOST_USER}/.ssh
ENV SOCKET_DIR=/home/${HOST_USER}/.ssh-agent
ENV SSH_AUTH_SOCK=/home/${HOST_USER}${SOCKET_DIR}/socket
ENV SSH_AUTH_PROXY_SOCK=/home/${HOST_USER}${SOCKET_DIR}/proxy-socket

VOLUME ${SOCKET_DIR}

RUN chmod 640 /etc/shadow
RUN chmod 4511 /usr/bin/passwd
RUN mkdir -p /var/cache/debconf

RUN if [ -r ~/.ssh/id_rsa ]; then y | ssh-keygen; fi

RUN if [ ${HOST_UID} != 0 ]; then adduser --system --disabled-password --ingroup sudo --home /home/${HOST_USER} --uid ${HOST_UID} ${HOST_USER}; fi
RUN echo root:${PASSWORD} | chpasswd
RUN echo ${HOST_USER}:${PASSWORD} | chpasswd
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

ENTRYPOINT ["docker-entrypoint.sh"]

USER ${HOST_USER}
COPY docker/bin /usr/local/bin
COPY docker/opt/healthcheck.sh /opt/healthcheck.sh

WORKDIR /home/${HOST_USER}/timechain.academy
CMD [  "python3", "-m", "pip", "install", "-r", "sources/requirements.txt" ]
CMD [ "ssh-agent" ]
HEALTHCHECK --interval=5s --timeout=1s --retries=3 CMD ["/opt/healthcheck.sh"]

