#!/usr/bin/env bash

set -eo pipefail

[ -p /tmp/FIFO-${SERVER_MAP} ] && rm /tmp/FIFO-${SERVER_MAP}
mkfifo /tmp/FIFO-${SERVER_MAP}
export TERM=linux

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
    arkmanager stop --warn --warnreason "Ark container terminated. Server is going down."
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

if [[ ! -d /ark/google-cloud-sdk && -n "${GCLOUD_SERVICE_ACCOUNT_KEY:-}" ]]; then
    download_cloud_sdk
fi

if [[ -n "${GCLOUD_SERVICE_ACCOUNT_KEY:-}" && ! -d /ark/google-cloud-sdk && ! -f /ark/google-cloud-sdk/arkmanager-sa.json ]]; then
    log "Decoding GCLOUD_SERVICE_ACCOUNT_KEY to /ark/google-cloud-sdk/arkmanager-sa.json ..."
    echo -e "$GCLOUD_SERVICE_ACCOUNT_KEY" | base64 -d - > /ark/google-cloud-sdk/arkmanager-sa.json
fi

if [[ -n "${GCLOUD_SERVICE_ACCOUNT_KEY:-}" && -d /ark/google-cloud-sdk && -f /ark/google-cloud-sdk/arkmanager-sa.json ]]; then
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

if grep -q bAllowUnlimitedRespecs $game_ini; then
    sed -i "s/^bAllowUnlimitedRespecs.*$/bAllowUnlimitedRespecs=${ALLOW_UNLIMITED_RESPECS:-true}/" $game_ini
fi
if grep -q bPvEDisableFriendlyFire $game_ini; then
    sed -i "s/^bPvEDisableFriendlyFire.*$/bPvEDisableFriendlyFire=${PVE_DISABLE_FRIENDLY_FIRE:-false}/" $game_ini
fi
if grep -q bDisableFriendlyFire $game_ini; then
    sed -i "s/^bDisableFriendlyFire.*$/bDisableFriendlyFire=${DISABLE_FRIENDLY_FIRE:-false}/" $game_ini
fi
if grep -q bDisableStructurePlacementCollision $game_ini; then
    sed -i "s/^bDisableStructurePlacementCollision.*$/bDisableStructurePlacementCollision=${DISABLE_STRUCTURE_PLACEMENT_COLLISION:-true}/" $game_ini
fi
if grep -q MatingIntervalMultiplier $game_ini; then
    sed -i "s/^MatingIntervalMultiplier.*$/MatingIntervalMultiplier=${MATING_INTERVAL_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q MatingSpeedMultiplier $game_ini; then
    sed -i "s/^MatingSpeedMultiplier.*$/MatingSpeedMultiplier=${MATING_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q EggHatchSpeedMultiplier $game_ini; then
    sed -i "s/^EggHatchSpeedMultiplier.*$/EggHatchSpeedMultiplier=${EGG_HATCH_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyMatureSpeedMultiplier $game_ini; then
    sed -i "s/^BabyMatureSpeedMultiplier.*$/BabyMatureSpeedMultiplier=${BABY_MATURE_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyCuddleIntervalMultiplier $game_ini; then
    sed -i "s/^BabyCuddleIntervalMultiplier.*$/BabyCuddleIntervalMultiplier=${BABY_CUDDLE_INTERVAL_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyCuddleGracePeriodMultiplier $game_ini; then
    sed -i "s/^BabyCuddleGracePeriodMultiplier.*$/BabyCuddleGracePeriodMultiplier=${BABY_CUDDLE_GRACE_PERIOD_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyCuddleLoseImprintQualitySpeedMultiplier $game_ini; then
    sed -i "s/^BabyCuddleLoseImprintQualitySpeedMultiplier.*$/BabyCuddleLoseImprintQualitySpeedMultiplier=${BABY_CUDDLE_LOSE_IMPRINT_QUALITY_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyImprintingStatScaleMultiplier $game_ini; then
    sed -i "s/^BabyImprintingStatScaleMultiplier.*$/BabyImprintingStatScaleMultiplier=${BABY_IMPRINTING_STAT_SCALE_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyFoodConsumptionSpeedMultiplier $game_ini; then
    sed -i "s/^BabyFoodConsumptionSpeedMultiplier.*$/BabyFoodConsumptionSpeedMultiplier=${BABY_FOOD_CONSUMPTION_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q BabyImprintAmountMultiplier $game_ini; then
    sed -i "s/^BabyImprintAmountMultiplier.*$/BabyImprintAmountMultiplier=${BABY_IMPRINT_AMOUNT_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q CropGrowthSpeedMultiplier $game_ini; then
    sed -i "s/^CropGrowthSpeedMultiplier.*$/CropGrowthSpeedMultiplier=${CROP_GROWTH_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q CropDecaySpeedMultiplier $game_ini; then
    sed -i "s/^CropDecaySpeedMultiplier.*$/CropDecaySpeedMultiplier=${CROP_DECAY_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q LayEggIntervalMultiplier $game_ini; then
    sed -i "s/^LayEggIntervalMultiplier.*$/LayEggIntervalMultiplier=${LAY_EGG_INTERVAL_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q PoopIntervalMultiplier $game_ini; then
    sed -i "s/^PoopIntervalMultiplier.*$/PoopIntervalMultiplier=${POOP_INTERVAL_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q HairGrowthSpeedMultiplier $game_ini; then
    sed -i "s/^HairGrowthSpeedMultiplier.*$/HairGrowthSpeedMultiplier=${HAIR_GROWTH_SPEED_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q SupplyCrateLootQualityMultiplier $game_ini; then
    sed -i "s/^SupplyCrateLootQualityMultiplier.*$/SupplyCrateLootQualityMultiplier=${SUPPLY_CRATE_LOOT_QUALITY_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q CraftingSkillBonusMultiplier $game_ini; then
    sed -i "s/^CraftingSkillBonusMultiplier.*$/CraftingSkillBonusMultiplier=${CRAFTING_SKILL_BONUS_MULTIPLIER:-1\.00000}/" $game_ini
fi
if grep -q FishingLootQualityMultiplier $game_ini; then
    sed -i "s/^FishingLootQualityMultiplier.*$/FishingLootQualityMultiplier=${FISHING_LOOT_QUALITY_MULTIPLIER:-1\.00000}/" $game_ini
fi

gusini=/ark/server/ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini
if [ -f $gusini ]; then
    if grep -q MaxGateFrameOnSaddles $gusini; then
        sed -i "s/^MaxGateFrameOnSaddles.*$/MaxGateFrameOnSaddles=${MAX_GATE_FRAME_ON_SADDLES:-2\.00000}/" $gusini
    else
        sed -i "/\[ServerSettings\]/a MaxGateFrameOnSaddles=${MAX_GATE_FRAME_ON_SADDLES:-2\.00000}" $gusini
    fi
fi

log "Launching Ark Server ..."

arkmanager start

log "Waiting ..."

# exit server in case of signal INT or TERM
trap exit INT
trap exit TERM

read < /tmp/FIFO-${SERVER_MAP} &
wait
