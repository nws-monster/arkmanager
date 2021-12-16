ARG steamcmd_base_version=latest
FROM nhalase/steamcmd:${steamcmd_base_version} as base

ARG steam_uid=1000
ARG steam_gid=1000
ARG steam_user="steam"
ARG description="A image for an Ark server"
ARG packages_list=packages.list
ARG sysctlconf=/etc/sysctl.conf
ARG limitsconf=/etc/security/limits.conf
ARG pamd_common_session=/etc/pam.d/common-session

USER root
WORKDIR /root

COPY ${packages_list} /etc/apt/ark-packages.list

RUN echo >> ${sysctlconf} && echo "fs.file-max=100000" >> ${sysctlconf} \
    && sysctl -p ${sysctlconf} \
    && echo >> ${limitsconf} && echo "*               soft    nofile          1000000" >> ${limitsconf} \
    && echo "*               hard    nofile          1000000" >> ${limitsconf} \
    && echo >> ${pamd_common_session} && echo "session required pam_limits.so" >> ${pamd_common_session}

FROM base as builder

RUN dpkg --add-architecture i386 && apt-get update && apt-get update && apt-get install -y \
    $(grep -vE "^\s*#" /etc/apt/ark-packages.list | tr "\n" " ") \
    && rm -rf /var/lib/apt/lists/*

FROM builder as arkmanager

ARG description="A base image for an arkmanager container"

LABEL nws.monster.stack.description=${description}

ENV SERVER_MAP=TheIsland \
    CLUSTER_ID=changeit \
    SESSION_NAME=theisland-ark.nws.monster \
    SERVER_PASSWORD=changeit \
    SPECTATOR_PASSWORD=changeit \
    SERVER_ADMIN_PASSWORD=changeit \
    PORT=7777 \
    QUERY_PORT=27015 \
    RCON_ENABLED=true \
    RCON_PORT=27020

ARG arkmanager_cfg=arkmanager.cfg
ARG arkmanager_main_instance_cfg=main.cfg
ARG game_ini=Game.ini
ARG gameusersettings_ini=GameUserSettings.ini
ARG docker_entrypoint=docker-entrypoint.sh

RUN curl -sL https://git.io/arkmanager | bash -s ${steam_user} --install-service

COPY ${arkmanager_cfg} /etc/arkmanager/arkmanager.cfg
COPY ${arkmanager_main_instance_cfg} /etc/arkmanager/instances/main.cfg
COPY ${game_ini} /etc/arkmanager/instances/main.Game.ini
COPY ${gameusersettings_ini} /etc/arkmanager/instances/main.GameUserSettings.ini
COPY ${docker_entrypoint} /usr/local/bin/docker-entrypoint.sh

USER ${steam_uid}:${steam_gid}

WORKDIR /cluster

RUN touch .gitkeep

WORKDIR /ark

COPY --chown=${steam_uid}:${steam_gid} ${gameusersettings_ini} /ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
COPY --chown=${steam_uid}:${steam_gid} ${game_ini} /ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini

CMD [ "/usr/local/bin/docker-entrypoint.sh" ]
