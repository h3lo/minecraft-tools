#!/bin/bash -x

svcName="$1"
timestamp="$(date +%Y-%m-%d-%H%M)"
hour=${timestamp:11:2}
backupRoot=/opt/minecraft/backup
path="${backupRoot}/last24/${svcName}-${timestamp}.tar.gz"

# If the service isn't running, don't backup unless the --manual flag is specified
systemctl is-active --quiet minecraft@${svcName}.service
svcStatus=$?
if [[ ${svcStatus} != 0 ]] && [[ "$2" != "--manual" ]]; then
  exit 0
fi

### TODO - add --manual functionality and more detailed checks for service status
# No need to send screen commands if the server isn't running.
#  But we still want to if it is when we use --manual
# Also, have --manual backups include .manual.tar.gz as the end of the archive name

# Say some shit
/usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup will start in 30 seconds. This may cause a momentary freeze in game, so if you are in danger, get to safety or disconnect!"\015'
sleep 27
# Disable world saving so no writes to the world data will occur
/usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "save-off"\015'
sleep 2
# Force a world save
/usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup starting..."\015'
sleep 1
/usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "save-all"\015'
# added some sleep to give it a chance to finish saving before creating tarball
sleep 30

# Backup
if [[ ! -d "${backupRoot}/last24" ]]; then
  mkdir -p "${backupRoot}/last24"
fi
tar -cpzf "${path}" --exclude=${svcName}/minecraft_server.jar -C /opt/minecraft ${svcName}/
tarexit=$?

# if the error is due to the log changing, we should ignore it and call it success
if [[ ${tarexit} -eq 0 || \
      ${tarexit} -eq 1 && \
      $(tar --compare --file="${path}" -C /opt/minecraft | \
        grep -v ${svcName}'/logs/latest.log:' | \
        wc -l) -eq 0 ]]; then
  # This is a successful backup, either there was no error, or the error was due to the log changing
  incon=""
  /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup completed successfully!"\015'
else
  # if tar encountered some error, or the files changed during tarballing, wait a bit and try again
  /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup failed, retrying in 3 minutes."\015'
  sleep 180
  tar -cpzf "${path}" --exclude=${svcName}/minecraft_server.jar -C /opt/minecraft ${svcName}/
  tarexit=$?

  if [[ ${tarexit} -eq 0 || \
      ${tarexit} -eq 1 && \
      $(tar --compare --file="${path}" -C /opt/minecraft | \
        grep -v ${svcName}'/logs/latest.log:' | \
        wc -l) -eq 0 ]]; then
    # This is a successful backup, either there was no error, or the error was due to the log changing
    incon=""
    /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup completed successfully!"\015'
  else
    # If it happens again, rename the file to make it clear
    mv "${path}" "${path}.inconsistent"
    incon=.inconsistent
    # Say some shit
    /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup FAILED!!!!"\015'
    #### TO DO ####
    # Add a pushover API call to notify of failed backup
  fi
fi

## We can skip this post check since tar will return exit code 1 if the files change
##  or exit code 2 if it encounters other errors
# Check if backup completed successfully
#tar --compare --file="${path}" -C /opt/minecraft

### This old way of checking was dirty and didn't really work, left it for reference; it is replaced by the logic above
# If tar detects that the directory had changes, wait 3m and try again
#occur=$(grep -c "file changed as we read it" /opt/minecraft/backup.log)
#if [[ ${occur} -gt 0 ]]; then
#  /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup failed, retrying in 3 minutes."\015'
#  sleep 180
#  tar -cpzf "${path}" --exclude=/opt/minecraft/survival/minecraft_server.jar -C /opt/minecraft survival/
#  # If it happens again, rename the file to make it clear
#  if [[ $(( $(grep -c "file changed as we read it" /opt/minecraft/backup.log) - ${occur} )) -gt 0 ]]; then
#    mv "${path}" "${path}.inconsistent"
#    incon=.inconsistent
#    # Say some shit
#    /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup FAILED!!!!"\015'
#    #### TO DO ####
#    # Add a pushover API call to notify of failed backup
#  else
#    incon=""
#  fi
#fi

# Re-Enable automatic world saving
/usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "save-on"\015'
# Say some shit -- moved this up to the backup logic so that it is more accurate
#/usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say Backup complete!"\015'

# Copy backups taken at 4am to the parent directory for longer term storage
if [[ "${hour}" == "04" ]]; then
  # Hard links don't work via VBox shared folders, so we have to just copy it
  cp "${path}" "${backupRoot}/${svcName}-${timestamp}.tar.gz${incon}"
fi

# Delete hourly backups older than 24 hours
find "${backupRoot}/last24" -maxdepth 1 -type f -mtime +0 -exec rm -f {} +
# Delete daily (4am) backups older than 7 days
find "${backupRoot}" -maxdepth 1 -type f -name "${svcName}"'-*' -mtime +6 -exec rm -f {} +

# Do some other sanity checks to warn players if there might be an issue
# We expect there to be 24 backups in the last24 directory and 7 in the parent
# If there are less, show a warning
if [[ $(find "${backupRoot}/last24" -maxdepth 1 -type f | wc -l) -lt 24 ]]; then
  /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say There are less than 24 backups in the hourly backup location. There may be an issue with the backup script. Please investigate!!!"\015'
fi
if [[ $(find "${backupRoot}" -maxdepth 1 -type f -name "${svcName}"'-*' | wc -l) -lt 7 ]]; then
  /usr/bin/screen -p 0 -S mc-${svcName} -X eval 'stuff "say There are less than 7 backups in the daily backup location. There may be an issue with the backup script. Please investigate!!!"\015'
fi

# Upload backups somewhere else
##Nawp, this will be done on the backend
