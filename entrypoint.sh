#!/bin/bash
set -eu

MAA_URL="https://github.com/MaaAssistantArknights/maa-cli/releases/latest/download/maa_cli-x86_64-unknown-linux-gnu.tar.gz"
TEMP_TAR="/tmp/maa.tar.gz"
INSTALL_PATH="/usr/local/bin"

if [ ! -x "${INSTALL_PATH}/maa" ]; then
    echo
    echo "Downloading maa-cli..."
    curl -L -o "${TEMP_TAR}" "${MAA_URL}"
    tar -xzvf "${TEMP_TAR}" -C /tmp

    MAA_FILE=$(find /tmp -type f -name "maa" | head -n 1)
    if [ -z "$MAA_FILE" ]; then
        echo "Error: maa-cli binary not found in the archive!"
        exit 1
    fi

    mv "$MAA_FILE" "${INSTALL_PATH}/maa"
    chmod +x "${INSTALL_PATH}/maa"

    PARENT_DIR=$(dirname "$MAA_FILE")
    if [[ "$PARENT_DIR" != "/tmp" ]]; then
        rm -rf "$PARENT_DIR"
    else
        rm -f "$MAA_FILE"
    fi
    rm -f "${TEMP_TAR}"
fi

MAA_INSTALL_FILE="/root/.local/share/maa/"
if [ ! -x "${MAA_INSTALL_FILE}" ]; then
    echo
    echo "Install maa maa_core and resources..."
    if ! maa install; then
        echo "maa_core install failed"
        exit 1
    fi
fi
  
echo
echo "Update maa maa_core and resources..."
if ! maa update; then
    echo "maa update failed, continuing anyway..."
fi

echo
echo "Hot update for resources..."
if ! maa hot-update; then
    echo "maa hot-update failed, continuing anyway"
fi

echo
echo "Update maa-cli..."
if ! maa self update; then
    echo "maa self update failed, continuing anyway..."
fi

CRON_FILE="/root/maa-cron"
if [ ! -f "$CRON_FILE" ]; then
    echo "* * * * * root echo 请编辑maa-cron文件 >> /proc/1/fd/1 2>&1" > "$CRON_FILE"
    echo "" >> "$CRON_FILE"
else
    if [ -n "$(tail -c1 "$CRON_FILE")" ]; then
        echo "" >> "$CRON_FILE"
    fi
fi
chmod 0644 "$CRON_FILE"
ln -sf "$CRON_FILE" /etc/cron.d/maa-cron

CLI_FILE="/root/.config/maa/cli.toml"
PROFILES_FILE="/root/.config/maa/profiles/default.toml"
INFRAST_DIR="/root/.config/maa/infrast"
INFRAST_FILE="/root/.config/maa/infrast/infrast.json"
TASKS_DIR="/root/.config/maa/tasks"
TASKS_FILE="/root/.config/maa/tasks/tasks.yaml"

CLI_URL="https://github.com/ERSTT/MAA-Docker/raw/refs/heads/main/cli.toml"
INFRAST_URL="https://github.com/ERSTT/MAA-Docker/raw/refs/heads/main/infrast.json"
PROFILES_URL="https://github.com/ERSTT/MAA-Docker/raw/refs/heads/main/default.toml"
TASKS_URL="https://github.com/ERSTT/MAA-Docker/raw/refs/heads/main/tasks.yaml"

if [ ! -f "$CLI_FILE" ]; then
echo
echo "Downloading cli file..."
mkdir -p "$(dirname "$CLI_FILE")"
curl -L -o "${CLI_FILE}" "${CLI_URL}"
fi

if [ ! -f "$INFRAST_FILE" ]; then
echo
echo "Downloading infrast file..."
mkdir -p "$(dirname "$INFRAST_FILE")"
curl -L -o "${INFRAST_FILE}" "${INFRAST_URL}"
fi

if [ ! -f "${PROFILES_FILE}" ]; then
echo
echo "Downloading profiles file..."
mkdir -p "$(dirname "$PROFILES_FILE")"
curl -L -o "${PROFILES_FILE}" "${PROFILES_URL}"
fi

if [ ! -f "${TASKS_FILE}" ]; then
echo
echo "Downloading tasks file..."
mkdir -p "$(dirname "$TASKS_FILE")"
curl -L -o "${TASKS_FILE}" "${TASKS_URL}"
fi

if [ ! -f "/root/Maa-cli配置文件.toml" ]; then
    ln -sf ./.config/maa/cli.toml /root/Maa-cli配置文件.toml
fi

if [ ! -f "/root/Maa配置文件.toml" ]; then
    ln -sf ./.config/maa/profiles/default.toml /root/Maa配置文件.toml
fi

if [ ! -d "/root/Maa基建目录" ]; then
    ln -sf ./.config/maa/infrast /root/Maa基建目录
fi

if [ ! -f "/root/Maa基建配置文件.json" ]; then
    ln -sf ./.config/maa/infrast/infrast.json /root/Maa基建配置文件.json
fi

if [ ! -d "/root/Maa任务目录" ]; then
    ln -sf ./.config/maa/tasks /root/Maa任务目录
fi

if [ ! -f "/root/Maa任务配置文件.yaml" ]; then
    ln -sf ./.config/maa/tasks/tasks.yaml /root/Maa任务配置文件.yaml
fi

echo "Starting cron with tasks from $CRON_FILE"
cron -f
