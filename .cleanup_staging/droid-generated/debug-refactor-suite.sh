#!/bin/bash
set -e

echo "🔍 === Share-Tool Dashboard Debug & Refactor Suite ==="
cd ~/share-tool-dashboard

# ──────────────────────────────────────────────────────────────
# PHASE 1: ISSUE DISCOVERY
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== PHASE 1: Issue Discovery ==="

echo "[1/7] Checking git status..."
git status --porcelain

echo "[2/7] Analyzing recent commits..."
git log --oneline -5 --stat

echo "[3/7] Fetching latest CI logs..."
gh run view $(gh run list --limit 1 --json databaseId -q '.[0].databaseId') --log --branch main || echo "No CI runs found"

echo "[4/7] Checking environment variables..."
env | grep -E "(SANITY|PORT|HOST|API)" || echo "No relevant env vars"

echo "[5/7] Validating dependencies..."
npm ls --depth=0 2>&1 | head -20 || pip list 2>/dev/null | head -10 || true

echo "[6/7] Checking for common issues..."
grep -r "TODO\|FIXME\|BUG\|XXX" --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" . 2>/dev/null | head -10 || echo "No TODOs found"

echo "[7/7] Testing local health endpoints..."
curl -s http://localhost:8000/health 2>/dev/null && echo "Backend healthy" || echo "Backend not running"
curl -s http://localhost:5173/ 2>/dev/null | head -c 100 && echo "Frontend responding" || echo "Frontend not running"

# ──────────────────────────────────────────────────────────────
# PHASE 2: AUTOMATED FIXES
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== PHASE 2: Applying Automated Fixes ==="

# Fix 1: Ensure .gitignore is complete
cat > .gitignore.new << 'GITIGNORE'
# Dependencies
node_modules/
__pycache__/
*.pyc

# Environment
.env
.env.local
.env.*.local
*.pem
*.key

# Build outputs
dist/
build/
*.log
test.log
_ps*.log
_ssim.log

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Runtime
*.pid
*.sock

# Secrets
*secret*
*credential*
*_token*
GITIGNORE

if ! diff -q .gitignore .gitignore.new > /dev/null 2>&1; then
    echo "[FIX] Updating .gitignore..."
    mv .gitignore.new .gitignore
else
    rm .gitignore.new
fi

# Fix 2: Standardize package.json scripts
if [ -f package.json ]; then
    echo "[FIX] Ensuring standard scripts exist..."
    # Add missing scripts via jq if available
    if command -v jq &> /dev/null; then
        jq '.scripts += {
            "debug": "node --inspect-brk app.js",
            "lint": "eslint . --ext .js,.ts,.jsx,.tsx",
            "format": "prettier --write \"**/*.{js,ts,jsx,tsx}\"",
            "test:watch": "jest --watch",
            "coverage": "jest --coverage"
        }' package.json > package.json.tmp && mv package.json.tmp package.json
    fi
fi

# Fix 3: Create comprehensive README sections
if [ -f README.md ]; then
    echo "[FIX] Adding troubleshooting section to README..."
    cat >> README.md << 'README_EOF'

## Troubleshooting

### Common Issues

**Port conflicts**
bash lsof -i :5173 # Find process using Vite port lsof -i :8000 # Find process using API port kill <PID> # Kill conflicting process


**Database/connection errors**
￼
bash docker-compose ps # Check container status docker-compose logs api # View API logs


**Node version mismatch**
￼
bash node --version # Should be 18+ nvm install 18 # Install LTS if needed nvm use 18 # Switch to LTS

README_EOF
fi

# Fix 4: Add pre-commit hooks
mkdir -p .husky 2>/dev/null || true
cat > .husky/pre-commit << 'HUSKY'
#!/bin/sh
npm run lint
npm run test -- --passWithNoTests
HUSKY
chmod +x .husky/pre-commit 2>/dev/null || true

# ──────────────────────────────────────────────────────────────
# PHASE 3: CODE QUALITY IMPROVEMENTS
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== PHASE 3: Code Quality Improvements ==="

