## Overview

Based on [nhalase/steamcmd](https://github.com/nws-monster/steamcmd) and [ark-server-tools](https://github.com/arkmanager/ark-server-tools).

**NOTE: I USE THIS FOR MY HOMELAB SERVERS.** Your mileage may vary.

- ubuntu focal (20.04)
- `steam` user and user home created (`1000:1000` at `/home/steam`)
- timezone is set to America/Chicago
- enUS.UTF8 locale
- `steamcmd` is symlinked to `/usr/bin/steamcmd`
- `arkmanager` is installed globally

## Simple usage

```
# unique per instance
docker volume create arkmanager_theisland
# must be shared between the cluster
docker volume create arkmanager_cluster
docker run -d --rm --name arkmanager -v arkmanager_theisland:/ark -v arkmanager_cluster:/cluster -p {{your-host-ip}}:7777:7777/udp -p {{your-host-ip}}:7778:7778/udp -p {{your-host-ip}}:27015:27015/udp -p {{your-host-ip}}:27020:27020 --ulimit nofile=1000000:1000000 --memory="8g" --memory-reservation="6g" nhalase/arkmanager:latest
```

## Environment

If you're running multiple instances, make sure they don't have the same ports.

If you're running a cluster, make sure the CLUSTER_ID is the same across all instances.

```
SERVER_MAP=TheIsland
CLUSTER_ID=changeit
SESSION_NAME=changeit
SERVER_PASSWORD=changeit
SPECTATOR_PASSWORD=changeit
SERVER_ADMIN_PASSWORD=changeit
PORT=7777
QUERY_PORT=27015
RCON_ENABLED=true
RCON_PORT=27020
```

## Packages

```
perl-modules
libc6-i386
libsdl2-2.0-0:i386
```
