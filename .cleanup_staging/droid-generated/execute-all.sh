#!/bin/bash
set -e
echo "=========================================="
echo "  EXECUTING ALL 4 TASKS"
echo "=========================================="

cd ~/share-tool-dashboard

echo ""
echo "=== [1/4] COMMITTING ==="
~/commit-dashboard.sh

echo ""
echo "=== [2/4] SANITY SCHEMAS ==="
~/setup-sanity-schemas.sh

echo ""
echo "=== [3/4] DEPLOYMENT DOCS ==="
~/create-deploy-docs.sh

echo ""
echo "=== [4/4] GIT REMOTE ==="
~/setup-git-remote.sh

echo ""
echo "=========================================="
echo "  ALL COMPLETE! ✅"
echo "=========================================="
echo ""
echo "Next: git push -u origin main"
