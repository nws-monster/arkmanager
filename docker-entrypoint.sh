#!/usr/bin/env bash

set -eo pipefail

function log { echo "$(date +\"%Y-%m-%dT%H:%M:%SZ\"): $@"; }

function backup {
    log "Creating Backup ..."
    arkmanager saveworld
    arkmanager backup
}

function stop {
    backup
    arkmanager stop --warn
    arkmanager wait --all --stopped
}

# Stop server in case of signal INT or TERM
trap stop INT
trap stop TERM

mkdir -p /ark/log

if [ ! -f /ark/server/version.txt ]; then
    log "Installing Ark ..."
    arkmanager install --verbose | tee -a "/ark/log/install-$(date +'%Y%m%d%H%M%S').log"
fi

# if [[ -n "${GAME_MOD_IDS:-}" ]]; then
#     log "Installing Mods ..."
#     arkmanager installmods --verbose | tee -a "/ark/log/installmods-$(date +'%Y%m%d%H%M%S').log"
# fi

log "Launching Ark Server ..."
(arkmanager run --verbose | tee -a "/ark/log/run-$(date +'%Y%m%d%H%M%S').log") &
arkmanpid=$!

wait $arkmanpid
