#!/bin/bash

exit_handler() {
  # Execute the shutdown commands
  echo -e "Stopping ${GAMESERVER}"
  exec gosu "${USER}" ./"${GAMESERVER}" stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo -e "Loading exit handler"
trap exit_handler SIGQUIT SIGINT SIGTERM

DISTRO="$(grep "PRETTY_NAME" /etc/os-release | awk -F = '{gsub(/"/,"",$2);print $2}')"
echo -e ""
echo -e "Welcome to the LinuxGSM"
echo -e "================================================================================"
echo -e "CURRENT TIME: $(date)"
echo -e "BUILD TIME: $(cat /build-time.txt)"
echo -e "GAMESERVER: ${GAMESERVER}"
echo -e "DISTRO: ${DISTRO}"
echo -e ""
echo -e "USER: ${USER}"
echo -e "UID: ${UID}"
echo -e "GID: ${GID}"
if [ -n "${LGSM_PASSWORD}" ]; then
  echo -e "${USER}:${LGSM_PASSWORD}" | chpasswd
  echo -e "Password for user ${USER} changed"
else
  echo -e "Password is empty, skipping password change"
fi
echo -e ""
echo -e "LGSM_GITHUBUSER: ${LGSM_GITHUBUSER}"
echo -e "LGSM_GITHUBREPO: ${LGSM_GITHUBREPO}"
echo -e "LGSM_GITHUBBRANCH: ${LGSM_GITHUBBRANCH}"
echo -e "LGSM_LOGDIR: ${LGSM_LOGDIR}"
echo -e "LGSM_SERVERFILES: ${LGSM_SERVERFILES}"
echo -e "LGSM_DATADIR: ${LGSM_DATADIR}"
echo -e "LGSM_CONFIG: ${LGSM_CONFIG}"

echo -e ""
echo -e "Initalising"
echo -e "================================================================================"

export LGSM_GITHUBUSER=${LGSM_GITHUBUSER}
export LGSM_GITHUBREPO=${LGSM_GITHUBREPO}
export LGSM_GITHUBBRANCH=${LGSM_GITHUBBRANCH}
export LGSM_LOGDIR=${LGSM_LOGDIR}
export LGSM_SERVERFILES=${LGSM_SERVERFILES}
export LGSM_DATADIR=${LGSM_DATADIR}
export LGSM_CONFIG=${LGSM_CONFIG}

# Export KF2 configuration variables
export KF2_GAME_PORT=${KF2_GAME_PORT}
export KF2_QUERY_PORT=${KF2_QUERY_PORT}
export KF2_WEBADMIN_PORT=${KF2_WEBADMIN_PORT}
export KF2_WEBADMIN=${KF2_WEBADMIN}
export KF2_STEAM_PORT=${KF2_STEAM_PORT}
export KF2_NTP_PORT=${KF2_NTP_PORT}

cd /app || exit

# start cron
cron

echo -e ""
echo -e "Check Permissions"
echo -e "================================="
echo -e "setting UID to ${UID}"
usermod -u "${UID}" -m -d /data linuxgsm > /dev/null 2>&1
echo -e "setting GID to ${GID}"
groupmod -g "${GID}" linuxgsm
echo -e "updating permissions for /data"
chown -R "${USER}":"${USER}" /data
echo -e "updating permissions for /app"
chown -R "${USER}":"${USER}" /app
export HOME=/data

echo -e ""
echo -e "Custom Docker Scripts"
echo -e "================================="
if ls /app/docker-scripts/*.sh 1> /dev/null 2>&1; then
  for script in /app/docker-scripts/*.sh; do
    echo -e "$script"
    bash "$script"
    echo -e "---"
  done
else
  echo -e "No .sh files found in /app/docker-scripts"
fi

echo -e ""
echo -e "Config Profile"
echo -e "================================="
if [ ! -f $HOME/.bashrc ]; then
  echo -e "Creating $HOME/.bashrc"
  cp /etc/skel/.bashrc $HOME/.bashrc
  echo -e "Setting ownership for $HOME/.bashrc"
  chown "${USER}":"${USER}" $HOME/.bashrc
else
  echo -e "$HOME/.bashrc already exists"
fi

if [ ! -d $HOME/.ssh ]; then
  echo -e "Creating $HOME/.ssh"
  mkdir -p $HOME/.ssh
  echo -e "Setting ownership and permissions for $HOME/.ssh"
  chown "${USER}":"${USER}" $HOME/.ssh
  chmod 700 $HOME/.ssh
else 
  echo -e "$HOME/.ssh already exists"
fi

if [ ! -f $HOME/.ssh/authorized_keys ]; then
  echo -e "Creating authorized_keys"
  touch $HOME/.ssh/authorized_keys
  
  if [ -n "${SSH_KEY}" ]; then
    IFS=',' read -ra KEYS <<< "${SSH_KEY}"
    for key in "${KEYS[@]}"; do
      echo -e "${key}" >> $HOME/.ssh/authorized_keys
    done
  else
    echo -e "SSH_KEY is empty, skipping..."
  fi
  
  echo -e "Setting ownership and permissions for $HOME/.ssh/authorized_keys"
  chown "${USER}":"${USER}" $HOME/.ssh/authorized_keys
  chmod 600 $HOME/.ssh/authorized_keys
else
  echo -e "authorized_keys already exists"
fi

echo -e ""
echo -e "Switch to user ${USER}"
echo -e "================================="
exec gosu "${USER}" /app/entrypoint-user.sh &
wait
