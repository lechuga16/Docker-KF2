#
# LinuxGSM Killing Floor 2 Dockerfile with SSH Support
#
# https://github.com/lechuga16/Docker-KF2
#

FROM ghcr.io/gameservermanagers/linuxgsm:ubuntu-24.04

LABEL org.opencontainers.image.title="KF2 LinuxGSM Server"
LABEL org.opencontainers.image.description="Killing Floor 2 dedicated server using LinuxGSM with SSH support"
LABEL org.opencontainers.image.url="https://github.com/lechuga16/Docker-KF2"
LABEL org.opencontainers.image.source="https://github.com/lechuga16/Docker-KF2"
LABEL org.opencontainers.image.vendor="lechuga16"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="lechuga16"
LABEL version="1.0.0"

ARG SHORTNAME=kf2
ENV GAMESERVER=kf2server

WORKDIR /app

## Auto install game server requirements and SSH server
RUN depshortname=$(curl --connect-timeout 10 -s https://raw.githubusercontent.com/GameServerManagers/LinuxGSM/master/lgsm/data/ubuntu-24.04.csv |awk -v shortname="kf2" -F, '$1==shortname {$1=""; print $0}') \
  && echo "**** Update package list ****" \
  && apt-get update \
  && if [ -n "${depshortname}" ]; then \
  echo "**** Install ${depshortname} ****" \
  && apt-get install -y ${depshortname}; \
  fi \
  && echo "**** Install SSH server ****" \
  && apt-get install -y openssh-server \
  && echo "**** Cleanup ****" \
  && apt-get -y autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

HEALTHCHECK --interval=1m --timeout=1m --start-period=2m --retries=1 CMD /app/entrypoint-healthcheck.sh || exit 1

RUN date > /build-time.txt

COPY docker-scripts/ /app/docker-scripts/
COPY server-scripts/ /app/server-scripts/
COPY entrypoint.sh /app/entrypoint.sh
COPY entrypoint-user.sh /app/entrypoint-user.sh

ENTRYPOINT ["/bin/bash", "./entrypoint.sh"]