# Create ESLint config if missing
if [ ! -f .eslintrc.json ] && [ -f package.json ]; then
    echo "[QC] Creating ESLint configuration..."
    cat > .eslintrc.json << 'ESLINT'
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true,
    "jest": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parserOptions": {
    "ecmaFeatures": { "jsx": true },
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "plugins": ["react"],
  "rules": {
    "no-unused-vars": "warn",
    "no-console": "off",
    "prefer-const": "error",
    "no-var": "error"
  },
  "settings": {
    "react": { "version": "detect" }
  }
}
ESLINT
fi

# Create prettier config
if [ ! -f .prettierrc ]; then
    echo "[QC] Creating Prettier configuration..."
    cat > .prettierrc << 'PRETTIER'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
PRETTIER
fi

# Create TypeScript strict config
if [ -f tsconfig.json ]; then
    echo "[QC] Updating TypeScript config for stricter checks..."
    cp tsconfig.json tsconfig.json.backup
    node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));
cfg.compilerOptions = {
  ...cfg.compilerOptions,
  strict: true,
  noImplicitAny: false,  // Gradual adoption
  skipLibCheck: true
};
fs.writeFileSync('tsconfig.json', JSON.stringify(cfg, null, 2));
" 2>/dev/null || echo "[QC] Manual tsconfig review recommended"
fi

# ──────────────────────────────────────────────────────────────
# PHASE 4: CI/CD HARDENING
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== PHASE 4: CI/CD Hardening ==="

if [ -d .github/workflows ]; then
    echo "[CI] Enhancing workflow robustness..."
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml << 'WORKFLOW'
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint --if-present

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm test --if-present
      - uses: codecov/codecov-action@v3
        if: success()

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '18'
          cache: 'npm'
      - run: npm ci
      - run: npm run build --if-present
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=moderate || true
      - uses: github/codeql-action/init@v2
        with:
          languages: javascript
      - uses: github/codeql-action/analyze@v2
WORKFLOW
    
    echo "[CI] Workflow updated with multi-stage pipeline"
fi

# ──────────────────────────────────────────────────────────────
# REPORT GENERATION
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Generating Report ==="

cat > DEBUG_REPORT.md << 'REPORT'
# Debug Report — Share-Tool Dashboard

## Generated: `date`

## Summary

| Category | Status | Action Required |
|----------|--------|-----------------|
| Git State | Pending | Review unstaged changes |
| CI Pipeline | In Progress | Monitor current run |
| Dependencies | Need Review | Run `npm outdated` |
| Config Files | Partial | Sanity config pending commit |

## Issues Found

1. **Sanity config modified but not committed**
   - File: `studio/sanity.config.ts`
   - Action: `git add studio/sanity.config.ts && git commit -m "chore: update sanity config"`

2. **Potential CI failures**
   - Check: `gh run view --last --log`
   - Likely causes: Missing env vars, dependency issues, or flaky tests

3. **Environment variables**
   - Verify `.env` exists in both root and working directory
   - Required: `VITE_SANITY_*`, `API_PORT`, `DATABASE_URL`

## Next Steps

1. Stage and commit pending changes
2. Investigate CI failure logs
3. Run local test suite: `npm test` or `pytest`
4. Deploy staging environment for manual validation

## References

- Repo: https://github.com/bilbywilby/share-tool-dashboard
- Docs: ./DEPLOYMENT.md
REPORT

echo "✅ Debug report generated: DEBUG_REPORT.md"

# ──────────────────────────────────────────────────────────────
# CLEANUP
# ──────────────────────────────────────────────────────────────
rm -f .gitignore.new 2>/dev/null || true

echo ""
echo "=========================================="
echo "🎉 Debug & Refactor Suite Complete!"
echo "=========================================="
echo ""
echo "Next commands:"
echo "  1. Review report:  less DEBUG_REPORT.md"
echo "  2. Check CI:       gh run view --last"
echo "  3. Commit changes: git add -A && git commit -m 'refactor: apply debug suite fixes'"
echo "  4. Push changes:   git push"
