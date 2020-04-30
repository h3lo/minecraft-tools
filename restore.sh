#!/bin/bash

backupPath=/opt/minecraft/backup
instanceName="$1"

listBackups=$(find ${backupPath} -name ${instanceName}-'*' -printf '%f\n' | sort | uniq)
mostRecent=$(printf "%s" "${listBackups}" | tail -n 1)

printf "\n%s\n\n%s\n\n" \
       "Available backups to restore from:" \
       "${listBackups}" \

# Check if the server is running, if it is warn and exit.
if systemctl is-active --quiet minecraft@${instanceName}.service; then
  printf "%s\n%s\n\n%s\n\n%s" \
         "'minecraft@${instanceName}.service' is currently running." \
         " Stop it before attempting to restore!" \
         ' `sudo systemctl stop minecraft@'"${instanceName}"'.service`' \
         'Stop it now and continue? [no] '
  read yesno
  if [[ "${yesno}" = "y" ]] || \
     [[ "${yesno}" = "Y" ]] || \
     [[ "${yesno}" = "yes" ]] || \
     [[ "${yesno}" = "Yes" ]] || \
     [[ "${yesno}" = "YES" ]]; then
    sudo systemctl stop minecraft@${instanceName}.service
    sleep 10
    printf "\n"
  else
    printf "%s\n" "Canceled."
    exit 2
  fi
fi

printf "%s%s%s" 'Enter the backup to restore: [' "${mostRecent}" '] '

read restoreName
# Check if the user just pressed enter (for the most recent)
if [[ "${restoreName}" = "" ]]; then
  restoreName="${mostRecent}"
fi

# Make sure a backup actually exists for the chosen restoreName
restorePath=$(find ${backupPath} -name "${restoreName}" -print -quit)
if [ -f "${restorePath}" ] && tar -tzf "${restorePath}" >/dev/null 2>&1; then
  printf "%s\n" "Restoring '${restorePath}' to '/opt/minecraft/${instanceName}'."
elif [ ! -f "${restorePath}" ]; then
  printf "%s\n" "'${restoreName}' doesn't exist in '${backupPath}'."
else
  printf "%s\n" "'${restorePath}' is not a valid tar.gz archive."
fi

# Run a new backup, and put it in the 'other' directory.
timestamp="$(date +%Y-%m-%d-%H%M)"
tar -cpzf "${backupPath}/other/${instanceName}-${timestamp}.prerestore.tar.gz" --exclude=${instanceName}/minecraft_server.jar -C /opt/minecraft ${instanceName}/
tarexit=$?
# if tar exits with an error, rm the backup and quit
if [[ ! ${tarexit} -eq 0 ]]; then
  rm "${backupPath}/other/${instanceName}-${timestamp}.tar.gz"
  printf "%s\n" "tar failed to archive the current server."
  exit 3
fi

# Remove the existing directory
rm -rf /opt/minecraft/${instanceName}
# Restore the chosen archive
tar -xzf "${restorePath}" -C /opt/minecraft

# Hardlink the minecraft_server.jar
ln /opt/minecraft/minecraft_server.jar /opt/minecraft/${instanceName}/minecraft_server.jar

# Prompt the user to start the service again
printf "%s" "Start the service again? [yes] "
read yesno
if [[ "${yesno}" = "y" ]] || \
   [[ "${yesno}" = "Y" ]] || \
   [[ "${yesno}" = "yes" ]] || \
   [[ "${yesno}" = "Yes" ]] || \
   [[ "${yesno}" = "YES" ]] || \
   [[ "${yesno}" = "" ]]; then
  printf "%s\n" 'Running `'"sudo systemctl start minecraft@${instanceName}.service"'`.'
  sudo systemctl start minecraft@${instanceName}.service
  sleep 5
  systemctl --no-pager status minecraft@${instanceName}.service
fi
