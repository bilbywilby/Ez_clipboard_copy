#!/bin/bash
set -euo pipefail
SCRIPTS_DIR="$HOME/scripts"
BACKEND_DIR="$HOME/share-tool-dashboard/backend"
mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/fix-pydantic-compatibility.sh" << 'PYEOF'
#!/bin/bash
set -euo pipefail
BACKEND_DIR="${1:-$HOME/share-tool-dashboard/backend}"
VENV_DIR="$BACKEND_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then python3 -m venv "$VENV_DIR" || exit 1; fi
PIP="$VENV_DIR/bin/pip"
PY="$VENV_DIR/bin/python"
if [ -f "$BACKEND_DIR/requirements.txt" ]; then cp "$BACKEND_DIR/requirements.txt" "$BACKEND_DIR/requirements.txt.backup.$(date +%Y%m%d_%H%M%S)"; fi
"$PIP" install --upgrade --quiet "pydantic>=2.10,<3.0" "pydantic-core>=2.27,<3.0"
echo "Verifying..."
"$PY" -c "import pydantic; print(f'pydantic:{pydantic.__version__}')" && echo "OK" || exit 1
PYEOF

cat > "$SCRIPTS_DIR/fix-sqlalchemy-python313.sh" << 'SQLEOF'
#!/bin/bash
set -euo pipefail
BACKEND_DIR="${1:-$HOME/share-tool-dashboard/backend}"
VENV_DIR="$BACKEND_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then echo "No venv"; exit 1; fi
PIP="$VENV_DIR/bin/pip"
PY="$VENV_DIR/bin/python"
"$PIP" install --upgrade --quiet "sqlalchemy>=2.0.30,<3.0" "aiosqlite>=0.20"
echo "Verifying..."
"$PY" -c "import sqlalchemy; print(f'sqlalchemy:{sqlalchemy.__version__}')" && echo "OK" || exit 1
SQLEOF

cat > "$SCRIPTS_DIR/fix-router-imports.sh" << 'ROUTEEOF'
#!/bin/bash
set -uo pipefail
BACKEND_DIR="${1:-$HOME/share-tool-dashboard/backend}"
VENV_DIR="$BACKEND_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then echo "No venv"; exit 1; fi
PY="$VENV_DIR/bin/python"
cd "$BACKEND_DIR" || exit 1
echo "Checking routers/..."
[ -d "routers" ] && ls -1 routers/ || echo "No routers/ dir"
echo "Testing import..."
if "$PY" -c "from main import app" 2>&1; then echo "Import OK"; else echo "Import FAILED"; exit 1; fi
ROUTEEOF

cat > "$SCRIPTS_DIR/fix-backend-api.sh" << 'APIEOF'
#!/bin/bash
set -euo pipefail
BACKEND_DIR="${1:-$HOME/share-tool-dashboard/backend}"
VENV_DIR="$BACKEND_DIR/.venv"
if [ ! -d "$BACKEND_DIR" ]; then echo "Backend not found"; exit 1; fi
if [ ! -d "$VENV_DIR" ]; then python3 -m venv "$VENV_DIR" || exit 1; fi
PIP="$VENV_DIR/bin/pip"
PY="$VENV_DIR/bin/python"
"$PIP" install --upgrade --quiet pip
[ -f "$BACKEND_DIR/requirements.txt" ] && cp "$BACKEND_DIR/requirements.txt" "$BACKEND_DIR/requirements.txt.backup.$(date +%Y%m%d_%H%M%S)"
"$PIP" install -r "$BACKEND_DIR/requirements.txt" 2>&1 | tail -3
cd "$BACKEND_DIR"
"$PY" -c "from main import app; print('main:app OK')" || exit 1
echo "Repair complete!"
APIEOF

cat > "$SCRIPTS_DIR/master-repair-all.sh" << 'MASTERCAT'
#!/bin/bash
set -uo pipefail
BACKEND_DIR="${1:-$HOME/share-tool-dashboard/backend}"
SCRIPTS_DIR="$HOME/scripts"
VENV_DIR="$BACKEND_DIR/.venv"
if [ ! -d "$BACKEND_DIR" ]; then echo "Backend not found"; exit 1; fi
[ ! -d "$VENV_DIR" ] && python3 -m venv "$VENV_DIR"
echo "Running repair sequence..."
for step in fix-pydantic-compatibility.sh fix-sqlalchemy-python313.sh fix-router-imports.sh fix-backend-api.sh; do
    echo "=== $step ==="
    bash "$SCRIPTS_DIR/$step" "$BACKEND_DIR" || { echo "FAILED at $step"; exit 1; }
done
echo "=== ALL COMPLETE ==="
MASTERCAT

chmod +x "$SCRIPTS_DIR"/*.sh
echo "Bootstrap complete! Scripts in ~/scripts/"
ls -la ~/scripts/*.sh
