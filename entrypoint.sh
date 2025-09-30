#!/bin/bash
set -e

MAA_URL="https://github.com/MaaAssistantArknights/maa-cli/releases/latest/download/maa_cli-x86_64-unknown-linux-gnu.tar.gz"
TEMP_TAR="/tmp/maa.tar.gz"
INSTALL_PATH="/usr/local/bin"

if [ ! -x "${INSTALL_PATH}/maa" ]; then
    echo "Downloading maa-cli from ${MAA_URL}..."
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

CRON_FILE="/root/maa-cron"
if [ ! -f "$CRON_FILE" ]; then
    echo "* * * * * root echo 请编辑maa-cron文件 >> /proc/1/fd/1 2>&1" > "$CRON_FILE"
    echo "" >> "$CRON_FILE"
fi
chmod 0644 "$CRON_FILE"
ln -sf "$CRON_FILE" /etc/cron.d/maa-cron

echo "Starting cron with tasks from $CRON_FILE"
cron -f
