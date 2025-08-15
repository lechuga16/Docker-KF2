#!/bin/bash
# Script: SSH-config.sh
# Description: Configures the SSH service in the container, generates host keys (RSA, ECDSA, and ED25519),
# and updates the SSH configuration to use a persistent directory ($HOME/ssh). It also enables or disables
# password authentication based on the LGSM_PASSWORD variable.

SSH_PERSIST_DIR="$HOME/ssh"
if [ ! -d "$SSH_PERSIST_DIR" ]; then
    mkdir -p "$SSH_PERSIST_DIR"
fi

if [ ! -f "$SSH_PERSIST_DIR/ssh_host_rsa_key" ]; then
    ssh-keygen -t rsa -b 4096 -f "$SSH_PERSIST_DIR/ssh_host_rsa_key" -N ''
fi

if [ ! -f "$SSH_PERSIST_DIR/ssh_host_ecdsa_key" ]; then
    ssh-keygen -t ecdsa -f "$SSH_PERSIST_DIR/ssh_host_ecdsa_key" -N ''
fi

if [ ! -f "$SSH_PERSIST_DIR/ssh_host_ed25519_key" ]; then
    ssh-keygen -t ed25519 -f "$SSH_PERSIST_DIR/ssh_host_ed25519_key" -N ''
fi

sed -i "s|#HostKey /etc/ssh/ssh_host_rsa_key|HostKey $clear/ssh_host_rsa_key|" /etc/ssh/sshd_config
sed -i "s|#HostKey /etc/ssh/ssh_host_ecdsa_key|HostKey $SSH_PERSIST_DIR/ssh_host_ecdsa_key|" /etc/ssh/sshd_config
sed -i "s|#HostKey /etc/ssh/ssh_host_ed25519_key|HostKey $SSH_PERSIST_DIR/ssh_host_ed25519_key|" /etc/ssh/sshd_config


# --- SOPORTE CAMBIO DINÁMICO DE PasswordAuthentication Y PUERTO SSH ---
ssh_config_changed=0

# PasswordAuthentication
desired_auth="no"
[ -n "${LGSM_PASSWORD}" ] && desired_auth="yes"
current_auth=$(grep -E '^[# ]*PasswordAuthentication[ ]+(yes|no)' /etc/ssh/sshd_config | tail -1 | awk '{print $2}')
if [ -n "$current_auth" ]; then
    if [ "$current_auth" != "$desired_auth" ]; then
        sed -i "/^[# ]*PasswordAuthentication[ ]\+/c\PasswordAuthentication ${desired_auth}" /etc/ssh/sshd_config
        echo "[SSH-config.sh] PasswordAuthentication cambiado: $current_auth → $desired_auth"
        ssh_config_changed=1
    else
        echo "[SSH-config.sh] PasswordAuthentication ya configurado en $desired_auth, sin cambios."
    fi
else
    echo "PasswordAuthentication ${desired_auth}" >> /etc/ssh/sshd_config
    echo "[SSH-config.sh] PasswordAuthentication agregado: $desired_auth"
    ssh_config_changed=1
fi

# Port
if [ -n "${SSH_PORT}" ]; then
    current_port=$(grep -E '^[# ]*Port[ ]+[0-9]+' /etc/ssh/sshd_config | tail -1 | awk '{print $2}')
    if [ -n "$current_port" ]; then
        if [ "$current_port" != "$SSH_PORT" ]; then
            sed -i "/^[# ]*Port[ ]\+/c\Port ${SSH_PORT}" /etc/ssh/sshd_config
            echo "[SSH-config.sh] Puerto SSH cambiado: $current_port → $SSH_PORT"
            ssh_config_changed=1
        else
            echo "[SSH-config.sh] Puerto SSH ya configurado en $SSH_PORT, sin cambios."
        fi
    else
        echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
        echo "[SSH-config.sh] Puerto SSH agregado: $SSH_PORT"
        ssh_config_changed=1
    fi
else
    echo "[SSH-config.sh] SSH_PORT no definido, usando configuración por defecto."
fi

# Recargar/reiniciar solo si hubo cambios
if [ "$ssh_config_changed" = "1" ]; then
    service ssh reload || service ssh restart
fi

# Start the SSH service si no está corriendo
if ! pgrep -x "sshd" > /dev/null; then
    service ssh start
fi
