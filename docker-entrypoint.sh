#!/usr/bin/env bash

set -eo pipefail

function log { echo "$(date +\"%Y-%m-%dT%H:%M:%SZ\"): $@"; }

function backup {
    log "Creating Backup ..."
    arkmanager saveworld
    arkmanager backup
}

function exit {
    log "Caught SIGINT or SIGTERM"
    log "Creating Backup ..."
    backup
    log "Stopping server ..."
    arkmanager stop --warn --warnreason "Ark container terminated by Server Admin. Server is going down."
    arkmanager wait --all --stopped
}

function install {
    log "Installing Ark ..."
    arkmanager install --verbose | tee -a "/ark/log/install-$(date +'%Y%m%d%H%M%S').log"
}

function download_cloud_sdk {
    log "Downloading Google Cloud SDK ..."
    curl -sL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/$CLOUD_SDK_ARCHIVE | tar -zx
}

mkdir -p /ark/log
mkdir -p /ark/backup
mkdir -p /ark/staging
mkdir -p /ark/server/ShooterGame/Saved/Config/LinuxServer

# exit server in case of signal INT or TERM
trap exit INT
trap exit TERM

if [[ ! -d /ark/google-cloud-sdk && -n "${GCLOUD_SERVICE_ACCOUNT_KEY:-}" ]]; then
    download_cloud_sdk
fi

if [[ -n ${GCLOUD_SERVICE_ACCOUNT_KEY:-} && ! -d /ark/google-cloud-sdk && ! -f /ark/google-cloud-sdk/arkmanager-sa.json ]]; then
    log "Decoding GCLOUD_SERVICE_ACCOUNT_KEY to /ark/google-cloud-sdk/arkmanager-sa.json ..."
    echo -e "$GCLOUD_SERVICE_ACCOUNT_KEY" | base64 -d - > /ark/google-cloud-sdk/arkmanager-sa.json
fi

if [[ -n ${GCLOUD_SERVICE_ACCOUNT_KEY:-} && -d /ark/google-cloud-sdk && -f /ark/google-cloud-sdk/arkmanager-sa.json ]]; then
    log "Authenticating /ark/google-cloud-sdk/arkmanager-sa.json with gcloud ..."
    bash /ark/google-cloud-sdk/bin/gcloud auth activate-service-account --key-file=/ark/google-cloud-sdk/arkmanager-sa.json
fi

game_ini=/etc/arkmanager/instances/main.Game.ini
if [ ! -f $game_ini ]; then
    echo "missing $game_ini"
    exit 1
fi

ln -sf $game_ini /ark/server/ShooterGame/Saved/Config/LinuxServer/Game.ini

if [ ! -f /ark/server/version.txt ]; then
    install
fi

if [[ -n "${GAME_MOD_IDS:-}" ]]; then
    log "Installing Mods ..."
    arkmanager installmods --verbose | tee -a "/ark/log/installmods-$(date +'%Y%m%d%H%M%S').log"
fi

log "Launching Ark Server ..."
(arkmanager run --verbose | tee -a "/ark/log/run-$(date +'%Y%m%d%H%M%S').log") &
ARKMANPID=$!
echo $ARKMANPID > ~/.arkmanpid

wait $ARKMANPID
