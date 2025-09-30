#!/bin/bash
set -eu

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

    echo "Install maa maa_core and resources..."
    if ! maa install; then
        echo "maa_core install failed"
        exit 1
    fi

    echo "Hot update for resources..."
    if ! maa hot-update; then
        echo "maa hot-update failed, continuing anyway"
    fi

    PARENT_DIR=$(dirname "$MAA_FILE")
    if [[ "$PARENT_DIR" != "/tmp" ]]; then
        rm -rf "$PARENT_DIR"
    else
        rm -f "$MAA_FILE"
    fi
    rm -f "${TEMP_TAR}"
fi
echo "Update maa maa_core and resources..."
if ! maa update; then
    echo "maa update failed, continuing anyway..."
fi

echo "Update maa-cli..."
if ! maa self update; then
    echo "maa self update failed, continuing anyway..."
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
