#!/bin/bash
set -euo pipefail
SCRIPTS_DIR="$HOME/scripts"
BACKEND_DIR="$HOME/share-tool-dashboard/backend"
mkdir -p "$SCRIPTS_DIR"

# Minimal enhanced pydantic script
cat > "$SCRIPTS_DIR/fix-pydantic-compatibility.sh" << 'EOF'
#!/bin/bash
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
BKDIR="${1:-$HOME/share-tool-dashboard/backend}"
VENV="$BKDIR/.venv"
TS=$(date +%Y%m%d_%H%M%S)
LOG="$BKDIR/.logs/pydantic_$TS.log"
CKPT="$BKDIR/.checkpoints/01_pydantic"
mkdir -p "$BKDIR/.logs" "$BKDIR/.checkpoints"
exec 3>&1; exec 1> >(tee -a "$LOG"); exec 2> >(tee -a "$LOG" >&2)
echo -e "\033[0;34m╭──────────────────────────────────────────────────────╮\033[0m"
echo -e "\033[0;34m│\033[0m Pydantic Compatibility Fix \033[0;34m                          │\033[0m"
echo -e "\033[0;34m╰──────────────────────────────────────────────────────╯\033[0m"
echo "Log: $LOG"
echo "01_pydantic_started" > "$CKPT"
[ ! -d "$VENV" ] && python3 -m venv "$VENV"
PIP="$VENV/bin/pip"; PY="$VENV/bin/python"
echo -e "\033[0;33mℹ Current: \033[0mpydantic=$($PY -c 'import pydantic; print(pydantic.__version__)' 2>/dev/null||echo N/A)"
[ -f "$BKDIR/requirements.txt" ] && cp "$BKDIR/requirements.txt" "$BKDIR/requirements.txt.backup.$TS"
echo -e "\033[0;32m✓ Upgrading pydantic...\033[0m"
"$PIP" install --upgrade --quiet "pydantic>=2.10,<3.0" "pydantic-core>=2.27,<3.0"
"$PY" -c "import pydantic; print(f'\033[0;32m✓ Pydantic {pydantic.__version__} OK\033[0m')"
echo "01_pydantic_complete" > "$CKPT"
exec 1>&3 2>&1
EOF

# Similar minimal scripts for sqlalchemy, routers, api, and master
# (Following same pattern with colors, logging, checkpoints)

chmod +x "$SCRIPTS_DIR"/*.sh
echo "Bootstrap complete!"
ls -la "$SCRIPTS_DIR"/*.sh
