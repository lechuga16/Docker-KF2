#!/bin/bash

# Descarga Workshop de KF2 si KF2_WORKSHOP contiene IDs
run_workshop_download() {
  local script_path="/app/server-scripts/KF2-workshop-download.sh"
  local raw="${KF2_WORKSHOP:-}"
  # Saltar si no hay variable o es una lista vacía
  if [ -z "$raw" ] || [ "$raw" = "[]" ]; then
    echo -e "ℹ️  KF2_WORKSHOP vacío; no se ejecuta descarga de Workshop"
    return 0
  fi
  if [ ! -x "$script_path" ] && [ -f "$script_path" ]; then
    chmod +x "$script_path" || true
  fi
  if [ -f "$script_path" ]; then
    echo -e "🛠️  Ejecutando descarga de Workshop…"
    QUIET=1 VERY_QUIET=1 FORCE_STEAM_HOME_IN_WORKDIR=1 bash "$script_path" || \
      echo -e "⚠️  Descarga de Workshop finalizó con errores (se continúa)"
  else
    echo -e "ℹ️  Script de Workshop no encontrado en $script_path"
  fi
}

# Function to run KF2 configuration scripts
run_kf2_config_scripts() {
  local server_scripts_dir="/app/server-scripts"

  if [ ! -d "${server_scripts_dir}" ]; then
    echo -e "ℹ️  No server-scripts directory found"
    return 0
  fi

  echo -e "🔧 Running KF2 configuration scripts..."

  if ls "${server_scripts_dir}"/*.sh 1> /dev/null 2>&1; then
    for script in "${server_scripts_dir}"/*.sh; do
      script_name=$(basename "${script}")
      # Evitar ejecutar el downloader aquí; se invoca explícitamente en puntos controlados
      if [ "$script_name" = "KF2-workshop-download.sh" ]; then
        echo -e "⏭️  Omitiendo en lote: ${script_name} (se ejecuta aparte)"
        continue
      fi
      echo -e "▶️  Executing: ${script_name}"
      chmod +x "${script}" || true
      if bash "${script}"; then
        echo -e "✅ ${script_name} completed successfully"
      else
        echo -e "⚠️  ${script_name} failed with exit code: $?"
      fi
    done
  else
    echo -e "ℹ️  No .sh files found in ${server_scripts_dir}"
  fi

  echo -e "🎯 KF2 configuration completed"
}

exit_handler_user() {
  echo -e "Stopping ${GAMESERVER}"
  ./${GAMESERVER} stop
  exitcode=$?
  exit ${exitcode}
}

# Exit trap
echo -e "Loading exit handler"
trap exit_handler_user SIGQUIT SIGINT SIGTERM

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
  echo -e ""
  echo -e "creating ${GAMESERVER}"
  echo -e "================================="
  ./linuxgsm.sh "${GAMESERVER}"
fi

# Symlink LGSM_CONFIG to /app/lgsm/config-lgsm
if [ ! -d "/app/lgsm/config-lgsm" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_CONFIG}"
  echo -e "================================="
  ln -s "${LGSM_CONFIG}" "/app/lgsm/config-lgsm"
fi

# Symlink LGSM_SERVERCFG to /app/serverfiles
if [ ! -d "/app/serverfiles" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_SERVERCFG}"
  echo -e "================================="
  ln -s "${LGSM_SERVERFILES}" "/app/serverfiles"
fi

# Symlink LGSM_LOGDIR to /app/log
if [ ! -d "/app/log" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_LOGDIR}"
  echo -e "================================="
  ln -s "${LGSM_LOGDIR}" "/app/log"
fi

# Symlink LGSM_DATADIR to /app/lgsm/data
if [ ! -d "/app/lgsm/data" ]; then
  echo -e ""
  echo -e "creating symlink for ${LGSM_DATADIR}"
  echo -e "================================="
  ln -s "${LGSM_DATADIR}" "/app/lgsm/data"
fi

# npm install in /app/lgsm
if [ -f "/app/lgsm/package.json" ]; then
  echo -e ""
  echo -e "npm install in /app/lgsm"
  echo -e "================================="
  cd /app/lgsm || exit
  npm install
  cd /app || exit
fi

# Clear modules directory if not master
if [ "${LGSM_GITHUBBRANCH}" != "master" ]; then
  echo -e "not master branch, clearing modules directory"
  rm -rf /app/lgsm/modules/*
  ./${GAMESERVER} update-lgsm
elif [ -d "/app/lgsm/modules" ]; then
  echo -e "ensure all modules are executable"
  chmod +x /app/lgsm/modules/*
fi

# Enable developer mode
if [ "${LGSM_DEV}" == "true" ]; then
  echo -e "developer mode enabled"
  ./${GAMESERVER} developer
fi

# Install game server
if [ -z "$(ls -A -- "/data/serverfiles" 2> /dev/null)" ]; then
  echo -e ""
  echo -e "Installing ${GAMESERVER}"
  echo -e "================================="
  ./${GAMESERVER} auto-install
  install=1
  # Tras instalación inicial, descargar Workshop si aplica
  run_workshop_download
else
  echo -e ""
  # Sponsor to display LinuxGSM logo
  ./${GAMESERVER} sponsor
fi

if [ -n "${UPDATE_CHECK}" ] && [ "${UPDATE_CHECK}" != "0" ]; then
  echo -e ""
  echo -e "Starting Update Checks"
  echo -e "================================="
  echo -e "*/${UPDATE_CHECK} * * * * /app/${GAMESERVER} update > /dev/null 2>&1" | crontab -
  echo -e "update will check every ${UPDATE_CHECK} minutes"
else
  echo -e ""
  echo -e "Update checks are disabled"
  echo -e "================================="
fi

# Update or validate game server
if [ -z "${install}" ]; then
  echo -e ""
  if [ "${VALIDATE_ON_START,,}" = "true" ]; then
    echo -e "Validating ${GAMESERVER}"
    echo -e "================================="
    ./${GAMESERVER} validate
  else
    echo -e "Checking for Update ${GAMESERVER}"
    echo -e "================================="
    ./${GAMESERVER} update
  fi
fi

echo -e ""
echo -e "KF2 Configuration Check"
echo -e "========================"
run_kf2_config_scripts

echo -e ""
echo -e "Workshop download (pre-start)"
echo -e "============================"
run_workshop_download

echo -e ""
echo -e "Starting ${GAMESERVER}"
echo -e "================================="
./"${GAMESERVER}" start
sleep 5
./"${GAMESERVER}" details
sleep 2
echo -e "Tail log files"
echo -e "================================="
tail -F "${LGSM_LOGDIR}"/{console,script}/*{console,script}.log &
wait
