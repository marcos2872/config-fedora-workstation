#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

curl -f https://zed.dev/install.sh | sh

"${SCRIPT_DIR}/agents_config.sh" zed

echo "[zed] Configuração do Zed aplicada com sucesso."
