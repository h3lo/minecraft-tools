#!/bin/bash

instanceName=$1

# Short circuit and exit without doing anything if the screen process is already dead
if ! kill -0 $(systemctl show --property MainPID --value minecraft@${instanceName}.service) ; then
  exit 0
fi

/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say SERVER SHUTTING DOWN IN 20 SECONDS. SAVING ALL MAPS (in 15 seconds)..."\015'
/bin/sleep 10
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say 5"\015'
/bin/sleep 1
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say 4"\015'
/bin/sleep 1
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say 3"\015'
/bin/sleep 1
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say 2"\015'
/bin/sleep 1
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say 1"\015'
/bin/sleep 1
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "say Saving..."\015'
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "save-all"\015'
/bin/sleep 5
/usr/bin/screen -p 0 -S "mc-${instanceName}" -X eval 'stuff "stop"\015'
/bin/sleep 2
