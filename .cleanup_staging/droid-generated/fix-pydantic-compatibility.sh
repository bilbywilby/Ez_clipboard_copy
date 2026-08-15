#!/bin/bash
# fix-pydantic-compatibility.sh - Fixes pydantic-core compatibility with Python 3.13

set -e

echo "=========================================="
echo "Pydantic-Core Python 3.13 Compatibility Fix"
echo "=========================================="
echo ""

PROJECT_DIR="${1:-./share-tool-dashboard/backend}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Project directory '$PROJECT_DIR' not found!"
    exit 1
fi

cd "$PROJECT_DIR"

echo "Target: $(pwd)"
echo ""

# Activate backend venv if exists
if [ -d ".venv" ]; then
    echo "✓ Found .venv in $PROJECT_DIR"
    source .venv/bin/activate
else
    echo "✗ No .venv found. Creating one..."
    python3 -m venv .venv
    source .venv/bin/activate
    echo "✓ Created new virtual environment"
fi

echo ""
echo "Python: $(python --version)"
echo "Pip: $(pip --version)"
echo ""

# Backup current requirements
if [ -f "requirements.txt" ]; then
    cp requirements.txt "requirements.txt.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Backed up original requirements.txt"
fi

echo ""
echo ">>> Installing compatible pydantic versions for Python 3.13"
echo "-----------------------------------------------------------"

# Install with --prefer-binary to avoid source builds
pip install --upgrade pip setuptools wheel
pip install --prefer-binary \
    "pydantic>=2.10,<3.0" \
    "pydantic-core>=2.27,<3.0" \
    "pydantic-settings>=2.5" \
    fastapi==0.109.0 \
    uvicorn[standard]==0.27.0 \
    sqlalchemy==2.0.25 \
    python-jose[cryptography]==3.3.0 \
    passlib[bcrypt]==1.7.4 \
    python-multipart==0.0.6 \
    pytest==7.4.4 \
    httpx==0.26.0 \
    requests==2.31.0 \
    python-dotenv==1.0.0 \
    aiosqlite==0.19.0

echo ""
echo "✓ Installation complete!"
echo ""

# Verify
echo ">>> Verification"
echo "-----------------------------------------------------------"
pip show pydantic pydantic-core pydantic-settings fastapi | grep -E "Name:|Version:"
echo ""

# Update requirements.txt with newer versions
cat > requirements.txt << 'EOF'
# FastAPI ecosystem (Python 3.13 compatible)
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic>=2.10,<3.0
pydantic-core>=2.27,<3.0
pydantic-settings>=2.5.0

# Database
sqlalchemy==2.0.25
aiosqlite==0.19.0

# Auth & Security
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# Testing
pytest==7.4.4
pytest-asyncio==0.23.3
httpx==0.26.0

# Utilities
requests==2.31.0
python-dotenv==1.0.0
EOF

echo "✓ Updated requirements.txt with Python 3.13 compatible versions"
echo ""
echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Test your app: cd $PROJECT_DIR && python -c \"from pydantic import BaseModel; print('OK')\""
echo "  2. Start server: uvicorn main:app --reload"
echo "  3. Original requirements.txt backed up as: requirements.txt.backup.*"
echo ""
